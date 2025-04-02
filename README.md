# SPT-AKI_CI <a href="https://github.com/qe201020335/SPT-AKI_CI/actions"><img src="https://img.shields.io/github/actions/workflow/status/qe201020335/SPT-AKI_CI/build.yml?branch=master&style=for-the-badge" alt="GitHub Actions status" align="right"></a>

Scripts for building [SPT Server](https://github.com/sp-tarkov/server), [SPT .NET Server](https://github.com/sp-tarkov/server-csharp), [SPT Launcher](https://github.com/sp-tarkov/launcher), [SPT Modules](https://github.com/sp-tarkov/modules) and also making an entire release package.

Also has daily builds if you want to stay on the bleeding edge of bleeding edge. See [Actions](https://github.com/qe201020335/SPT-AKI_CI/actions).

> [!IMPORTANT] 
> Make sure to always backup your profiles before using any builds!

> [!CAUTION]
> Do NOT report any issues you have using the scripts or builds to the sp-tarkov team!
>
> Use them at your own risk!


## Build SPT Server
### Requirements
* PowerShell
* Node 20 (3.10.x) or Node 22 (3.11.x)
* Git
* Git lfs
### Parameters
| Parameter | Required? | Description |
|----------|-----|-----|
| `-Branch` | no | The branch to build on |
| `-Commit` | no | The exact commit to build, doesn't matter which branch it is |
| `-Overwrite` | no | If present, will delete existing source folder without asking |
| `-Release` | no | If present, will make a release build instead of debug |
### Examples
Build the default branch (aka master or main)
```pwsh
pwsh ./build_server.ps1
```
Build the `0.13.5.0` branch
```pwsh
pwsh ./build_server.ps1 -Branch 0.13.5.0
```
Build a tag. Find out tag names on SPT's source repo. [Tags](https://github.com/sp-tarkov/server/tags) 
```pwsh
pwsh ./build_server.ps1 -Branch 3.7.2
```
Build an exact commit
```pwsh
pwsh ./build_server.ps1 -Commit fbb1d7eb2f6b7847fc1d6bfb2f36dd794f3b1301
```
Make a release build on the tag 3.7.5
```pwsh
pwsh ./build_server.ps1 -Release -Branch 3.7.5
```
