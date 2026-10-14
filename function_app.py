#!/usr/bin/env python3
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
"""Azure Functions workload for deterministic Azure SRE Agent demonstrations."""

from __future__ import annotations

import hashlib
import json
import logging
import os
import time
import uuid
from collections.abc import Callable
from dataclasses import asdict, dataclass
from datetime import UTC, datetime

import azure.functions as func
from azure.storage.queue import QueueClient

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)
logger = logging.getLogger("sre_demo")

SCENARIO_NAMES = (
    "http-500",
    "latency",
    "dependency-failure",
    "throttling",
    "queue-backlog",
    "poison-message",
    "memory-pressure",
    "cpu-saturation",
    "config-drift",
    "deployment-regression",
)


@dataclass(frozen=True)
class ScenarioResult:
    """Result returned by a controlled reliability scenario."""

    scenario: str
    status_code: int
    severity: int
    summary: str
    expected_root_cause: str
    duration_ms: int = 0
    item_count: int = 0


def _json_response(payload: dict[str, object], status_code: int = 200) -> func.HttpResponse:
    return func.HttpResponse(
        json.dumps(payload, indent=2),
        status_code=status_code,
        mimetype="application/json",
    )


def _telemetry_payload(result: ScenarioResult, correlation_id: str) -> dict[str, object]:
    return {
        "eventType": "sre-demo-scenario",
        "timestamp": datetime.now(UTC).isoformat(),
        "correlationId": correlation_id,
        **asdict(result),
    }


def _emit_result(result: ScenarioResult, correlation_id: str) -> None:
    payload = _telemetry_payload(result, correlation_id)
    message = json.dumps(payload, separators=(",", ":"))
    if result.severity <= 1:
        logger.error(message)
    elif result.severity == 2:
        logger.warning(message)
    else:
        logger.info(message)


def _queue_client() -> QueueClient:
    connection_string = os.environ["AzureWebJobsStorage"]
    queue_name = os.getenv("SRE_DEMO_QUEUE_NAME", "sre-demo-events")
    return QueueClient.from_connection_string(connection_string, queue_name)


def _http_500() -> ScenarioResult:
    return ScenarioResult(
        scenario="http-500",
        status_code=500,
        severity=1,
        summary="The checkout endpoint returned an internal server error.",
        expected_root_cause="A simulated unhandled checkout exception.",
    )


def _latency() -> ScenarioResult:
    delay_seconds = 3
    started = time.perf_counter()
    time.sleep(delay_seconds)
    elapsed_ms = int((time.perf_counter() - started) * 1000)
    return ScenarioResult(
        scenario="latency",
        status_code=200,
        severity=2,
        summary="The catalog endpoint exceeded its latency objective.",
        expected_root_cause="A simulated three-second synchronous operation.",
        duration_ms=elapsed_ms,
    )


def _dependency_failure() -> ScenarioResult:
    return ScenarioResult(
        scenario="dependency-failure",
        status_code=503,
        severity=1,
        summary="The payment dependency was unavailable.",
        expected_root_cause="A simulated downstream connection refusal.",
    )


def _throttling() -> ScenarioResult:
    return ScenarioResult(
        scenario="throttling",
        status_code=429,
        severity=2,
        summary="The public API rejected traffic above its request quota.",
        expected_root_cause="A simulated rate-limit policy.",
    )


def _queue_backlog() -> ScenarioResult:
    count = 25
    client = _queue_client()
    for index in range(count):
        client.send_message(
            json.dumps(
                {
                    "kind": "valid-order",
                    "orderId": f"demo-{index:03d}",
                    "createdAt": datetime.now(UTC).isoformat(),
                }
            )
        )
    return ScenarioResult(
        scenario="queue-backlog",
        status_code=202,
        severity=2,
        summary=f"Added {count} messages without a consumer.",
        expected_root_cause="A simulated stopped queue processor.",
        item_count=count,
    )


def _poison_message() -> ScenarioResult:
    client = _queue_client()
    client.send_message('{"kind":"order","orderId":null,"payload":"INVALID"')
    return ScenarioResult(
        scenario="poison-message",
        status_code=202,
        severity=2,
        summary="Added a malformed message to the order queue.",
        expected_root_cause="A simulated producer schema violation.",
        item_count=1,
    )


