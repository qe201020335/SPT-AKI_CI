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
Build an exact commit
```bash
pwsh ./build_server.ps1 -Commit fbb1d7eb2f6b7847fc1d6bfb2f36dd794f3b1301
```

### Tags and Commit Hashes
You can also find the tags on SPT-Aki's server source webpage. [Tags](https://dev.sp-tarkov.com/SPT-AKI/Server/tags)
Values here are for easy reference and copy paste.
| Version | Tag Name | Short Hash | Commit Hash (Full) |
|---------|----------|---------------------|--------------------|
| 3.7.1 | `3.7.1` | `fbb1d7eb2f` | `fbb1d7eb2f6b7847fc1d6bfb2f36dd794f3b1301`
