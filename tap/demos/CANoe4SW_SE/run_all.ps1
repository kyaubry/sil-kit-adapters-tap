param (
    [string]$SILKitDir
)

# Check if exactly one argument is passed
if (-not $SILKitDir) {
    Write-Host "Error: Exactly one argument is required."
    Write-Host "Usage: .\run_all.ps1 <path_to_sil_kit_dir>"
    exit 1
}

# Scripts to run the executables and commands in background
$execRegistry = {
   param ($SILKitDir, $ScriptDir)
   & $SILKitDir\sil-kit-registry.exe --listen-uri 'silkit://0.0.0.0:8501' -s | Out-File -FilePath $ScriptDir\sil-kit-registry.out
}

$execAdapter = {
    param ($ScriptDir)
    & $ScriptDir\..\..\..\bin\SilKitAdapterTap.exe --log Debug | Out-File -FilePath $ScriptDir\SilKitAdapterTap.out
}

$execDemo = {
    param ($ScriptDir)
    & $ScriptDir\..\..\..\bin\SilKitDemoEthernetIcmpEchoDevice.exe --log Debug | Out-File -FilePath $ScriptDir\SilKitDemoEthernetIcmpEchoDevice.out
}

$execPing = {
    param ($ScriptDir)
    & ping 192.168.7.35 -S 192.168.7.2 -n 100 | Out-File -FilePath $ScriptDir\ping-command.out
}

Start-Job -ScriptBlock $execRegistry -ArgumentList $SILKitDir, $PSScriptRoot -Name SILKitRegistry

Start-Sleep -Seconds 1

Start-Job -ScriptBlock $execAdapter -ArgumentList $PSScriptRoot -Name TapAdapter

Start-Job -ScriptBlock $execDemo -ArgumentList $PSScriptRoot -Name Demo

Start-Job -ScriptBlock $execPing -ArgumentList $PSScriptRoot -Name PingCmd

# Get the last line telling the overall test verdict (passed/failed)
$scriptResult = & $PSScriptRoot\run.ps1 | Select-Object -Last 1

$isPassed = select-string -pattern "passed" -InputObject $scriptResult

Write-Output "sil-kit-registry.out:---------------------------------------------------------------------------"
Get-Content $PSScriptRoot/sil-kit-registry.out
Write-Output "------------------------------------------------------------------------------------------------"

# Stop all the jobs
Stop-Job -Name PingCmd, TapAdapter, Demo, SILKitRegistry

if($isPassed)
{
    Write-Output "Tests passed"
    exit 0
}
else
{
    Write-Output "Tests failed"
    exit 1
}
