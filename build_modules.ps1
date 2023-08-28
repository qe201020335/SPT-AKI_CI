Param(
    [Parameter(Mandatory=$false)]
    [Switch] $Overwrite,

    [Parameter(Mandatory=$false)]
    [string] $Branch,

    [Parameter(Mandatory=$true)]
    [string] $Url,

    [Parameter(Mandatory=$true)]
    [string] $TarkovVersion
)

$ErrorActionPreference = "Stop"
$SOURCE_DIR = "./Modules"
$SOURCE_REPO = "https://dev.sp-tarkov.com/SPT-AKI/Modules.git"

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
    git clone -b $Branch $SOURCE_REPO $SOURCE_DIR
} 
else
{
    Write-Output "Branch not given, using default branch"
    git clone $SOURCE_REPO $SOURCE_DIR
}

Set-Location $SOURCE_DIR

$Head = git rev-parse --short HEAD
$Branch = git rev-parse --abbrev-ref HEAD

Write-Output "Current HEAD is at $Head in $Branch"

Write-Output "Download tarkov dlls"
Invoke-WebRequest -Uri "$Url$TarkovVersion.zip" -OutFile "./dlls.zip"
Expand-Archive -Path "./dlls.zip" -DestinationPath "./project/Shared/Managed"
Get-ChildItem "./project/Shared/Managed"

Write-Output "build"
Set-Location ./project
dotnet restore
dotnet tool restore
dotnet cake

Get-ChildItem ./build

$ZipName = "Aki-Modules-{0}-{1}-Tarkov{2}.zip" -f $Branch, $Head, $TarkovVersion

Compress-Archive -Path ./build/* -DestinationPath "../$ZipName"
Write-Output "Built file: $ZipName"
Write-Output "ZIP_NAME=$ZipName" >> "$env:GITHUB_OUTPUT"