def _memory_pressure() -> ScenarioResult:
    allocation = bytearray(24 * 1024 * 1024)
    digest = hashlib.sha256(allocation).hexdigest()[:12]
    return ScenarioResult(
        scenario="memory-pressure",
        status_code=200,
        severity=2,
        summary=f"Allocated 24 MiB temporarily; digest {digest}.",
        expected_root_cause="A simulated oversized in-memory payload.",
        item_count=len(allocation),
    )


def _cpu_saturation() -> ScenarioResult:
    started = time.perf_counter()
    iterations = 0
    digest = b"seed"
    while time.perf_counter() - started < 2:
        digest = hashlib.sha256(digest).digest()
        iterations += 1
    elapsed_ms = int((time.perf_counter() - started) * 1000)
    return ScenarioResult(
        scenario="cpu-saturation",
        status_code=200,
        severity=2,
        summary=f"Ran a CPU-bound loop for {elapsed_ms} ms.",
        expected_root_cause="A simulated inefficient hashing workload.",
        duration_ms=elapsed_ms,
        item_count=iterations,
    )


def _config_drift() -> ScenarioResult:
    actual = os.getenv("SRE_DEMO_MODE", "unexpected")
    expected = "healthy"
    is_drifted = actual != expected
    return ScenarioResult(
        scenario="config-drift",
        status_code=503 if is_drifted else 200,
        severity=1 if is_drifted else 4,
        summary=f"Expected SRE_DEMO_MODE={expected}; observed {actual}.",
        expected_root_cause="An application setting differs from the approved baseline.",
    )


def _deployment_regression() -> ScenarioResult:
    actual = os.getenv("SRE_DEMO_RELEASE", "2026.10-bad")
    expected = "2026.10-good"
    return ScenarioResult(
        scenario="deployment-regression",
        status_code=500,
        severity=1,
        summary=f"Release {actual} failed the post-deployment validation.",
        expected_root_cause=f"The deployed release does not match approved release {expected}.",
    )


SCENARIOS: dict[str, Callable[[], ScenarioResult]] = {
    "http-500": _http_500,
    "latency": _latency,
    "dependency-failure": _dependency_failure,
    "throttling": _throttling,
    "queue-backlog": _queue_backlog,
    "poison-message": _poison_message,
    "memory-pressure": _memory_pressure,
    "cpu-saturation": _cpu_saturation,
    "config-drift": _config_drift,
    "deployment-regression": _deployment_regression,
}


@app.route(route="health", methods=["GET"])
def health(req: func.HttpRequest) -> func.HttpResponse:
    """Return the workload health and available scenarios."""
    del req
    return _json_response(
        {
            "status": "healthy",
            "service": "azure-sre-agent-demo",
            "release": os.getenv("SRE_DEMO_RELEASE", "2026.10-bad"),
            "scenarios": list(SCENARIO_NAMES),
        }
    )


@app.route(route="scenario/{name}", methods=["POST"])
def invoke_scenario(req: func.HttpRequest) -> func.HttpResponse:
    """Run one bounded and deterministic reliability scenario."""
    name = req.route_params.get("name", "")
    scenario = SCENARIOS.get(name)
    if scenario is None:
        return _json_response(
            {"error": "Unknown scenario.", "availableScenarios": list(SCENARIO_NAMES)},
            status_code=404,
        )

    correlation_id = req.headers.get("x-correlation-id", str(uuid.uuid4()))
    try:
        result = scenario()
    except Exception:
        logger.exception(
            json.dumps(
                {
                    "eventType": "sre-demo-scenario-failure",
                    "scenario": name,
                    "correlationId": correlation_id,
                }
            )
        )
        return _json_response(
            {"scenario": name, "correlationId": correlation_id, "error": "Scenario failed."},
            status_code=500,
        )

    _emit_result(result, correlation_id)
    return _json_response(
        {"correlationId": correlation_id, **asdict(result)},
        status_code=result.status_code,
    )
