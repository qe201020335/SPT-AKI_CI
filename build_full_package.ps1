Param(
    [Parameter(Mandatory=$false)]
    [Switch] $Overwrite,

    [Parameter(Mandatory=$false)]
    [string] $ServerBranch,

    [Parameter(Mandatory=$false)]
    [string] $ModulesBranch,

    [Parameter(Mandatory=$false)]
    [string] $LauncherBranch,

    [Parameter(Mandatory=$true)]
    [string] $TarkovVersion,

    [Parameter(Mandatory=$true)]
    [string] $Url
)

$ErrorActionPreference = "Stop"

if ($Overwrite) {
    $OverwriteFlag = "-Overwrite"
}
else {
    $OverwriteFlag = ""
}

$ServerBuild = "./Server/project/build"
$ModulesBuild = "./Modules/project/Build"
$LauncherBuild = "./Launcher/project/Build"

$PackagerSouceZipLink = "https://dev.sp-tarkov.com/SPT-AKI/release-packager-tool/archive/main.zip"
$BepInExLink = "https://github.com/BepInEx/BepInEx/releases/download/v5.4.19/BepInEx_x64_5.4.19.0.zip"
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

# build server
Write-Output "Building Aki Server"
pwsh ./build_server.ps1 $OverwriteFlag -Branch $ServerBranch -NoZip
Get-ChildItem "$ServerBuild"
$AkiMeta = (Get-Content "$ServerBuild/Aki_Data/Server/configs/core.json" | ConvertFrom-Json -AsHashtable)
Write-Output $akiMeta
# $TarkovVersion = $akimeta.compatibleTarkovVersion  # this doesn't always work, aki may omit a digit such as 0.13.5.3.26535 => 0.13.5.26535
$AkiVersion = $akimeta.akiVersion

# build modules
Write-Output "Building Aki Modules"
Write-Output "Using Aki server compatible tarkov version: $TarkovVersion"
pwsh ./build_modules.ps1 $OverwriteFlag -Branch $ModulesBranch -Url $Url -TarkovVersion $TarkovVersion -NoZip
Get-ChildItem "$ModulesBuild/BepInEx/plugins/spt"

# build launcher
Write-Output "Building Aki Launcher"
pwsh ./build_launcher.ps1 $OverwriteFlag -Branch $LauncherBranch
Get-ChildItem "$LauncherBuild"

# Add extra files
Write-Output "Adding extra files"
Invoke-WebRequest -Uri "$BepInExLink" -OutFile "./bepinex.zip"
Expand-Archive -Path "./bepinex.zip" -DestinationPath "$OutputFolder" -Force

Invoke-WebRequest -Uri "$PackagerSouceZipLink" -OutFile "./packager.zip"
if (Test-Path -Path "./PackagerFiles") {
    Remove-Item -Recurse -Force "./PackagerFiles"
}
Expand-Archive -Path "./packager.zip" -DestinationPath "./PackagerFiles"
Copy-Item -Recurse -Force -Path "./PackagerFiles/release-packager-tool/Release-Packager/Release-Packager/BepinExFiles/*" -Destination "$OutputFolder"

Write-Output "Copying Aki projects"
Copy-Item -Recurse -Force -Path "$LauncherBuild/*" -Destination "$OutputFolder"
Copy-Item -Recurse -Force -Path "$ServerBuild/*" -Destination "$OutputFolder"
Copy-Item -Recurse -Force -Path "$ModulesBuild/*" -Destination "$OutputFolder"

# make the final zip
Write-Output "Zipping files"
Get-ChildItem "$OutputFolder"

$ZipName = "SPT-Aki-$AkiVersion-$TarkovVersion-$(Get-Date -Format "yyyyMMdd").zip"
Compress-Archive -Path "$OutputFolder/*" -DestinationPath "./$ZipName" -Force

Write-Output "Packaged file: $ZipName"
Write-Output "ZIP_NAME=$ZipName" >> "$env:GITHUB_OUTPUT"