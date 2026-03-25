# PowerPlatformChecker

![example workflow](https://github.com/autosysops/PowerShell_PowerPlatformChecker/actions/workflows/build.yml/badge.svg)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PowerPlatformChecker.svg)](https://www.powershellgallery.com/packages/PowerPlatformChecker/)

PowerShell module to check Power Platform solutions. This module will use the exported json files so it can be used inside a deployment pipeline. No connection to the Power Platform is required.
This module will assume solutions are unpacked using the Power Platform CLI tools (pac solution unpack).

## Installation

You can install the module from the [PSGallery](https://www.powershellgallery.com/packages/PowerPlatformChecker) by using the following command.

```PowerShell
Install-Module -Name PowerPlatformChecker
```

Or if you are using PowerShell 7.4 or higher you can use

```PowerShell
Install-PSResource -Name PowerPlatformChecker
```

## Usage

To use the module first import it.

```PowerShell
Import-Module -Name PowerPlatformChecker
```

You will receive a message about telemetry being enabled. After that you can use the command `Get-PowerPlatformChecker` to use the module.

Check out the Get-Help for more information on how to use the function.

## Features

For now the feature set is limited. You can:

* Test a Power Automate flow for unchanged actions, this can help you test if your flows are documented correctly
* Get all connectors linked to a flow and check their tier to check if a premium license is needed for this flow
* Get all action in a flow and the refernces they have
* Get the flows, environmental variables and connection references in a solution

## Credits

The module is using the [Telemetryhelper module](https://github.com/nyanhp/TelemetryHelper) to gather telemetry.
The module is made using the [PSModuleDevelopment module](https://github.com/PowershellFrameworkCollective/PSModuleDevelopment) to get a template for a module.
