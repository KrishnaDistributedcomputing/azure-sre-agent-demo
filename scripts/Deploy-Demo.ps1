#!/usr/bin/env pwsh
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#Requires -Version 7.0

<#
.SYNOPSIS
    Deploys the low-cost Azure SRE Agent demonstration stack.
.DESCRIPTION
    Validates Azure access, deploys subscription-scoped Bicep resources, publishes
    the Python Function App, and writes deployment outputs for scenario scripts.
.PARAMETER SubscriptionId
    Azure subscription that owns the SRE Agent and demo resources.
.PARAMETER AlertEmail
    Email address that receives budget and reliability alerts.
.PARAMETER Location
    Azure region for demo and guardrail resources.
.PARAMETER EvaluationDays
    Number of days before automatic teardown. The maximum safe value is 29.
.EXAMPLE
    ./scripts/Deploy-Demo.ps1 -SubscriptionId <id> -AlertEmail owner@example.com
.NOTES
    Requires Azure CLI, Bicep CLI, and Azure Functions Core Tools.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AlertEmail,

    [Parameter(Mandatory = $false)]
    [ValidateSet('westus2', 'westus3', 'centralus', 'eastus2')]
    [string]$Location = 'westus2',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 29)]
    [int]$EvaluationDays = 29
)

$ErrorActionPreference = 'Stop'

#region Functions

function Invoke-AzureCli {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Arguments
    )

    $Output = & az @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Azure CLI failed: $($Output -join [Environment]::NewLine)"
    }

    return $Output -join [Environment]::NewLine
}

#endregion Functions

#region Main Execution

if ($MyInvocation.InvocationName -ne '.') {
    try {
        $RepositoryRoot = Split-Path -Parent $PSScriptRoot
        $DeploymentOutputPath = Join-Path $RepositoryRoot 'deployment-output.json'
        $env:AZURE_EXTENSION_DIR = Join-Path $RepositoryRoot '.azure-cli-extensions'
        $TeardownUtc = (Get-Date).ToUniversalTime().AddDays($EvaluationDays).ToString('yyyy-MM-ddTHH:mm:ssZ')

        Invoke-AzureCli -Arguments @(
            'account', 'show',
            '--subscription', $SubscriptionId,
            '--output', 'none'
        ) | Out-Null

        Write-Host 'Deploying shared demo infrastructure and cost guardrails.' -ForegroundColor Cyan
        $DeploymentJson = Invoke-AzureCli -Arguments @(
            'deployment', 'sub', 'create',
            '--name', "sre-demo-$(Get-Date -Format 'yyyyMMddHHmmss')",
            '--subscription', $SubscriptionId,
            '--location', $Location,
            '--template-file', (Join-Path $RepositoryRoot 'infra/main.bicep'),
            '--parameters',
            "alertEmail=$AlertEmail",
            "location=$Location",
            "teardownUtc=$TeardownUtc",
            '--query', 'properties.outputs',
            '--output', 'json'
        )
        $DeploymentJson | Set-Content -Path $DeploymentOutputPath -Encoding utf8

        $Deployment = $DeploymentJson | ConvertFrom-Json
        $FunctionAppName = $Deployment.functionAppName.value
        $WorkspaceId = $Deployment.logAnalyticsWorkspaceId.value

        Write-Host 'Applying the 0.1 GB daily Log Analytics ingestion cap.' -ForegroundColor Cyan
        Invoke-AzureCli -Arguments @(
            'rest',
            '--method', 'patch',
            '--url', "$WorkspaceId`?api-version=2023-09-01",
            '--headers', 'Content-Type=application/json',
            '--body', '{"properties":{"workspaceCapping":{"dailyQuotaGb":0.1}}}',
            '--output', 'none'
        ) | Out-Null

        Write-Host "Publishing Function App $FunctionAppName." -ForegroundColor Cyan
        Push-Location $RepositoryRoot
        try {
            & func azure functionapp publish $FunctionAppName --python
            if ($LASTEXITCODE -ne 0) {
                throw "Function App publish failed with exit code $LASTEXITCODE."
            }
        }
        finally {
            Pop-Location
        }

        Write-Host "Deployment succeeded. Automatic teardown: $TeardownUtc" -ForegroundColor Green
        Write-Host "Outputs: $DeploymentOutputPath" -ForegroundColor Green
        exit 0
    }
    catch {
        Write-Error -ErrorAction Continue "Deploy-Demo failed: $($_.Exception.Message)"
        exit 1
    }
}

#endregion Main Execution
