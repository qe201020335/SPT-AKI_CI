Param(
    [Parameter(Mandatory = $false)]
    [Switch] $Overwrite,

    [Parameter(Mandatory = $false)]
    [Switch] $Release,

    [Parameter(Mandatory = $false)]
    [string] $Branch,

    [Parameter(Mandatory = $false)]
    [string] $Commit,

    [Parameter(Mandatory = $false)]
    [Switch] $NoZip
)

$ErrorActionPreference = "Stop"
$SOURCE_REPO = "https://github.com/sp-tarkov/server.git"
$SERVER_DIR = "./Server"

$BuildOnCommit = $Commit.Length -gt 0

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
    Write-Output "Cloning branch/tag $Branch"
    git clone --depth 1 -b $Branch $SOURCE_REPO $SERVER_DIR
} 
else {
    Write-Output "Cloning default branch"
    git clone --depth 1 $SOURCE_REPO $SERVER_DIR
}

Set-Location $SERVER_DIR

if ($BuildOnCommit) {
    Write-Output "Checking out the commit $Commit"
    git fetch --depth=1 $SOURCE_REPO $Commit
    git checkout $Commit

    if ($LASTEXITCODE -ne 0) {
        throw ("Commit $Commit checkout failed. It doesn't exist? git exit code $LASTEXITCODE")
    }
}

$Head = git rev-parse --short HEAD
$CTime = git log -1 --format="%at"
$CTimeS = (([System.DateTimeOffset]::FromUnixTimeSeconds($CTime)).DateTime).ToString("yyyyMMddHHmmss")

Write-Output "Current HEAD is at $Head in $Branch committed at $CTimeS"

Write-Output "lfs"
git lfs fetch
git lfs pull

Write-Output "build"
if ($Release) {
    $Target = "release"
}
else {
    $Target = "debug"
}
Set-Location ./project

npm install --force
npm run build:$Target *>&1

if ($LASTEXITCODE -ne 0) {
    throw ("npm run build:$Target failed, exit code $LASTEXITCODE")
}

Get-ChildItem ./build
$AkiMeta = (Get-Content ./build/SPT_Data/Server/configs/core.json | ConvertFrom-Json -AsHashtable)
Write-Output $akiMeta

if ($BuildOnCommit) {
    $CInfo = "$Head-$CTimeS"
} 
else {
    $CInfo = "$Branch-$Head-$CTimeS"
}

$Suffix = "$Target-v$($akimeta.sptVersion)-$CInfo-Tarkov$($akimeta.compatibleTarkovVersion)"

if ($IsWindows) {
    $Os = "win"
}
else{
    $Os = "linux"
}

$ZipName = "Aki-Server-$Os-$Suffix"

if (!$NoZip) {
    if ($IsWindows) {
        $ZipName = "$ZipName.zip"
        Compress-Archive -Path ./build/* -DestinationPath "../$ZipName" -Force
    }
    else {
        $ZipName = "$ZipName.tar.gz"
        Set-Location ./build
        tar --overwrite -czv -f "../../$ZipName" ./*
    }
    Write-Output "Built file: $ZipName"
}

Write-Output "ZIP_NAME=$ZipName" >> "$env:GITHUB_OUTPUT"
