# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
"""Tests for the deterministic Azure SRE Agent demo scenarios."""

from __future__ import annotations

import json
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
    assert b'class="mermaid"' in response.get_body()
    assert b'SRE Agent deployment and execution architecture' in response.get_body()
    assert b'Azure Monitor alerts' in response.get_body()


def test_partner_page_is_not_registered() -> None:
    routes = {
        binding.get("route")
        for function in function_app.app.get_functions()
        for binding in json.loads(function.get_function_json())["bindings"]
        if binding["type"] == "httpTrigger"
    }

    assert "partner" not in routes
    assert {"portal", "cost", "resources", "sre-deep-dive"} <= routes


def test_public_pages_do_not_link_to_removed_partner_page() -> None:
    for handler in (
        function_app.portal,
        function_app.cost,
        function_app.resources,
        function_app.sre_deep_dive,
    ):
        response = handler(MagicMock())

        assert response.status_code == 200
        assert b'href="./partner"' not in response.get_body()


def test_sre_deep_dive_is_served_with_official_references() -> None:
    response = function_app.sre_deep_dive(MagicMock())
    body = response.get_body()

    assert response.status_code == 200
    assert response.mimetype == "text/html"
    assert response.headers["Cache-Control"] == "public, max-age=300"
    assert b"Azure SRE Agent: from operational signals to governed recovery" in body
    for topic in (
        "overview",
        "permissions",
        "user-roles",
        "azure-monitor-alerts",
        "run-modes",
        "audit-agent-actions",
        "live-reports",
        "tool-access-policies",
        "agent-hooks",
        "mcp-connectors",
        "pricing-billing",
    ):
        assert f'https://learn.microsoft.com/en-us/azure/sre-agent/{topic}"'.encode() in body


def test_all_dashboards_link_to_the_deep_dive() -> None:
    for handler in (function_app.portal, function_app.cost, function_app.resources):
        assert b'href="./sre-deep-dive"' in handler(MagicMock()).get_body()


def test_sre_deep_dive_includes_five_explained_diagrams() -> None:
    body = function_app.sre_deep_dive(MagicMock()).get_body()

    assert body.count(b'class="mermaid"') == 5
    assert body.count(b'<figure id="agent-') == 5
    assert body.count(b'class="diagram-use"') == 5
    for diagram in ("architecture", "investigation", "reports", "governance", "specialists"):
        assert f'id="agent-{diagram}-diagram"'.encode() in body
    assert b'securityLevel: "strict"' in body
    assert b"Diagrams could not be rendered." in body
    assert b"not three agents deployed by this project" in body


def test_sre_deep_dive_explains_native_context_setup_and_validation() -> None:
    body = function_app.sre_deep_dive(MagicMock()).get_body()

    for required in (
        'href="#setup"',
        'id="setup"',
        "Configure-AgentContext.ps1",
        "-Apply -WhatIf",
        "NativeConnectionsVerified: false",
        "sre-demo-application-insights",
        "sre-demo-log-analytics",
        "GitHub authorization is pending",
        "Knowledge files",
        "Incidents (optional)",
        "Read-only setup validation",
        "Pass subscription explicitly to Azure Monitor tool calls.",
        "Recorded read-only validation",
        "system-mcp-monitor",
        "historical observations",
        "AppTraces, AppRequests",
        "not a live health check",
    ):
        assert required.encode() in body
    for topic in (
        "complete-setup",
        "connect-source-code",
        "connect-telemetry-source",
        "upload-knowledge-document",
    ):
        assert f'https://learn.microsoft.com/en-us/azure/sre-agent/{topic}"'.encode() in body


def test_sre_deep_dive_links_to_illustrated_skills_guide() -> None:
    body = function_app.sre_deep_dive(MagicMock()).get_body()

    assert b'href="#skills-guide"' in body
    assert b'id="skills-guide"' in body
    assert b"blob/main/docs/sre-agent-configuration-and-skills.md" in body
    assert body.count(b'<figure class="setup-shot">') == 3
    for image in (
        "01-managed-resources.png",
        "02-telemetry-connectors.png",
        "03-create-skill-draft.png",
    ):
        assert f"/docs/images/sre-setup/{image}".encode() in body
    assert b"allowed_skills" in body
    assert b"No example custom skill is left installed" in body
    assert b"https://learn.microsoft.com/en-us/azure/sre-agent/skills" in body
