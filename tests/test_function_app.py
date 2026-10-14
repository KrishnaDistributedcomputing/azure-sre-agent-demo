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
