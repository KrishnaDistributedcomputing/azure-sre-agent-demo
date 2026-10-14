#!/usr/bin/env pwsh
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#Requires -Version 7.0

<#
.SYNOPSIS
    Invokes one or all controlled SRE demonstration scenarios.
.DESCRIPTION
    Reads the deployed Function App host name and sends bounded requests that
    produce deterministic reliability telemetry for dashboards and investigations.
.PARAMETER Scenario
    Scenario name or All to invoke every scenario once.
.PARAMETER DeploymentOutputPath
    Path to the JSON output written by Deploy-Demo.ps1.
.EXAMPLE
    ./scripts/Invoke-Scenario.ps1 -Scenario All
.NOTES
    Expected 4xx and 5xx responses are returned as scenario results, not script failures.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet(
        'All',
        'http-500',
        'latency',
        'dependency-failure',
        'throttling',
        'queue-backlog',
        'poison-message',
        'memory-pressure',
        'cpu-saturation',
        'config-drift',
        'deployment-regression'
    )]
    [string]$Scenario = 'All',

    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$DeploymentOutputPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'deployment-output.json')
)

$ErrorActionPreference = 'Stop'

#region Functions

function Invoke-DemoScenario {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$HostName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $Uri = "https://$HostName/api/scenario/$Name"
    try {
        return Invoke-RestMethod -Method Post -Uri $Uri -Headers @{
            'x-correlation-id' = [guid]::NewGuid().ToString()
        }
    }
    catch {
        if ($null -ne $_.ErrorDetails.Message) {
            return $_.ErrorDetails.Message | ConvertFrom-Json
        }
        throw
    }
}

#endregion Functions

#region Main Execution

if ($MyInvocation.InvocationName -ne '.') {
    try {
        $Deployment = Get-Content -LiteralPath $DeploymentOutputPath -Raw | ConvertFrom-Json
        $HostName = $Deployment.functionAppHostName.value
        $Scenarios = if ($Scenario -eq 'All') {
            @(
                'http-500',
                'latency',
                'dependency-failure',
                'throttling',
                'queue-backlog',
                'poison-message',
                'memory-pressure',
                'cpu-saturation',
                'config-drift',
                'deployment-regression'
            )
        }
        else {
            @($Scenario)
        }

        $Results = foreach ($Name in $Scenarios) {
            Write-Host "Invoking $Name" -ForegroundColor Cyan
            Invoke-DemoScenario -HostName $HostName -Name $Name
        }

        $Results | ConvertTo-Json -Depth 10
        exit 0
    }
    catch {
        Write-Error -ErrorAction Continue "Invoke-Scenario failed: $($_.Exception.Message)"
        exit 1
    }
}

#endregion Main Execution
