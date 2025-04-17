# Go-Steam Protocol Generator Readme

This guide explains how to use the `generate.ps1` PowerShell script to regenerate the Go files for Steam Language enums/messages and Protobuf definitions based on the SteamKit submodule.

This is necessary if you want to update to the latest protocol definitions from SteamKit.

## Prerequisites

Before running the script, ensure you have the following installed and configured on your Windows system:

1.  **Git:** Required for managing the repository and submodules.
2.  **.NET SDK:** Required to build and run the `GoSteamLanguageGenerator` tool. Download from [https://dotnet.microsoft.com/download](https://dotnet.microsoft.com/download).
3.  **Go:** Required to run the `generator.go` script and format the generated files. Download from [https://golang.org/dl/](https://golang.org/dl/).
4.  **Protobuf Compiler (`protoc`):** Required to compile `.proto` files into Go code. Download the `protoc-*-win64.zip` from the [Protobuf Releases page](https://github.com/protocolbuffers/protobuf/releases) and ensure `protoc.exe` is in your system's PATH.

## Setup Steps

1.  **Initialize Submodules:**
    *   Open a terminal (like PowerShell or Git Bash) in the root directory of the `go-steam` project (`Dota2LobbyBot/dota2-bot-project/go-steam/`).
    *   Run the following command to download the necessary SteamKit files into the `generator/SteamKit` directory:
        ```bash
        git submodule update --init --recursive
        ```

2.  **Build `GoSteamLanguageGenerator` Tool:**
    *   Navigate into the GoSteamLanguageGenerator directory:
        ```powershell
        cd GoSteamLanguageGenerator
        ```
    *   Build the .NET project using the .NET SDK. This will create the necessary executable in `bin\Debug\`.
        ```powershell
        dotnet build
        ```
    *   Navigate back to the `generator` directory:
        ```powershell
        cd ..
        ```

## Running the Generator Script

1.  **Open PowerShell:**
    *   Navigate to this `generator` directory (`Dota2LobbyBot/dota2-bot-project/go-steam/generator/`) in File Explorer.
    *   Hold down `Shift`, right-click in the empty space of the folder, and select "Open PowerShell window here" or "Open in Windows Terminal".

2.  **Check PowerShell Execution Policy (If Necessary):**
    *   If you encounter an error about script execution being disabled, you may need to adjust the policy for your user.
    *   Check the current policy: `Get-ExecutionPolicy`
    *   If it's `Restricted`, you can allow locally signed scripts by running: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`. You'll need to confirm with `Y`.

3.  **Run the Script:**
    *   Execute the script:
        ```powershell
        .\generate.ps1
        ```
    *   This will run the Go program (`generator.go`) which in turn calls the .NET tool and `protoc` to generate both Steam Language and Protobuf files by default.
    *   You can specify targets:
        *   Generate only Steam Language files: `.\generate.ps1 -Target steamlang`
        *   Generate only Protobuf files: `.\generate.ps1 -Target proto`

4.  **Monitor Output:**
    *   The script will output status messages and any errors encountered during the process.
    *   If successful, the relevant `.go` files in the `../protocol/steamlang` and `../protocol/protobuf` (and other protocol directories like `tf2`) will be updated or created.
    *   If errors occur, review the output in the PowerShell window to diagnose the problem (e.g., missing prerequisites, build errors).

5.  **Review Changes:** Use `git status` or your Git client in the `go-steam` directory to see the generated file changes.

## Troubleshooting

### Null Characters in Source File (e.g., `error CS1056: Unexpected character '\0'`)**

This error usually indicates file corruption within the `SteamKit` submodule, often caused during checkout or update.

To fix this:

1.  **Open Terminal:** Open PowerShell or Git Bash in the root `go-steam` directory (`Dota2LobbyBot/dota2-bot-project/go-steam/`).
2.  **Reset Submodule:** Run the following commands:
    ```bash
    # De-initialize the submodule
    git submodule deinit --force generator/SteamKit

    # Remove the potentially corrupted directory
    # PowerShell alternative: Remove-Item -Recurse -Force generator/SteamKit
    rm -rf generator/SteamKit

    # Re-initialize and update the submodule
    git submodule update --init --recursive generator/SteamKit
    ```
3.  **Retry Build:** Navigate back to `generator/GoSteamLanguageGenerator` and run `dotnet build` again.

### Target Framework Mismatch Error (`It cannot be referenced by a project that targets...` or `MSB4184`)

If you see an error like:
`Project 'SteamLanguageParser.csproj' targets 'netcoreappX.Y'. It cannot be referenced by a project that targets '.NETFramework,Version=vZ.W'.`
Or:
`error MSB4184: The expression "[MSBuild]::VersionGreaterThanOrEquals(...)" cannot be evaluated. Version string was not in a correct format.`

It means the `GoSteamLanguageGenerator.csproj` file is using an old project format or targeting an incompatible framework (like `.NET Framework 4.8`) compared to its dependency from SteamKit (`.NET Core`) or the modern .NET SDK.

To fix this:

1.  **Convert to SDK-Style Project:** Ensure `GoSteamLanguageGenerator.csproj` uses the modern SDK-style format (starting with `<Project Sdk="Microsoft.NET.Sdk">`). See the current file for an example.
2.  **Edit Project File:** Open `Dota2LobbyBot/dota2-bot-project/go-steam/generator/GoSteamLanguageGenerator/GoSteamLanguageGenerator.csproj` in a text editor.
3.  **Change Target Framework:** Find the line `<TargetFramework>...</TargetFramework>`. Update the value to a modern, compatible .NET version installed on your system (e.g., `net6.0`, `net7.0`, `net8.0`). Example: `<TargetFramework>net8.0</TargetFramework>`.
4.  **Save** the file.
5.  **Retry Build:** Run `dotnet build` again in the `GoSteamLanguageGenerator` directory.

### Duplicate Attributes / Version Wildcard Errors (`CS0579`, `CS8357`)

If you encounter errors like:
`error CS0579: Duplicate 'AssemblyCompany' attribute`
Or:
`error CS8357: The specified version string '1.0.*' contains wildcards...`

These occur after converting to the SDK-style project because the old `Properties/AssemblyInfo.cs` file conflicts with automatically generated assembly information.

To fix this:

1.  **Delete Old File:** Delete the `Properties/AssemblyInfo.cs` file within the `GoSteamLanguageGenerator` directory.
2.  **Ensure Auto-Generation:** (Optional - Usually default) Make sure the `<PropertyGroup>` in `GoSteamLanguageGenerator.csproj` contains `<GenerateAssemblyInfo>true</GenerateAssemblyInfo>`.
3.  **Retry Build:** Run `dotnet build` again.

### Inconsistent Accessibility Errors (`CS0050`, `CS0051`, `CS0053`)

If you see errors like:
`error CS0053: Inconsistent accessibility: property type 'TokenSourceInfo' is less accessible than property 'Token.Source'`
Or:
`error CS0051: Inconsistent accessibility: parameter type 'Token' is less accessible than method 'TokenAnalyzer.Analyze(Queue<Token>)'`

This means a public type or member is trying to use another type that is not public (it's likely `internal` by default).

To fix this:

1.  **Identify Inaccessible Type:** Note the type name mentioned in the error message (e.g., `TokenSourceInfo`, `Token`, `TokenAnalyzer`).
2.  **Locate Definition:** Find the C# file where this type is defined (usually within the `generator/SteamKit/Resources/SteamLanguageParser/Parser/` directory).
3.  **Add `public`:** Open the file and add the `public` keyword before the `class`, `struct`, or `enum` definition of the inaccessible type.
    *   Example: Change `struct TokenSourceInfo` to `public struct TokenSourceInfo`.
4.  **Repeat:** You might need to repeat this for several types mentioned in the errors.
5.  **Retry Build:** Run `dotnet build` again.
