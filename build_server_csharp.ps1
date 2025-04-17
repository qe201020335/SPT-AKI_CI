Param(
    [Parameter(Mandatory = $false)]
    [Switch] $Overwrite,

    [Parameter(Mandatory = $false)]
    [string] $Branch,

    [Parameter(Mandatory = $false)]
    [string] $Commit,

    [Parameter(Mandatory = $false)]
    [Switch] $NoZip,

    [Parameter(Mandatory = $false)]
    [Switch] $Release,

    [Parameter(Mandatory = $false)]
    [Switch] $SelfContained,

    [Parameter(Mandatory = $false)]
    [Switch] $SingleFile,

    [Parameter(Mandatory = $false)]
    [string] $Runtime
)

$ErrorActionPreference = "Stop"
$SOURCE_REPO = "https://github.com/sp-tarkov/server-csharp.git"
$SERVER_DIR = "./server-csharp"

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
$Branch = git branch --show-current

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
    $Configuration = "Release"
}
else {
    $Configuration = "Debug"
}

if ($Runtime.Length -eq 0) {
    $Runtime = ((dotnet --info | findstr "RID:") -split ":")[1].Trim()
    Write-Output "USing current runtime (RID): $Runtime"
}

$Suffix = "$Configuration-$Runtime"

if ($SelfContained) {
    $SCFlag = "--sc"
    $Suffix = "$Suffix-selfcontained"
}
else {
    $SCFlag = ""
}

if ($SingleFile) {
    $SFFlag = "PublishSingleFile=true"
    $Suffix = "$Suffix-single"
}
else {
    $SFFlag = "PublishSingleFile=false"
}

Write-Output "dotnet publish -c $Configuration -r $Runtime $SCFlag -p $SFFlag -o ./Build ./SPTarkov.Server"
dotnet publish -c $Configuration -r $Runtime $SCFlag -p $SFFlag -o ./Build ./SPTarkov.Server

if ($LASTEXITCODE -ne 0) {
    throw ("dotnet publish failed, exit code $LASTEXITCODE")
}

Get-ChildItem ./Build
$SPTMeta = (Get-Content ./Build/Assets/configs/core.json | ConvertFrom-Json -AsHashtable)
Write-Output $SPTMeta

if ($BuildOnCommit) {
    $CInfo = "$Head-$CTimeS"
} 
else {
    $CInfo = "$Branch-$Head-$CTimeS"
}

Write-Output $Suffix
$Suffix = "$Suffix-v$($SPTmeta.sptVersion)-$CInfo-Tarkov$($SPTmeta.compatibleTarkovVersion)"
$ZipName = "SPTarkov.Server-$Suffix"
Write-Output $ZipName

if (!$NoZip) {
    if ($Runtime.StartsWith("win")) {
        $ZipName = "$ZipName.zip"
        Compress-Archive -Path ./Build/* -DestinationPath "./$ZipName" -Force
    }
    else {
        $ZipName = "$ZipName.tar.gz"
        Set-Location ./Build
        tar -czv -f "../$ZipName" ./*
    }
    Write-Output "Built file: $ZipName"
}

Write-Output "ZIP_NAME=$ZipName" >> "$env:GITHUB_OUTPUT"
