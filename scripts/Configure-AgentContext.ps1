#!/usr/bin/env pwsh
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#Requires -Version 7.0

<#
.SYNOPSIS
    Checks or grants scoped read access for the demo SRE Agent.
.DESCRIPTION
    Resolves the operational user-assigned identity from the existing agent.
    Checks the five Reader-level roles used by native SRE Agent setup on the
    demo resource group. Apply adds missing assignments only. The script never
    grants Contributor, changes run mode, configures OAuth, or resets teardown.
    Native resource scope, code, logs, and knowledge connections must also be
    configured and tested in the SRE Agent setup interface.
.PARAMETER SubscriptionId
    Subscription containing the existing agent and evaluation workload.
.PARAMETER AgentResourceGroup
    Resource group containing the existing agent.
.PARAMETER AgentName
    Existing SRE Agent name.
.PARAMETER DemoResourceGroup
    Resource group whose resources the agent may read.
.PARAMETER Apply
    Grant missing read roles. Without this switch, only inspect and report.
.EXAMPLE
    .\scripts\Configure-AgentContext.ps1 -SubscriptionId <id>
.EXAMPLE
    .\scripts\Configure-AgentContext.ps1 -SubscriptionId <id> -Apply -WhatIf
.EXAMPLE
    .\scripts\Configure-AgentContext.ps1 -SubscriptionId <id> -Apply
.NOTES
    Requires Azure CLI and permission to read agent metadata and role assignments.
    Apply also requires permission to assign roles on the demo resource group.
    No credentials are accepted or written by this script.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [guid]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$AgentResourceGroup = 'rg-sre-agent',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$AgentName = 'msdn-sre-agent',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$DemoResourceGroup = 'rg-sre-demo',

    [Parameter(Mandatory = $false)]
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

#region Main Execution

if ($MyInvocation.InvocationName -ne '.') {
    try {
        $AgentId = "/subscriptions/$SubscriptionId/resourceGroups/$AgentResourceGroup/providers/Microsoft.App/agents/$AgentName"
        $Scope = "/subscriptions/$SubscriptionId/resourceGroups/$DemoResourceGroup"
        $AgentJson = & az resource show --ids $AgentId --output json
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to read the existing SRE Agent.'
        }
        $Agent = $AgentJson | ConvertFrom-Json
        $IdentityId = $Agent.properties.actionConfiguration.identity
        if ([string]::IsNullOrWhiteSpace($IdentityId)) {
            throw 'The agent does not identify its operational user-assigned identity. No roles were granted.'
        }
        $IdentityEntries = @(
            $Agent.identity.userAssignedIdentities.PSObject.Properties |
                Where-Object { $_.Name -eq $IdentityId }
        )
        if ($IdentityEntries.Count -ne 1 -or
            [string]::IsNullOrWhiteSpace($IdentityEntries[0].Value.principalId)) {
            throw 'The operational identity is not attached to this agent or has no principal ID.'
        }
        $PrincipalId = $IdentityEntries[0].Value.principalId
        & az group show --name $DemoResourceGroup --subscription $SubscriptionId --output none
        if ($LASTEXITCODE -ne 0) {
            throw 'The requested demo resource group cannot be read.'
        }
        $RequiredRoles = @(
            'Reader'
            'Monitoring Reader'
            'Log Analytics Reader'
            'Workbook Reader'
            'Storage Blob Data Reader'
        )
        $AssignmentsJson = & az role assignment list --assignee $PrincipalId `
            --scope $Scope --subscription $SubscriptionId --include-inherited --output json
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to inspect role assignments for the operational identity.'
        }
        $AssignedRoles = @(
            $AssignmentsJson | ConvertFrom-Json |
                Select-Object -ExpandProperty roleDefinitionName
        )
        foreach ($Role in $RequiredRoles) {
            if ($Role -notin $AssignedRoles -and $Apply -and
                $PSCmdlet.ShouldProcess($Scope, "Grant $Role to the SRE Agent operational identity")) {
                & az role assignment create --assignee-object-id $PrincipalId `
                    --assignee-principal-type ServicePrincipal --role $Role `
                    --scope $Scope --subscription $SubscriptionId --output none
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to grant $Role on the demo resource group."
                }
            }
        }
        $VerifiedJson = & az role assignment list --assignee $PrincipalId `
            --scope $Scope --subscription $SubscriptionId --include-inherited --output json
        if ($LASTEXITCODE -ne 0) {
            throw 'Unable to verify the resulting read access.'
        }
        $VerifiedRoles = @(
            $VerifiedJson | ConvertFrom-Json |
                Select-Object -ExpandProperty roleDefinitionName
        )
        $MissingRoles = @($RequiredRoles | Where-Object { $_ -notin $VerifiedRoles })
        if ($MissingRoles.Count -gt 0) {
            Write-Warning "Missing roles: $($MissingRoles -join ', '). RBAC propagation may require another check."
            if ($Apply -and -not $WhatIfPreference) {
                throw 'Read access is not fully verified. Inspect the missing assignments and rerun the check.'
            }
        }
        [pscustomobject]@{
            AgentName = $AgentName
            DemoResourceGroup = $DemoResourceGroup
            OperationalIdentity = $IdentityId
            ReadAccessReady = $MissingRoles.Count -eq 0
            MissingRoles = $MissingRoles
            AgentRunMode = $Agent.properties.actionConfiguration.mode
            NativeConnectionsVerified = $false
            NextStep = 'Verify Code, Logs, Azure resources, and Knowledge files in native Agent setup; run an evidence-backed read-only query.'
        } | ConvertTo-Json -Depth 4
        exit 0
    }
    catch {
        Write-Error -ErrorAction Continue "Configure-AgentContext failed: $($_.Exception.Message)"
        exit 1
    }
}

#endregion Main Execution
