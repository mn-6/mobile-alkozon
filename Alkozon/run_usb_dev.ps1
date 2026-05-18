$ErrorActionPreference = 'Stop'

Write-Host 'Starting ADB server...'
adb start-server | Out-Null

$devicesOutput = adb devices
$deviceLines = $devicesOutput | Select-String "\tdevice$"

if (-not $deviceLines) {
  Write-Error 'No Android device in state "device". Connect phone and enable USB debugging.'
  exit 1
}

$serial = ($deviceLines[0].ToString() -split "\t")[0]
Write-Host "Using device: $serial"

Write-Host 'Resetting reverse rules...'
adb -s $serial reverse --remove-all | Out-Null

Write-Host 'Configuring reverse tcp:8080 -> tcp:8080...'
adb -s $serial reverse tcp:8080 tcp:8080 | Out-Null

$reverseList = adb -s $serial reverse --list
if ($reverseList -notmatch 'tcp:8080\s+tcp:8080') {
  Write-Error 'adb reverse was not set correctly.'
  exit 1
}

Write-Host 'Reverse active. Starting flutter run...'
flutter run
