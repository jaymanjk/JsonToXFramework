<!-- Copyright (c) 2026 Axel Johnson International. All rights reserved. -->

# Contributing to Axbus Framework

Thank you for your interest in contributing to Axbus!

## Before You Start

1. Read the [architecture overview](docs/architecture/overview.md)
2. Read the [copilot-instructions.md](.github/copilot-instructions.md) —
   this is the authoritative coding standard for all contributions
3. Check existing [issues](../../issues) before opening a new one

## Development Setup

1. Clone the repository
2. Open `Axbus.sln` in Visual Studio 2022+
3. Ensure .NET 8 SDK is installed
4. Restore NuGet packages
5. Build solution — all projects should build with zero warnings

## Coding Standards

All contributions MUST follow the rules in
[.github/copilot-instructions.md](.github/copilot-instructions.md).

Key rules:
- Full XML documentation on all public members
- StyleCop copyright header on every `.cs` file
- Using statements below namespace declaration
- No underscore prefix on private fields
- `ConfigureAwait(false)` in all library async methods
- Structured logging only — no string interpolation in log messages
- Plugins must only depend on `Axbus.Core`

## Writing a New Plugin

1. Create new Class Library project: `Axbus.Plugin.{Reader|Writer}.{Format}`
2. Add project reference to `Axbus.Core` only
3. Implement `IPlugin` in `{Format}Plugin.cs`
4. Create `{AssemblyName}.manifest.json` alongside the plugin class
5. Implement only the pipeline stages your plugin supports
6. Return `null` from unsupported `Create*()` methods
7. Add a test project: `Axbus.Plugin.{Reader|Writer}.{Format}.Tests`

## Pull Request Process

1. Fork the repository
2. Create a feature branch: `feature/your-feature-name`
3. Make your changes following coding standards
4. Ensure all tests pass: `dotnet test`
5. Fill in the PR template completely
6. Request review

## Commit Message Format