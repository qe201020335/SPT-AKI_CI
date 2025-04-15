# SPT-AKI_CI <a href="https://github.com/qe201020335/SPT-AKI_CI/actions"><img src="https://img.shields.io/github/actions/workflow/status/qe201020335/SPT-AKI_CI/build.yml?branch=master&style=for-the-badge" alt="GitHub Actions status" align="right"></a>

Scripts for
building [SPT Server](https://github.com/sp-tarkov/server), [SPT .NET Server](https://github.com/sp-tarkov/server-csharp), [SPT Launcher](https://github.com/sp-tarkov/launcher), [SPT Modules](https://github.com/sp-tarkov/modules)
and also making an entire release package.

Also has daily builds if you want to stay on the bleeding edge of bleeding edge.
See [Actions](https://github.com/qe201020335/SPT-AKI_CI/actions).

> [!IMPORTANT]
> Make sure to always back up your profiles before using any builds!

> [!CAUTION]
> Do NOT report any issues you have using the scripts or builds to the sp-tarkov team!
>
> Use them at your own risk! Open an issue [here](https://github.com/qe201020335/SPT-AKI_CI/issues) if you have any problems with the scripts or builds.

## Build SPT Node Server

`build_server.ps1` is used to build the SPT Node server.

### Requirements

* PowerShell
* Node 20 (3.10.x) or Node 22 (3.11.x)
* Git
* Git lfs

### Parameters

| Parameter    | Required? | Description                                                   |
|--------------|-----------|---------------------------------------------------------------|
| `-Branch`    | no        | The branch or tag to build on                                 |
| `-Commit`    | no        | The exact commit to build, doesn't matter which branch it is  |
| `-Overwrite` | no        | If present, will delete existing source folder without asking |
| `-Release`   | no        | If present, will make a release build instead of debug        |
| `-NoZip`     | no        | If present, will not compress the output to an archive        |

### Examples

Build the default branch (aka master or main)

```pwsh
pwsh ./build_server.ps1
```

Build an exact commit

```pwsh
pwsh ./build_server.ps1 -Commit fbb1d7eb2f6b7847fc1d6bfb2f36dd794f3b1301
```

Make a release build on a tag. Find out tag names on SPT's source repo. [Tags](https://github.com/sp-tarkov/server/tags)

```pwsh
pwsh ./build_server.ps1 -Release -Branch 3.7.5
```

## Build SPT .NET Server

`build_server_csharp.ps1` is used to build the SPT .NET server.

### Requirements

* PowerShell
* .NET 9 SDK
* Git
* Git lfs

### Parameters

| Parameter        | Required? | Description                                                                                                                                  |
|------------------|-----------|----------------------------------------------------------------------------------------------------------------------------------------------|
| `-Branch`        | no        | The branch or tag to build on                                                                                                                |
| `-Commit`        | no        | The exact commit to build, doesn't matter which branch it is                                                                                 |
| `-Runtime`       | no        | The target runtime to build for, such as `win-x64`, `linux-arm64`. See [.NET RID](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) |
| `-SelfContained` | no        | If present, output build will have .NET runtime bundled                                                                                      |
| `-Overwrite`     | no        | If present, will delete existing source folder without asking                                                                                |
| `-Release`       | no        | If present, will make a release build instead of debug                                                                                       |
| `-NoZip`         | no        | If present, will not compress the output to an archive                                                                                       |

## Build SPT Modules

`build_modules.ps1` is used to build the SPT client modules.

The script will download the necessary Tarkov managed dlls for building. It will use the url: `$Url$TarkovVersion.zip`.
The zip should have all the dlls from `EscapeFromTarkov_Data/Managed` in the **root** of the archive.

### Requirements

* PowerShell
* .NET SDK
* Git

### Parameters

| Parameter        | Required? | Description                                                   |
|------------------|-----------|---------------------------------------------------------------|
| `-Branch`        | no        | The branch or tag to build on                                 |
| `-Commit`        | no        | The exact commit to build, doesn't matter which branch it is  |
| `-TarkovVersion` | **yes**   | Version of the Tarkov game it is building for                 |
| `-Url`           | **yes**   | Tarkov managed dll zip base url                               |
| `-Overwrite`     | no        | If present, will delete existing source folder without asking |
| `-NoZip`         | no        | If present, will not compress the output to an archive        |
