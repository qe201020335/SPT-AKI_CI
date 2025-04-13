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

if ($NeedBuild) {
    # build server
    if (!$IsV4) {
        Write-Output "Building SPT Node Server"
        pwsh ./build_server.ps1 $OverwriteFlag -Branch $ServerBranch -NoZip -Release
        Get-ChildItem "$ServerBuild"
    }
    else {
        Write-Output "Building SPT .NET Server"
        pwsh ./build_server_csharp.ps1 $OverwriteFlag -Branch $ServerBranch -NoZip -Release -SelfContained
        Get-ChildItem "$ServerBuild"
    }

    # build modules
    Write-Output "Building SPT Modules"
    Write-Output "Using SPT server compatible tarkov version: $TarkovVersion"
    pwsh ./build_modules.ps1 $OverwriteFlag -Branch $ModulesBranch -Url $Url -TarkovVersion $TarkovVersion -NoZip
    Get-ChildItem "$ModulesBuild/BepInEx/plugins/spt"

    # build launcher
    Write-Output "Building SPT Launcher"
    pwsh ./build_launcher.ps1 $OverwriteFlag -Branch $LauncherBranch
    Get-ChildItem "$LauncherBuild"
}

# Extra files
Invoke-WebRequest -Uri "$PackagerSouceZipLink" -OutFile "./packager.zip"
if (Test-Path -Path "./PackagerFiles") {
    Remove-Item -Recurse -Force "./PackagerFiles"
}
Expand-Archive -Path "./packager.zip" -DestinationPath "./PackagerFiles"
Copy-Item -Recurse -Force -Path "./PackagerFiles/build-main/static-assets/" -Destination "$OutputFolder"

if (!$IsV4) {
    $SPTMetaFile = "$ServerBuild/SPT_Data/Server/configs/core.json"
}
else {
    $SPTMetaFile = "$CSharpServerBuild/Assets/configs/core.json"
}
$SPTMeta = (Get-Content "$SPTMetaFile" | ConvertFrom-Json -AsHashtable)
Write-Output $SPTMeta
$SPTCompatVersion = $SPTmeta.compatibleTarkovVersion
$SPTVersion = $SPTmeta.sptVersion

Write-Output "Copying SPT projects"
if (!$IsV4) {
    Copy-Item -Recurse -Force -Path "$ServerBuild/*" -Destination "$OutputFolder"
}
else {
    Copy-Item -Recurse -Force -Path "$CSharpServerBuild/*" -Destination "$OutputFolder/SPTarkov.Server/"
}
Copy-Item -Recurse -Force -Path "$ModulesBuild/*" -Destination "$OutputFolder"
Copy-Item -Recurse -Force -Path "$LauncherBuild/*" -Destination "$OutputFolder"

$ZipName = "SPT-$SPTVersion-$SPTCompatVersion-$(Get-Date -Format "yyyyMMdd")"
Get-ChildItem "$OutputFolder"
if (!$NoZip) {
    # make the final zip
    $ZipName = "$ZipName.zip"
    Write-Output "Zipping files"
    Compress-Archive -Path "$OutputFolder/*" -DestinationPath "./$ZipName" -Force
    Write-Output "Packaged file: $ZipName"
}

Write-Output "ZIP_NAME=$ZipName" >> "$env:GITHUB_OUTPUT"
