param (
	$TestGeneral = $true,

	$TestFunctions = $true,

	$EnableCoverage = $true,

	[double]
	$CoverageThreshold = 90,

	[ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
	[Alias('Show')]
	$Output = "None",

	$Include = "*",

	$Exclude = ""
)

Write-Host "Starting Tests"

Write-Host "Importing Module"

$global:testroot = $PSScriptRoot
$global:__pester_data = @{ }

# Shared helper for split function tests (fixtures + cached module test data).
. "$PSScriptRoot\functions\PowerPlatformChecker.TestCommon.ps1"

Remove-Module PowerPlatformChecker -ErrorAction Ignore
Import-Module "$PSScriptRoot\..\PowerPlatformChecker\PowerPlatformChecker.psd1"
Import-Module "$PSScriptRoot\..\PowerPlatformChecker\PowerPlatformChecker.psm1" -Force

# Need to import explicitly so we can use the configuration class
Import-Module Pester -DisableNameChecking

Write-Host  "Creating test result folder"
$null = New-Item -Path "$PSScriptRoot\.." -Name TestResults -ItemType Directory -Force

$totalFailed = 0
$totalRun = 0

$testresults = @()
$config = [PesterConfiguration]::Default
$config.TestResult.Enabled = $true

#region Run General Tests
if ($TestGeneral)
{
	Write-Host  "Modules imported, proceeding with general tests"
	foreach ($file in (Get-ChildItem "$PSScriptRoot\general" | Where-Object Name -like "*.Tests.ps1"))
	{
		if ($file.Name -notlike $Include) { continue }
		if ($file.Name -like $Exclude) { continue }

		Write-Host  "  Executing $($file.Name)"
		$config.TestResult.OutputPath = Join-Path "$PSScriptRoot\..\TestResults" "TEST-$($file.BaseName).xml"
		$config.Run.Path = $file.FullName
		$config.Run.PassThru = $true
		$config.Output.Verbosity = $Output
    	$results = Invoke-Pester -Configuration $config
		foreach ($result in $results)
		{
			$totalRun += $result.TotalCount
			$totalFailed += $result.FailedCount
			$result.Tests | Where-Object Result -ne 'Passed' | ForEach-Object {
				$testresults += [pscustomobject]@{
					Block    = $_.Block
					Name	 = "It $($_.Name)"
					Result   = $_.Result
					Message  = $_.ErrorRecord.DisplayErrorMessage
				}
			}
		}
	}
}
#endregion Run General Tests

$global:__pester_data.ScriptAnalyzer | Out-Host

#region Test Commands
$functionTestFiles = @()
$functionTestResult = $null
if ($TestFunctions)
{
	Write-Host "Proceeding with individual tests"
	$functionTestFiles = @(Get-ChildItem "$PSScriptRoot\functions" -Recurse -File | Where-Object Name -like "*Tests.ps1" | Where-Object {
		$_.Name -like $Include -and $_.Name -notlike $Exclude
	})

	if ($functionTestFiles.Count -gt 0)
	{
		Write-Host "  Executing function test suite ($($functionTestFiles.Count) files)"
		$config.TestResult.OutputPath = Join-Path "$PSScriptRoot\..\TestResults" "TEST-Functions.xml"
		$config.Run.Path = @($functionTestFiles.FullName)
		$config.Run.PassThru = $true
		$config.Output.Verbosity = $Output
		$config.CodeCoverage.Enabled = $EnableCoverage
		if ($EnableCoverage)
		{
			$config.CodeCoverage.Path = @("$PSScriptRoot\..\PowerPlatformChecker\functions\*.ps1")
			$config.CodeCoverage.OutputPath = Join-Path "$PSScriptRoot\..\TestResults" "coverage.xml"
			$config.CodeCoverage.OutputFormat = "JaCoCo"
		}
		$functionTestResult = Invoke-Pester -Configuration $config
		$totalRun += $functionTestResult.TotalCount
		$totalFailed += $functionTestResult.FailedCount
		$functionTestResult.Tests | Where-Object Result -ne 'Passed' | ForEach-Object {
			$testresults += [pscustomobject]@{
				Block    = $_.Block
				Name	 = "It $($_.Name)"
				Result   = $_.Result
				Message  = $_.ErrorRecord.DisplayErrorMessage
			}
		}
	}
	else
	{
		Write-Host "No function tests selected."
	}
}
#endregion Test Commands

#region Code Coverage
if ($TestFunctions -and $EnableCoverage)
{
	Write-Host "Calculating code coverage for public functions"
	if ($functionTestFiles.Count -eq 0 -or $null -eq $functionTestResult)
	{
		Write-Host "No function tests selected for coverage run."
		return
	}

	$coverageOutputPath = Join-Path "$PSScriptRoot\..\TestResults" "coverage.xml"
	if ($functionTestResult.FailedCount -gt 0)
	{
		$failedCoverageTests = $functionTestResult.Tests | Where-Object Result -ne 'Passed' | Select-Object -ExpandProperty Name
		throw "Coverage-enabled function test run contained failing tests: $($failedCoverageTests -join ', ')"
	}

	[xml]$coverageXml = (Get-Content -Path $coverageOutputPath) -join "`n"
	$lineCounters = $coverageXml.report.package.counter | Where-Object type -eq 'LINE'
	$lineMissed = ($lineCounters | Measure-Object -Property missed -Sum).Sum
	$lineCovered = ($lineCounters | Measure-Object -Property covered -Sum).Sum
	$lineTotal = $lineMissed + $lineCovered
	$coveragePercent = if ($lineTotal -gt 0)
	{
		[math]::Round((($lineCovered / $lineTotal) * 100), 2)
	}
	else
	{
		100
	}

	Write-Host "Code coverage: $coveragePercent% ($lineCovered/$lineTotal lines)"
	if ($coveragePercent -lt $CoverageThreshold)
	{
		throw "Code coverage $coveragePercent% is below threshold $CoverageThreshold%."
	}
}
#endregion Code Coverage

$testresults | Sort-Object Describe, Context, Name, Result, Message | Format-List

if ($totalFailed -eq 0) { Write-Host  "All $totalRun tests executed without a single failure!" }
else { Write-Host "$totalFailed tests out of $totalRun tests failed!" }

if ($totalFailed -gt 0)
{
	throw "$totalFailed / $totalRun tests failed!"
}