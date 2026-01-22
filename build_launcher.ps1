Param(
    [Parameter(Mandatory=$false)]
    [Switch] $Overwrite,

    [Parameter(Mandatory=$false)]
    [string] $Branch,
    
    [Parameter(Mandatory = $false)]
    [string] $Runtime
)

$ErrorActionPreference = "Stop"
$SOURCE_DIR = "./Launcher"
$SOURCE_REPO = "https://github.com/sp-tarkov/launcher.git"

$BuildOnCommit = $Commit.Length -gt 0

if ($Runtime.Length -eq 0) {
    if ($IsWindows)
    {
        $Runtime = "win-x64"
    } 
    elseif ($IsLinux) {
        $Runtime = "linux-x64"
    }
    else {
        throw "Unsupported OS for launcher build"
    }
}

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

Write-Output "build"
Set-Location ./project
if (Test-Path -Path "./SPTarkov.Launcher")
{
    # new launcher 
    # using the logic here instead of their build script becuase theirs is broken atm
    dotnet build --property WarningLevel=0 "./SPTarkov.Core/SPTarkov.Core.csproj" -c Release -p:OutputType=Library
    if ($LASTEXITCODE -ne 0) {
        throw ("dotnet build SPTarkov.Core failed, exit code $LASTEXITCODE")
    }
    Copy-Item "./SPTarkov.Core/bin/Release/net10.0/MudBlazor.min.css" "./SPTarkov.Launcher/wwwroot/MudBlazor.min.css"
    Copy-Item "./SPTarkov.Core/bin/Release/net10.0/MudBlazor.min.js" "./SPTarkov.Launcher/wwwroot/MudBlazor.min.js"

    dotnet publish --property WarningLevel=0 "./SPTarkov.Launcher/SPTarkov.Launcher.csproj" -c Release --self-contained false --runtime $Runtime -p:PublishSingleFile=true
    if ($LASTEXITCODE -ne 0) {
        throw ("dotnet build SPTarkov.Launcher failed, exit code $LASTEXITCODE")
    }

    if (Test-Path -Path "./Build") { 
        Remove-Item "./Build" -Recurse -Force 
    }
    New-Item -Path "./" -Name "Build" -ItemType "Directory"
    Copy-Item "./SPTarkov.Launcher/bin/Release/net10.0/$Runtime/publish/SPTarkov.Launcher*" "./Build/"
    Copy-Item "./SPTarkov.Core/SPT_Data" "./Build/SPT_Data" -Recurse
}
else {
    dotnet restore
    dotnet build --property WarningLevel=0 SPT.Build

    if ($LASTEXITCODE -ne 0) {
        throw ("dotnet build failed, exit code $LASTEXITCODE")
    }
}

Get-ChildItem ./Build
