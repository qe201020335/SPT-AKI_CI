Param(
    [Parameter(Mandatory = $false)]
    [Switch] $Overwrite,

    [Parameter(Mandatory = $false)]
    [string] $Branch,

    [Parameter(Mandatory = $false)]
    [string] $Commit

)

$ErrorActionPreference = "Stop"
$SOURCE_REPO = "https://dev.sp-tarkov.com/SPT-AKI/Server.git"
$SERVER_DIR = "./Server"
$GULP_TIMEOUT = 60 # 60 sec is planty for compiling the server

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
    Write-Output "Cloning branch $Branch"
    git clone -b $Branch $SOURCE_REPO $SERVER_DIR
} 
else {
    Write-Output "Branch not given, using default branch"
    git clone $SOURCE_REPO $SERVER_DIR
}

Set-Location $SERVER_DIR

if ($Commit.Length -gt 0) {
    Write-Output "Checking out the commit $Commit"
    git fetch --all
    git checkout $Commit
}

$Head = git rev-parse --short HEAD
$Branch = git rev-parse --abbrev-ref HEAD

Write-Output "Current HEAD is at $Head in $Branch"

Write-Output "lfs"
git lfs fetch
git lfs pull

Write-Output "build"
Set-Location ./project
npm install

Write-Output "Workaround for hardcoded windows path delimiter"
$GULPFILE = "./gulpfile.mjs"
Set-Content -path $GULPFILE ((Get-Content -path $GULPFILE -Raw) -replace "\\\\checks.dat",'/checks.dat')

npm run build:debug *>&1

# Write-Output ("building the server with timeout {0} sec" -f $GULP_TIMEOUT)
# # the gulp task may never return because a file watcher is not being triggered
# $code = {
#     npm run build:debug *>&1

#     if ($LASTEXITCODE -ne 0) {
#         throw ("Build failed. Exit code {0}" -f $LASTEXITCODE)
#     }
# }
# $j = Start-Job -ScriptBlock $code
# Wait-Job $j -Timeout $GULP_TIMEOUT
# Write-Output "Job Output: "
# Receive-Job $j
# Write-Output "Forcefully removing the job"
# Remove-Job -force $j
# Write-Output ("Job state: {0}" -f $j.State)

# if ($j.State -ne "Completed") {
#     # it did not return, we need to manually re-do the unfinished file watch job
#     Write-Output "Gulp was stuck!"
#     if (!(Test-Path -Path "./build/Aki_Data/Server/configs/core.json")) {
#         Write-Output "Something went wrong, the core json doesn't exist"
#         Exit 1
#     }
#     $CoreJson = (Get-Content ./build/Aki_Data/Server/configs/core.json |  ConvertFrom-Json -AsHashtable)
#     if (!$CoreJson.ContainsKey("commit")) {
#         $CoreJson.commit = git rev-parse HEAD
#     }
# } 
# else {
#     Write-Output "Gulp exited!"
# }


if ($IsLinux -eq $true) {
    $Os = "linux"
}
else {
    $Os = "win"
}
Write-Output "Current OS: " $Os

Get-ChildItem ./build
$AkiMeta = (Get-Content ./build/Aki_Data/Server/configs/core.json |  ConvertFrom-Json -AsHashtable)
Write-Output $akiMeta
$ZipName = "Aki-Server-{0}-debug-{1}-{2}-Tarkov{3}.zip" -f $Os, $akimeta.akiVersion, $Head, $akimeta.compatibleTarkovVersion

Compress-Archive -Path ./build/* -DestinationPath "../$ZipName" -Force
Write-Output "Built file: $ZipName"
Write-Output "ZIP_NAME=$ZipName" >> "$env:GITHUB_OUTPUT"
