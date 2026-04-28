# =============================================================================
# build-and-export.ps1 - Build the NodeCast TV container on Windows and export
# it as a .tar file ready to load on your QNAP NAS.
#
# Requirements:
#   - Docker Desktop for Windows (running)
#   - SCP available for transfer (or use -SkipTransfer and copy manually)
#
# Usage:
#   .\build-and-export.ps1
#   .\build-and-export.ps1 -DockerHost 192.168.37.55 -HostUser admin
#   .\build-and-export.ps1 -SkipTransfer
# =============================================================================

param(
    [string]$ImageName = "nodecast-tv",
    [string]$ImageTag = "local",
    [string]$OutputFile = "nodecast-tv.tar",
    [string]$DockerHost = "192.168.37.55", # Updated to your QNAP IP
    [string]$HostUser = "admin",
    [string]$HostPath = "/share/CACHEDEV1_DATA/Public", # Common public share on QNAP
    [switch]$SkipTransfer
)

$ErrorActionPreference = "Stop"
$FullImage = "${ImageName}:${ImageTag}"

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  NodeCast TV Container - Build and Export" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# -- Step 1: Build ------------------------------------------------------------
Write-Host "[1/3] Building Docker image: $FullImage" -ForegroundColor Yellow
Write-Host "      This may take several minutes on first run."
Write-Host ""

docker build -t $FullImage .

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker build failed. Check the output above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "      Build complete." -ForegroundColor Green

# -- Step 2: Export -----------------------------------------------------------
Write-Host ""
Write-Host "[2/3] Exporting image to $OutputFile ..." -ForegroundColor Yellow
Write-Host "      Using docker save - produces a plain .tar"
Write-Host ""

if (Test-Path $OutputFile) { Remove-Item $OutputFile }
docker save -o $OutputFile $FullImage

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: docker save failed." -ForegroundColor Red
    exit 1
}

$SizeMB = [math]::Round((Get-Item $OutputFile).Length / 1MB, 1)
Write-Host "      Exported: $OutputFile ($SizeMB MB)" -ForegroundColor Green

# -- Step 3: Transfer ---------------------------------------------------------
Write-Host ""
if ($SkipTransfer) {
    Write-Host "[3/3] Skipping transfer (-SkipTransfer flag set)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "      Transfer the file manually to your QNAP NAS."
    Write-Host ""
}
else {
    Write-Host "[3/3] Transferring to QNAP at $DockerHost via SCP ..." -ForegroundColor Yellow
    Write-Host "      Destination: ${HostUser}@${DockerHost}:${HostPath}/${OutputFile}"
    Write-Host "      You will be prompted for the NAS password."
    Write-Host ""

    scp $OutputFile "${HostUser}@${DockerHost}:${HostPath}/"

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "      SCP failed - transfer manually instead (e.g. via File Station / SMB)" -ForegroundColor Yellow
    }
    else {
        Write-Host "      Transfer complete." -ForegroundColor Green
    }
}

# -- Summary ------------------------------------------------------------------
Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  Next steps on the QNAP NAS:" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. SSH into your QNAP (if not using Container Station UI):"
Write-Host "       ssh $HostUser@$DockerHost"
Write-Host ""
Write-Host "  2. Load the image into Docker:"
Write-Host "       docker load -i ${HostPath}/${OutputFile}"
Write-Host "       Expected: Loaded image: nodecast-tv:local"
Write-Host ""
Write-Host "  3. Deploy via Container Station or SSH:"
Write-Host "       docker-compose up -d"
Write-Host ""
