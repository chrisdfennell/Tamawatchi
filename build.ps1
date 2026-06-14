param(
    [string]$Device = "fenix7",
    [switch]$Run,
    [switch]$WaitForRun,
    [switch]$Export
)

$ErrorActionPreference = "Stop"

$javaHome = "C:\Program Files\Android\openjdk\jdk-21.0.8"
if (Test-Path $javaHome) {
    $env:JAVA_HOME = $javaHome
    $env:PATH = "$javaHome\bin;" + $env:PATH
}

$sdkDir = "C:\Users\christopher.fennell\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.1.0-2026-03-09-6a872a80b"
$sdkBin = Join-Path $sdkDir "bin"
$monkeyc = Join-Path $sdkBin "monkeyc.bat"
$monkeydo = Join-Path $sdkBin "monkeydo.bat"
$simulator = Join-Path $sdkBin "simulator.exe"

if (!(Test-Path $monkeyc)) {
    throw "Garmin compiler not found at $monkeyc"
}

$binDir = Join-Path $PSScriptRoot "bin"
if (!(Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir | Out-Null
}

$localKey = Join-Path $PSScriptRoot "developer_key.der"
$fallbackKey = "C:\programming\binary watch face - garmin\developer_key.der"
$keyPath = if (Test-Path $localKey) { $localKey } elseif (Test-Path $fallbackKey) { $fallbackKey } else { $null }
if ($keyPath -eq $null) {
    throw "No developer_key.der found. Place one in this project root or update build.ps1."
}

$junglePath = Join-Path $PSScriptRoot "monkey.jungle"

if ($Export) {
    $outputPath = Join-Path $binDir "GarmiGotchi.iq"
    Write-Host "Packaging Garmi-gotchi for Connect IQ Store..." -ForegroundColor Cyan
    & $monkeyc -e -f $junglePath -o $outputPath -y $keyPath
} else {
    $outputPath = Join-Path $binDir "GarmiGotchi.prg"
    Write-Host "Building Garmi-gotchi for $Device..." -ForegroundColor Cyan
    & $monkeyc -f $junglePath -o $outputPath -y $keyPath -d $Device
}

if ($LASTEXITCODE -ne 0) {
    throw "Compilation failed with exit code $LASTEXITCODE"
}

Write-Host "Build succeeded: $outputPath" -ForegroundColor Green

if ($Run) {
    if (!(Test-Path $simulator)) {
        throw "Simulator not found at $simulator"
    }
    if (!(Get-Process -Name "simulator" -ErrorAction SilentlyContinue)) {
        Write-Host "Starting Connect IQ Simulator..." -ForegroundColor Cyan
        Start-Process -FilePath $simulator -WorkingDirectory $sdkBin
        Start-Sleep -Seconds 4
    }

    $tempDir = "C:\Garmin_Temp"
    if (!(Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }

    $tempPrg = Join-Path $tempDir "GarmiGotchi.prg"
    Copy-Item $outputPath $tempPrg -Force

    Write-Host "Running Garmi-gotchi watch-app on $Device in simulator..." -ForegroundColor Cyan
    if ($WaitForRun) {
        & $monkeydo $tempPrg $Device
    } else {
        Start-Process -FilePath $monkeydo -ArgumentList @($tempPrg, $Device)
    }
}
