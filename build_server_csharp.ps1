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

$SPTMeta = (Get-Content ./Libraries/SPTarkov.Server.Assets/SPT_Data/configs/core.json | ConvertFrom-Json -AsHashtable)
Write-Output $SPTMeta

$SPTVersion = (Select-Xml -Path .\Build.props '//SptVersion').Node.InnerText  # $SPTmeta.sptVersion
$EFTVersion = $SPTmeta.compatibleTarkovVersion

Write-Output "Building SPT Server $SPTVersion compatible with $EFTVersion"

Write-Output "build"
if ($Release) {
    $Configuration = "Release"
    $SptBuildType = "RELEASE"
}
else {
    $Configuration = "Debug"
    $SptBuildType = "DEBUG"
}

if ($Runtime.Length -eq 0) {
    $Runtime = ((dotnet --info | Select-String -Pattern "RID:") -split ":")[1].Trim()
    Write-Output "USing current runtime (RID): $Runtime"
}

$Suffix = "$Configuration-$Runtime"

if ($SingleFile) {
    $SFFlag = "PublishSingleFile=true"
    $Suffix = "$Suffix-single"
}
else {
    $SFFlag = "PublishSingleFile=false"
}

$BuildTime = Get-Date -Format yyyyMMdd

Write-Output "dotnet publish --property WarningLevel=0 ./SPTarkov.Server/SPTarkov.Server.csproj -f net9.0 -o ./Build -c $Configuration -r $Runtime --self-contained false -p $SFFlag -p:IncludeNativeLibrariesForSelfExtract=true -p:SptBuildType=$SptBuildType -p:SptVersion=$SPTVersion -p:SptBuildTime=$BuildTime -p:SptCommit=$Head -p:IsPublish=true"
dotnet publish --property WarningLevel=0 ./SPTarkov.Server/SPTarkov.Server.csproj -f net9.0 -o ./Build -c $Configuration -r $Runtime --self-contained false -p $SFFlag -p:IncludeNativeLibrariesForSelfExtract=true -p:SptBuildType=$SptBuildType -p:SptVersion=$SPTVersion -p:SptBuildTime=$BuildTime -p:SptCommit=$Head -p:IsPublish=true

if ($LASTEXITCODE -ne 0) {
    throw ("dotnet publish failed, exit code $LASTEXITCODE")
}

Get-ChildItem ./Build

if ($BuildOnCommit) {
    $CInfo = "$Head-$CTimeS"
} 
else {
    $CInfo = "$Branch-$Head-$CTimeS"
}

Write-Output $Suffix
$Suffix = "$Suffix-v$SPTVersion-$CInfo-Tarkov$EFTVersion"
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
