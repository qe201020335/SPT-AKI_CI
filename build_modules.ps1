Param(
    [Parameter(Mandatory=$false)]
    [Switch] $Overwrite,

    [Parameter(Mandatory=$false)]
    [string] $Branch,

    [Parameter(Mandatory = $false)]
    [string] $Commit,

    [Parameter(Mandatory=$true)]
    [string] $Url,

    [Parameter(Mandatory=$true)]
    [string] $TarkovVersion,

    [Parameter(Mandatory = $false)]
    [Switch] $NoZip
)

$ErrorActionPreference = "Stop"
$SOURCE_DIR = "./Modules"
$SOURCE_REPO = "https://dev.sp-tarkov.com/SPT/Modules.git"

$BuildOnCommit = $Commit.Length -gt 0

if (Test-Path -Path $SOURCE_DIR) {
    if ($Overwrite -or (Read-Host "$SOURCE_DIR exists, delete? [y/n]") -eq 'y') {
        Write-Output "$SOURCE_DIR exists, removing"
        Remove-Item -Recurse -Force $SOURCE_DIR
    }
    else
    {
        Exit 1
    }
}

Write-Output "clone repo"
if ( $Branch.Length -gt 0 )
{
    Write-Output "Cloning branch $Branch"
    git clone --depth 1 -b $Branch $SOURCE_REPO $SOURCE_DIR
} 
else
{
    Write-Output "Branch not given, using default branch"
    git clone --depth 1 $SOURCE_REPO $SOURCE_DIR
}

Set-Location $SOURCE_DIR


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

Write-Output "Download tarkov dlls"
Invoke-WebRequest -Uri "$Url$TarkovVersion.zip" -OutFile "./dlls.zip"
Expand-Archive -Path "./dlls.zip" -DestinationPath "./project/Shared/Managed"
Get-ChildItem "./project/Shared/Managed"

Write-Output "build"
Set-Location ./project
dotnet restore
dotnet build

if ($LASTEXITCODE -ne 0) {
    throw ("dotnet build failed, exit code $LASTEXITCODE")
}

if ($BuildOnCommit) {
    $CInfo = "$Head-$CTimeS"
} 
else {
    $CInfo = "$Branch-$Head-$CTimeS"
}

$ZipName = "Aki-Modules-$CInfo-Tarkov$TarkovVersion"

Get-ChildItem ./build
if (!$NoZip) {
    $ZipName = "$ZipName.zip"
    Compress-Archive -Path ./build/* -DestinationPath "../$ZipName" -Force
    Write-Output "Built file: $ZipName"
}

Write-Output "ZIP_NAME=$ZipName" >> "$env:GITHUB_OUTPUT"
