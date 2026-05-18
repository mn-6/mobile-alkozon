$ErrorActionPreference = 'Stop'

function Resolve-AdbPath {
  $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
  if ($adbCmd) {
    return $adbCmd.Source
  }

  $sdkCandidates = @()

  if ($env:ANDROID_SDK_ROOT) {
    $sdkCandidates += $env:ANDROID_SDK_ROOT
  }
  if ($env:ANDROID_HOME) {
    $sdkCandidates += $env:ANDROID_HOME
  }

  $localPropsPath = Join-Path $PSScriptRoot 'android\local.properties'
  if (Test-Path $localPropsPath) {
    $sdkLine = Select-String -Path $localPropsPath -Pattern '^sdk\.dir=' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($sdkLine) {
      $sdkDir = ($sdkLine.Line -replace '^sdk\.dir=', '').Trim()
      $sdkDir = $sdkDir -replace '\\\\', '\'
      if ($sdkDir) {
        $sdkCandidates += $sdkDir
      }
    }
  }

  foreach ($sdk in $sdkCandidates | Select-Object -Unique) {
    $candidate = Join-Path $sdk 'platform-tools\adb.exe'
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  return $null
}

function Resolve-FlutterPath {
  $flutterBat = Get-Command flutter.bat -ErrorAction SilentlyContinue
  if ($flutterBat) {
    return $flutterBat.Source
  }

  $fallback = 'C:\flutter\src\flutter\bin\flutter.bat'
  if (Test-Path $fallback) {
    return $fallback
  }

  return $null
}

$adb = Resolve-AdbPath
if (-not $adb) {
  Write-Error 'adb.exe not found. Install Android platform-tools or add SDK\\platform-tools to PATH.'
  exit 1
}

Write-Host "Using ADB: $adb"
Write-Host 'Starting ADB server...'
& $adb start-server | Out-Null

$devicesOutput = & $adb devices
$deviceLines = $devicesOutput | Select-String "\tdevice$"

if (-not $deviceLines) {
  Write-Error 'No Android device in state "device". Connect phone and enable USB debugging.'
  exit 1
}

$serial = ($deviceLines[0].ToString() -split "\t")[0]
Write-Host "Using device: $serial"

Write-Host 'Resetting reverse rules...'
& $adb -s $serial reverse --remove-all | Out-Null

Write-Host 'Configuring reverse tcp:8080 -> tcp:8080...'
& $adb -s $serial reverse tcp:8080 tcp:8080 | Out-Null

$reverseList = & $adb -s $serial reverse --list
if ($reverseList -notmatch 'tcp:8080\s+tcp:8080') {
  Write-Error 'adb reverse was not set correctly.'
  exit 1
}

$flutter = Resolve-FlutterPath
if (-not $flutter) {
  Write-Error 'flutter.bat not found. Add Flutter\\bin to PATH.'
  exit 1
}

Write-Host "Using Flutter: $flutter"
Write-Host 'Reverse active. Starting flutter run...'
& $flutter run
