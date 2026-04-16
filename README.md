<!-- Copyright (c) 2026 Axel Johnson International. All rights reserved. -->

# Axbus Framework

> Enterprise-grade, plugin-based, extensible data transformation framework for .NET 8.

## What Is Axbus?

Axbus is a generic pipeline framework that converts any file format to any other file
format via a discoverable, isolated plugin system. The framework itself never knows
about specific file formats — all format knowledge lives in independently deployable
plugins.

Source File(s)
→ [Reader Plugin]
→ [Parser Plugin]
→ [Transformer Plugin]
→ [Writer Plugin]
→ Output File(s)

## Key Features

- **Plugin-based architecture** — Add new formats without touching framework code
- **Pipeline pattern** — Typed stage chain with middleware support
- **Async end-to-end** — Streaming with `IAsyncEnumerable`, no full-file loads
- **Observable notifications** — `IProgress<T>` + `IObservable<ConversionEvent>`
- **Graceful cancellation** — `CancellationToken` throughout
- **Configurable parallelism** — Module-level and root-level parallel control
- **Error resilience** — Per-row error strategies including error output files
- **Plugin isolation** — `AssemblyLoadContext` per plugin, no DLL conflicts

## Projects

| Project | Description | NuGet |
|---|---|---|
| `Axbus.Core` | Pure abstractions, models, enums | ✅ |
| `Axbus.Application` | Pipeline engine, orchestration | ✅ |
| `Axbus.Infrastructure` | Generic I/O, Serilog, connectors | ✅ |
| `Axbus.Plugin.Reader.Json` | JSON reader/parser/transformer | ✅ |
| `Axbus.Plugin.Writer.Csv` | CSV schema builder + writer | ✅ |
| `Axbus.Plugin.Writer.Excel` | Excel schema builder + writer | ✅ |
| `Axbus.ConsoleApp` | Console client | ❌ |
| `Axbus.WinFormsApp` | WinForms client | ❌ |

## Quick Start

### Install Packages
```bash
dotnet add package Axbus.Core
dotnet add package Axbus.Application
dotnet add package Axbus.Infrastructure
dotnet add package Axbus.Plugin.Reader.Json
dotnet add package Axbus.Plugin.Writer.Csv
```

### Configure `appsettings.json`
```json
{
  "RunInParallel": false,
  "PluginSettings": {
    "PluginsFolder": null,
    "IsolatePlugins": true,
    "Plugins": [
      "Axbus.Plugin.Reader.Json",
      "Axbus.Plugin.Writer.Csv"
    ]
  },
  "ConversionModules": [
    {
      "ConversionName": "SalesOrders",
      "IsEnabled": true,
      "ExecutionOrder": 1,
      "SourceFormat": "json",
      "TargetFormat": "csv",
      "Source": {
        "Type": "FileSystem",
        "Path": "C:\\input\\sales",
        "FilePattern": "*.json"
      },
      "Target": {
        "Type": "FileSystem",
        "Path": "C:\\output\\sales"
      },
      "Pipeline": {
        "SchemaStrategy": "FullScan",
        "RowErrorStrategy": "WriteToErrorFile",
        "MaxExplosionDepth": 3
      }
    }
  ]
}
```

### Register Plugins
```csharp
// 1. Register each plugin as IPlugin in DI — framework controls lifecycle
services.AddSingleton<IPlugin, JsonReaderPlugin>();
services.AddSingleton<IPlugin, CsvWriterPlugin>();
services.AddSingleton<IPlugin, ExcelWriterPlugin>();

// 2. AddAxbusApplication() automatically registers PluginRegistrationService,
//    which reads each plugin's .manifest.json at startup and populates
//    IPluginRegistry before the first pipeline is created.
services.AddAxbusApplication(configuration);
services.AddAxbusInfrastructure(configuration);
```

> **Note:** Each plugin assembly must ship with a companion `{AssemblyName}.manifest.json`
> file in the same directory. Add `<Content>` entries to your plugin `.csproj` files so
> the manifests are copied to the build output:
> ```xml
> <Content Include="Axbus.Plugin.Reader.Json.manifest.json">
>   <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
> </Content>
> ```

## Writing a Custom Plugin

See [docs/guides/plugin-development.md](docs/guides/plugin-development.md).

## Architecture

See [docs/architecture/overview.md](docs/architecture/overview.md).

## License

MIT — Copyright (c) 2026 Axel Johnson International. All rights reserved.
