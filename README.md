# SPT-AKI_CI
Build scripts for building SPT-Aki Server and client modules.

Also has daily actions built. See [Actions](https://github.com/qe201020335/SPT-AKI_CI/actions).

## Build Aki Server
### Requirements
* PowerShell
* Node 18
* Git
* Git lfs
### Parameters
| Parameter | Required? | Description |
|----------|-----|-----|
| `-Branch` | no | The branch to build on |
| `-Commit` | no | The exact commit to build, doesn't matter which branch it is |
| `-Overwrite` | no | If present, will delete existing source folder without asking |
### Examples
Build the default branch (aka master or main)
```bash
pwsh ./build_server.ps1
```
Build the `0.13.5.0` branch
```bash
pwsh ./build_server.ps1 -Branch 0.13.5.0
```

