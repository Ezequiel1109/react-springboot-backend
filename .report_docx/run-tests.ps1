<#
run-tests.ps1
Utility script to run Maven tests on Windows PowerShell with proper quoting for -D properties.

Usage:
  # Run unit + integration tests (default)
  .\run-tests.ps1

  # Run only unit tests
  .\run-tests.ps1 test

  # Run verify (unit + IT)
  .\run-tests.ps1 verify
#>
param(
    [string]$phase = "verify"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir
Write-Host "Running: mvn \"-Dsurefire.useFile=false\" \"-Dfailsafe.useFile=false\" $phase"

# Execute Maven with quoted -D properties so PowerShell doesn't treat them as lifecycle phases
mvn "-Dsurefire.useFile=false" "-Dfailsafe.useFile=false" $phase
