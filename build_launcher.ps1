Param(
    [Parameter(Mandatory=$false)]
    [Switch] $Overwrite,

    [Parameter(Mandatory=$false)]
    [string] $Branch
)

$ErrorActionPreference = "Stop"
$SOURCE_DIR = "./Launcher"
$SOURCE_REPO = "https://dev.sp-tarkov.com/SPT-AKI/Launcher.git"

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

if ($Commit.Length -gt 0) {
    Write-Output "Checking out the commit $Commit"
    git fetch --depth=1 $SOURCE_REPO $Commit
    git checkout $Commit

    if ($LASTEXITCODE -ne 0) {
        throw ("Commit $Commit checkout failed. It doesn't exist? git exit code $LASTEXITCODE")
    }
}

$Head = git rev-parse --short HEAD
$Branch = git rev-parse --abbrev-ref HEAD
$CTime = git log -1 --format="%at"
$CTimeS = (([System.DateTimeOffset]::FromUnixTimeSeconds($CTime)).DateTime).ToString("yyyyMMddHHmmss")

Write-Output "Current HEAD is at $Head in $Branch committed at $CTimeS"

Write-Output "build"
Set-Location ./project
dotnet restore
dotnet tool restore
dotnet cake

if ($LASTEXITCODE -ne 0) {
    throw ("cake build failed, exit code $LASTEXITCODE")
}

Get-ChildItem ./Build
