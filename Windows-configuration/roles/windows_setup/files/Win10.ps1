#!/usr/bin/env pwsh
# Title: Windows Initial Setup Script
# Description: This PowerShell script automates the initial setup and configuration for Windows 10, Server 2016, and Server 2019. It includes functionalities such as running with elevated privileges, handling command-line arguments, and executing user-defined tweaks.
# Author: Jay-Alexander Elliot
# Date: 2024-01-31
# Usage: Run the script with desired arguments. Use -include to specify additional scripts, -preset for predefined tweak sets, and -log for output logging. Start the script in PowerShell with administrator rights for full functionality.

# Relaunch the script with administrator privileges
Function RequireAdmin {
    # Check if the script is running as an administrator
    If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        # Relaunch the script with elevated privileges
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $PSCommandArgs" -Verb RunAs
        Exit
    }
}

$script:tweaks = @()
$PSCommandArgs = @()

# Add or remove tweaks based on provided arguments
Function AddOrRemoveTweak($tweak) {
    If ($tweak[0] -eq "!") {
        # Exclude the tweak if the name starts with an exclamation mark (!)
        $script:tweaks = $script:tweaks | Where-Object { $_ -ne $tweak.Substring(1) }
    } ElseIf ($tweak -ne "") {
        # Add the tweak otherwise
        $script:tweaks += $tweak
    }
}

# Parse and resolve paths in passed arguments
$i = 0
While ($i -lt $args.Length) {
    # Handle different types of arguments
    If ($args[$i].ToLower() -eq "-include") {
        # Include additional scripts
        $include = Resolve-Path $args[++$i] -ErrorAction Stop
        $PSCommandArgs += "-include `"$include`""
        Import-Module -Name $include -ErrorAction Stop
    } ElseIf ($args[$i].ToLower() -eq "-preset") {
        # Apply presets
        $preset = Resolve-Path $args[++$i] -ErrorAction Stop
        $PSCommandArgs += "-preset `"$preset`""
        Get-Content $preset -ErrorAction Stop | ForEach-Object { AddOrRemoveTweak($_.Split("#")[0].Trim()) }
    } ElseIf ($args[$i].ToLower() -eq "-log") {
        # Log output to a file
        $log = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($args[++$i])
        $PSCommandArgs += "-log `"$log`""
        Start-Transcript $log
    } Else {
        # Load tweaks from command line
        $PSCommandArgs += $args[$i]
        AddOrRemoveTweak($args[$i])
    }
    $i++
}

# Execute the desired tweaks
$tweaks | ForEach-Object { Invoke-Expression $_ }
