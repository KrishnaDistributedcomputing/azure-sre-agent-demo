#!/usr/bin/env python3
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
"""Azure Functions workload for deterministic Azure SRE Agent demonstrations."""

from __future__ import annotations

import hashlib
import json
import logging
import os
import threading
import time
import uuid
from collections.abc import Callable
from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.storage.queue import QueueClient

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)
logger = logging.getLogger("sre_demo")
_dashboard_cache: tuple[float, int, dict[str, object]] | None = None
_dashboard_cache_lock = threading.Lock()
_credential: DefaultAzureCredential | None = None

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


def _logs_credential() -> DefaultAzureCredential:
    global _credential
    if _credential is None:
        _credential = DefaultAzureCredential()
    return _credential


def _query_workspace(query: str) -> list[dict[str, object]]:
    workspace_id = os.environ["SRE_DEMO_WORKSPACE_ID"]
    token = _logs_credential().get_token("https://api.loganalytics.io/.default").token
    request = Request(
        f"https://api.loganalytics.azure.com/v1/workspaces/{workspace_id}/query",
        data=json.dumps({"query": query}).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urlopen(request, timeout=30) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except HTTPError as error:
        details = error.read().decode("utf-8", errors="replace")
        message = f"Log Analytics query failed with HTTP {error.code}: {details}"
        raise RuntimeError(message) from error
    except URLError as error:
        raise RuntimeError(f"Log Analytics query failed: {error.reason}") from error

    tables = payload.get("tables", [])
    if not tables:
        return []

    table = tables[0]
    columns = [column["name"] for column in table["columns"]]
    return [dict(zip(columns, row, strict=True)) for row in table["rows"]]


def _scenario_query(hours: int) -> str:
    return f"""
AppTraces
| where TimeGenerated >= ago({hours}h)
| where Message has '"eventType":"sre-demo-scenario"'
| extend event = parse_json(Message)
| project
    timestamp=TimeGenerated,
    scenario=tostring(event.scenario),
    severity=toint(event.severity),
    statusCode=toint(event.status_code),
    durationMs=toint(event.duration_ms),
    itemCount=toint(event.item_count),
    summary=tostring(event.summary),
    rootCause=tostring(event.expected_root_cause),
    correlationId=tostring(event.correlationId)
| order by timestamp desc
"""


def _request_query(hours: int) -> str:
    return f"""
AppRequests
| where TimeGenerated >= ago({hours}h)
| summarize
    requests=count(),
    failures=countif(Success == false),
    p50=percentile(DurationMs, 50),
    p95=percentile(DurationMs, 95),
    p99=percentile(DurationMs, 99)
    by timestamp=bin(TimeGenerated, 5m)
| order by timestamp asc
"""


def _build_dashboard_payload(
    events: list[dict[str, object]],
    request_series: list[dict[str, object]],
    hours: int,
) -> dict[str, object]:
    latest_by_scenario: dict[str, dict[str, object]] = {}
    counts: dict[str, int] = {}
    for event in events:
        scenario = str(event["scenario"])
        counts[scenario] = counts.get(scenario, 0) + 1
        latest_by_scenario.setdefault(scenario, event)

    coverage: list[dict[str, object]] = []
    for scenario in SCENARIO_NAMES:
        latest = latest_by_scenario.get(scenario)
        severity = int(latest["severity"]) if latest else 0
        status = (
            "critical"
            if severity == 1
            else "warning"
            if severity == 2
            else "observed"
            if latest
            else "not-run"
        )
        coverage.append(
            {
                "scenario": scenario,
                "count": counts.get(scenario, 0),
                "status": status,
                "latest": latest,
            }
        )

    request_count = sum(int(point.get("requests") or 0) for point in request_series)
    failure_count = sum(int(point.get("failures") or 0) for point in request_series)
    p95 = max((float(point.get("p95") or 0) for point in request_series), default=0)
    critical_count = sum(1 for event in events if int(event["severity"]) == 1)
    warning_count = sum(1 for event in events if int(event["severity"]) == 2)

    return {
        "generatedAt": datetime.now(UTC).isoformat(),
        "timeRangeHours": hours,
        "summary": {
            "signals": len(events),
            "critical": critical_count,
            "warning": warning_count,
            "scenariosObserved": len(latest_by_scenario),
            "requests": request_count,
            "failures": failure_count,
            "p95DurationMs": round(p95, 1),
        },
        "coverage": coverage,
        "requestSeries": request_series,
        "evidence": events[:100],
        "guardrails": {
            "monthlyBudgetUsd": 100,
            "dailyLogCapGb": 0.1,
            "activeFlowAauLimit": 500,
            "teardownUtc": os.getenv("SRE_DEMO_TEARDOWN_UTC"),
            "hosting": "Azure Functions Flex Consumption",
        },
    }


def _dashboard_payload(hours: int) -> dict[str, object]:
    global _dashboard_cache
    now = time.monotonic()
    with _dashboard_cache_lock:
        if (
            _dashboard_cache is not None
            and _dashboard_cache[1] == hours
            and now - _dashboard_cache[0] < 60
        ):
            return _dashboard_cache[2]

    payload = _build_dashboard_payload(
        _query_workspace(_scenario_query(hours)),
        _query_workspace(_request_query(hours)),
        hours,
    )
    with _dashboard_cache_lock:
        _dashboard_cache = (now, hours, payload)
    return payload


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


@app.route(route="dashboard-data", methods=["GET"])
def dashboard_data(req: func.HttpRequest) -> func.HttpResponse:
    """Return cached live telemetry for the public showcase portal."""
    try:
        hours = int(req.params.get("hours", "24"))
    except ValueError:
        return _json_response({"error": "hours must be an integer."}, status_code=400)
    if hours not in {1, 4, 24, 168}:
        return _json_response(
            {"error": "hours must be one of 1, 4, 24, or 168."},
            status_code=400,
        )

    try:
        payload = _dashboard_payload(hours)
    except (KeyError, RuntimeError) as error:
        logger.exception("Dashboard telemetry query failed.")
        return _json_response({"error": str(error)}, status_code=502)

    response = _json_response(payload)
    response.headers["Cache-Control"] = "public, max-age=60"
    return response


@app.route(route="portal", methods=["GET"])
def portal(req: func.HttpRequest) -> func.HttpResponse:
    """Serve the public no-login reliability showcase."""
    del req
    portal_path = Path(__file__).parent / "portal" / "index.html"
    return func.HttpResponse(
        portal_path.read_text(encoding="utf-8"),
        status_code=200,
        mimetype="text/html",
        headers={"Cache-Control": "public, max-age=300"},
    )


@app.route(route="cost", methods=["GET"])
def cost(req: func.HttpRequest) -> func.HttpResponse:
    """Serve the public evaluation cost-planning page."""
    del req
    cost_path = Path(__file__).parent / "portal" / "cost.html"
    return func.HttpResponse(
        cost_path.read_text(encoding="utf-8"),
        status_code=200,
        mimetype="text/html",
        headers={"Cache-Control": "public, max-age=300"},
    )
