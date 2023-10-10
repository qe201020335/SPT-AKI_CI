Param(
    [Parameter(Mandatory = $false)]
    [Switch] $Overwrite,

    [Parameter(Mandatory = $false)]
    [string] $Branch,

    [Parameter(Mandatory = $false)]
    [string] $Commit

)

$ErrorActionPreference = "Stop"
$SOURCE_REPO = "https://dev.sp-tarkov.com/SPT-AKI/Server.git"
$SERVER_DIR = "./Server"

if (Test-Path -Path $SERVER_DIR) {
    if ($Overwrite -or (Read-Host "$SERVER_DIR exists, delete? [y/n]") -eq 'y') {
        Write-Output "$SERVER_DIR exists, removing"
        Remove-Item -Recurse -Force $SERVER_DIR
    }
    else {
        Exit 1
    }
}

Write-Output "clone repo"
if ( $Branch.Length -gt 0 ) {
    Write-Output "Cloning branch $Branch"
    git clone -b $Branch $SOURCE_REPO $SERVER_DIR
} 
else {
    Write-Output "Branch not given, using default branch"
    git clone $SOURCE_REPO $SERVER_DIR
}

Set-Location $SERVER_DIR

if ($Commit.Length -gt 0) {
    Write-Output "Checking out the commit $Commit"
    git fetch --all
    git checkout $Commit

    if ($LASTEXITCODE -ne 0) {
        throw ("Commit $Commit checkout failed. It doesn't exist? git exit code $LASTEXITCODE")
    }
}

$Head = git rev-parse --short HEAD
$Branch = git rev-parse --abbrev-ref HEAD

Write-Output "Current HEAD is at $Head in $Branch"

Write-Output "lfs"
git lfs fetch
git lfs pull

Set-Location ./project


$GULPFILE = "./gulpfile.mjs"
if ($null -ne (Select-String -Path $GULPFILE -Pattern "\\\\checks.dat"))
{
    Write-Warning "Applying workaround for hardcoded windows path delimiter"
    Set-Content -path $GULPFILE ((Get-Content -path $GULPFILE -Raw) -replace "\\\\checks.dat",'/checks.dat')
} 
else {
    Write-Output "Workaround not applied."
}


Write-Output "build"
npm install
npm run build:debug *>&1


if ($IsLinux -eq $true) {
    $Os = "linux"
}
else {
    $Os = "win"
}
Write-Output "Current OS: " $Os

Get-ChildItem ./build
$AkiMeta = (Get-Content ./build/Aki_Data/Server/configs/core.json |  ConvertFrom-Json -AsHashtable)
Write-Output $akiMeta
$ZipName = "Aki-Server-{0}-debug-{1}-{2}-{3}-Tarkov{4}.zip" -f $Os, $akimeta.akiVersion, $Branch, $Head, $akimeta.compatibleTarkovVersion

Compress-Archive -Path ./build/* -DestinationPath "../$ZipName" -Force
Write-Output "Built file: $ZipName"
Write-Output "ZIP_NAME=$ZipName" >> "$env:GITHUB_OUTPUT"
