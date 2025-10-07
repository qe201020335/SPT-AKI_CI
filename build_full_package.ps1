Param(
    [Parameter(Mandatory=$false)]
    [Switch] $PkgOnly,

    [Parameter(Mandatory=$false)]
    [Switch] $Overwrite,

    [Parameter(Mandatory=$false)]
    [Switch] $NoZip,

    [Parameter(Mandatory=$false)]
    [Switch] $IsV4,

    [Parameter(Mandatory=$false)]
    [string] $ServerBranch,

    [Parameter(Mandatory=$false)]
    [string] $ModulesBranch,

    [Parameter(Mandatory=$false)]
    [string] $LauncherBranch,

    [Parameter(Mandatory=$false)]
    [string] $TarkovVersion,

    [Parameter(Mandatory=$false)]
    [string] $Url
)

$ErrorActionPreference = "Stop"

$NeedBuild = !$PkgOnly

if ($NeedBuild -and ($Url.Length -eq 0 -or $TarkovVersion.Length -eq 0)) {
    throw "Not PkgOnly, missing Url and/or TarkovVersion"
}

if ($Overwrite) {
    $OverwriteFlag = "-Overwrite"
}
else {
    $OverwriteFlag = ""
}

$ServerBuild = "./Server/project/build"
$ModulesBuild = "./Modules/project/Build"
$LauncherBuild = "./Launcher/project/Build"
$CSharpServerBuild = "./server-csharp/Build"

$PackagerSouceZipLink = "https://github.com/sp-tarkov/build/archive/refs/heads/main.zip"
$OutputFolder = "./output"

if (Test-Path -Path $OutputFolder) {
    if ($Overwrite -or (Read-Host "$OutputFolder exists, delete? [y/n]") -eq 'y') {
        Write-Output "$OutputFolder exists, removing"
        Remove-Item -Recurse -Force $OutputFolder
    }
    else
    {
        Exit 1
    }
}

New-Item -Path "$OutputFolder" -ItemType "Directory"

if ($NeedBuild) {
    # build server
    if (!$IsV4) {
        Write-Output "Building SPT Node Server"
        pwsh ./build_server.ps1 $OverwriteFlag -Branch $ServerBranch -Os win32 -Arch x64 -NoZip -Release
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
        Get-ChildItem "$ServerBuild"
    }
    else {
        Write-Output "Building SPT .NET Server"
        pwsh ./build_server_csharp.ps1 $OverwriteFlag -Branch $ServerBranch -Runtime win-x64 -NoZip -Release
        if ($LASTEXITCODE -ne 0) {
            Exit $LASTEXITCODE
        }
        Get-ChildItem "$CSharpServerBuild"
    }

    # build modules
    Write-Output "Building SPT Modules"
    Write-Output "Using SPT server compatible tarkov version: $TarkovVersion"
    pwsh ./build_modules.ps1 $OverwriteFlag -Branch $ModulesBranch -Url $Url -TarkovVersion $TarkovVersion -NoZip
    if ($LASTEXITCODE -ne 0) {
        Exit $LASTEXITCODE
    }
    Get-ChildItem "$ModulesBuild/BepInEx/plugins/spt"

    # build launcher
    Write-Output "Building SPT Launcher"
    pwsh ./build_launcher.ps1 $OverwriteFlag -Branch $LauncherBranch
    if ($LASTEXITCODE -ne 0) {
        Exit $LASTEXITCODE
    }
    Get-ChildItem "$LauncherBuild"
}

# Extra files
Invoke-WebRequest -Uri "$PackagerSouceZipLink" -OutFile "./packager.zip"
if (Test-Path -Path "./PackagerFiles") {
    Remove-Item -Recurse -Force "./PackagerFiles"
}
Expand-Archive -Path "./packager.zip" -DestinationPath "./PackagerFiles"

if ($IsV4)
{
    $StaticAssetsPath = "PackagerFiles/build-main/static-assets-csharp"
}
else {
    $StaticAssetsPath = "PackagerFiles/build-main/static-assets"
}

Copy-Item -Recurse -Force -Path "./$StaticAssetsPath/*" -Destination "$OutputFolder"

if (!$IsV4) {
    $SPTMetaFile = "$ServerBuild/SPT_Data/Server/configs/core.json"
}
else {
    $SPTMetaFile = "$CSharpServerBuild/SPT_Data/configs/core.json"
}
$SPTMeta = (Get-Content "$SPTMetaFile" | ConvertFrom-Json -AsHashtable)
Write-Output $SPTMeta
$SPTCompatVersion = $SPTmeta.compatibleTarkovVersion

if (!$IsV4) {
    $SPTVersion = $SPTmeta.sptVersion
}
else {
    $SPTVersion = (Select-Xml -Path "./server-csharp/Build.props" '//SptVersion').Node.InnerText
}

Write-Output "Copying SPT projects"
if (!$IsV4) {
    Copy-Item -Recurse -Force -Path "$ServerBuild/*" -Destination "$OutputFolder"
    Copy-Item -Recurse -Force -Path "$LauncherBuild/*" -Destination "$OutputFolder"
}
else {
    New-Item -Path "$OutputFolder/SPT" -ItemType Directory
    Copy-Item -Recurse -Force -Path "$CSharpServerBuild/*" -Destination "$OutputFolder/SPT"
    Copy-Item -Recurse -Force -Path "$LauncherBuild/*" -Destination "$OutputFolder/SPT"
}

Copy-Item -Recurse -Force -Path "$ModulesBuild/*" -Destination "$OutputFolder"
Get-ChildItem "$OutputFolder"

$ZipName = "SPT-$SPTVersion-$SPTCompatVersion-$(Get-Date -Format "yyyyMMdd")"
Write-Output $ZipName
if (!$NoZip) {
    # make the final zip
    $ZipName = "$ZipName.zip"
    Write-Output "Zipping files"
    Compress-Archive -Path "$OutputFolder/*" -DestinationPath "./$ZipName" -Force
    Write-Output "Packaged file: $ZipName"
}

Write-Output "ZIP_NAME=$ZipName" >> "$env:GITHUB_OUTPUT"
