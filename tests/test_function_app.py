# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
"""Tests for the deterministic Azure SRE Agent demo scenarios."""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import function_app


def test_all_documented_scenarios_are_registered() -> None:
    assert set(function_app.SCENARIO_NAMES) == set(function_app.SCENARIOS)
    assert len(function_app.SCENARIOS) == 10


def test_http_500_scenario_is_deterministic() -> None:
    result = function_app.SCENARIOS["http-500"]()

    assert result.status_code == 500
    assert result.severity == 1
    assert result.scenario == "http-500"


@patch("function_app._queue_client")
def test_queue_backlog_adds_bounded_messages(queue_client_factory: MagicMock) -> None:
    queue_client = MagicMock()
    queue_client_factory.return_value = queue_client

    result = function_app.SCENARIOS["queue-backlog"]()

    assert result.item_count == 25
    assert queue_client.send_message.call_count == 25


@patch.dict("os.environ", {"SRE_DEMO_MODE": "drifted"}, clear=False)
def test_config_drift_reports_unhealthy_setting() -> None:
    result = function_app.SCENARIOS["config-drift"]()

    assert result.status_code == 503
    assert result.severity == 1
    assert "drifted" in result.summary


def test_dashboard_payload_reports_full_scenario_coverage() -> None:
    events = [
        {
            "timestamp": "2026-10-14T13:55:38Z",
            "scenario": "http-500",
            "severity": 1,
            "statusCode": 500,
            "durationMs": 0,
            "itemCount": 0,
            "summary": "Failure",
            "rootCause": "Simulated exception",
            "correlationId": "test-id",
        }
    ]
    request_series = [
        {
            "timestamp": "2026-10-14T13:55:00Z",
            "requests": 14,
            "failures": 1,
            "p50": 867.0,
            "p95": 4020.0,
            "p99": 4020.0,
        }
    ]

    payload = function_app._build_dashboard_payload(events, request_series, 24)

    assert payload["summary"]["scenariosObserved"] == 1
    assert payload["summary"]["p95DurationMs"] == 4020.0
    assert len(payload["coverage"]) == 10
    assert payload["coverage"][0]["status"] == "critical"


def test_cost_page_is_available_without_authentication() -> None:
    response = function_app.cost(MagicMock())

    assert response.status_code == 200
    assert response.mimetype == "text/html"
    assert b"Evaluation cost planner" in response.get_body()


def test_resource_inventory_groups_components_for_business_view() -> None:
    inventory = function_app._build_resource_inventory(
        [
            {
                "id": "/subscriptions/test/resourceGroups/demo/providers/Microsoft.Web/sites/app",
                "name": "app",
                "type": "microsoft.web/sites",
                "resourceGroup": "demo",
                "location": "westus2",
                "kind": "functionapp,linux",
                "sku": "",
                "provisioningState": "Succeeded",
            },
            {
                "id": "/subscriptions/test/resourceGroups/demo/providers/"
                "Microsoft.OperationalInsights/workspaces/log",
                "name": "log",
                "type": "microsoft.operationalinsights/workspaces",
                "resourceGroup": "demo",
                "location": "westus2",
                "kind": "",
                "sku": "PerGB2018",
                "provisioningState": "Succeeded",
            },
        ]
    )

    assert inventory["summary"]["resources"] == 2
    assert inventory["summary"]["resourceGroups"] == 1
    assert inventory["resourceGroups"] == [{"name": "demo", "resourceCount": 2}]
    assert inventory["components"][0]["category"] == "Compute"
    assert len(inventory["supportingComponents"]) == 4


def test_resource_dashboard_is_available_without_authentication() -> None:
    response = function_app.resources(MagicMock())

    assert response.status_code == 200
    assert response.mimetype == "text/html"
    assert b"Azure component command center" in response.get_body()
