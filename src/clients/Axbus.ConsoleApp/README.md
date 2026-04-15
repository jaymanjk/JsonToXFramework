# Axbus Console Application

## Overview

The **Axbus ConsoleApp** is a command-line interface for running Axbus data conversion pipelines. It demonstrates how to integrate the Axbus framework into a .NET console application using the Generic Host pattern, dependency injection, and Serilog logging.

---

## Features

- ✅ **Generic Host Integration** - Uses .NET Generic Host for dependency injection and configuration
- ✅ **Serilog Logging** - Structured logging to console and rolling file logs
- ✅ **Progress Reporting** - Real-time progress updates during conversion
- ✅ **Event Streaming** - Observable event stream for lifecycle notifications
- ✅ **Cancellation Support** - Graceful shutdown on Ctrl+C
- ✅ **Multiple Conversions** - Execute multiple conversion modules sequentially or in parallel
- ✅ **Plugin-Based** - JSON Reader, CSV Writer, and Excel Writer plugins included

---

## Quick Start

### Prerequisites

- **.NET 8.0 SDK** or later
- Windows, Linux, or macOS

### Running the Application

1. **Navigate to the ConsoleApp directory:**
   ```bash
   cd src/clients/Axbus.ConsoleApp
   ```

2. **Run the application:**
   ```bash
   dotnet run
   ```

   Or build and run:
   ```bash
   dotnet build
   dotnet run --no-build
   ```

3. **Output will be generated in:**
   - CSV files: `.\Output\Csv\`
   - Excel files: `.\Output\Excel\`
   - Error logs: `.\Output\Errors\`
   - Application logs: `.\logs\`

---

## Sample Data

The application includes three sample JSON files in the `SampleData` folder:

| File | Description | Records |
|---|---|---|
| `customers.json` | Customer data with nested orders | 3 customers |
| `products.json` | Product catalog with specifications | 4 products |
| `employees.json` | Employee records with skills array | 3 employees |

---

## Configuration

### appsettings.json Structure

The application is configured via `appsettings.json`. Key sections:

#### 1. Parallel Execution Settings
```json
{
  "RunInParallel": false,
  "ParallelSettings": {
    "MaxDegreeOfParallelism": 4,
    "MaxConcurrentFileReads": 4,
    "MaxConcurrentFileWrites": 2
  }
}
```

#### 2. Plugin Settings
```json
{
  "PluginSettings": {
    "PluginsFolder": null,
    "ScanSubFolders": true,
    "IsolatePlugins": true,
    "ConflictStrategy": "UseLatestVersion"
  }
}
```

#### 3. Conversion Modules
Each module represents a conversion pipeline:

```json
{
  "ConversionName": "CustomersJsonToCsv",
  "Description": "Convert customer data from JSON to CSV",
  "IsEnabled": true,
  "ExecutionOrder": 1,
  "SourceFormat": "json",
  "TargetFormat": "csv",
  "Source": {
    "Type": "FileSystem",
    "Path": ".\\SampleData",
    "FilePattern": "customers.json"
  },
  "Target": {
    "Type": "FileSystem",
    "Path": ".\\Output\\Csv"
  },
  "Pipeline": {
    "SchemaStrategy": "FullScan",
    "RowErrorStrategy": "WriteToErrorFile",
    "MaxExplosionDepth": 3
  }
}
```

---

## Configuration Options

### Source Options

| Property | Description | Example |
|---|---|---|
| `Type` | Connector type | `"FileSystem"` |
| `Path` | Input folder path (relative or absolute) | `".\\SampleData"` |
| `FilePattern` | File matching pattern | `"*.json"` or `"customers.json"` |
| `ReadMode` | Read mode | `"AllFiles"` or `"FirstFile"` |

### Target Options

| Property | Description | Example |
|---|---|---|
| `Type` | Connector type | `"FileSystem"` |
| `Path` | Output folder path | `".\\Output\\Csv"` |
| `OutputMode` | Output mode | `"SingleFile"` or `"FilePerSource"` |
| `ErrorOutputPath` | Error file location | `".\\Output\\Errors"` |

### Pipeline Options

| Property | Description | Values |
|---|---|---|
| `SchemaStrategy` | Schema detection | `"FullScan"` or `"FirstFile"` |
| `RowErrorStrategy` | Error handling | `"WriteToErrorFile"`, `"Skip"`, `"Throw"` |
| `MaxExplosionDepth` | Array flattening depth | `1`, `2`, `3` (default) |
| `NullPlaceholder` | Null value placeholder | `""` (empty) or `"N/A"` |

---

## Customizing Conversions

### Adding a New Conversion Module

1. **Add a new JSON file** to `SampleData` folder
2. **Add a new module** to `appsettings.json`:

```json
{
  "ConversionName": "MyDataConversion",
  "Description": "Description here",
  "IsEnabled": true,
  "ExecutionOrder": 4,
  "SourceFormat": "json",
  "TargetFormat": "csv",
  "Source": {
    "Path": ".\\SampleData",
    "FilePattern": "mydata.json"
  },
  "Target": {
    "Path": ".\\Output\\Csv"
  }
}
```

### Enabling/Disabling Modules

Set `IsEnabled` to `true` or `false`:

```json
{
  "ConversionName": "EmployeesJsonToCsv",
  "IsEnabled": false  // ← This module will be skipped
}
```

### Changing Output Format

Change `TargetFormat` to switch between CSV and Excel:

```json
{
  "TargetFormat": "excel",  // or "csv"
  "Target": {
    "Path": ".\\Output\\Excel"  // Update output path accordingly
  }
}
```

---

## Logging

### Console Output

Real-time progress and events are displayed in the console:

```
[INFO ] CustomersJsonToCsv | ModuleStarted | Starting conversion
  [CustomersJsonToCsv] Converting | Files: 1/1 | Progress: 100.0%

===============================================================
Axbus Conversion Summary
===============================================================
Total modules  : 2
Successful     : 2
Failed         : 0
Skipped        : 1
Total files    : 2
Total rows     : 150
Error rows     : 0
Duration       : 2.45s
===============================================================
```

### File Logging

Application logs are written to `logs/axbus-YYYYMMDD.log`:

- **Rolling interval:** Daily
- **Retention:** 10 files
- **Max size:** 5 MB per file

Configure in `appsettings.json`:

```json
{
  "Serilog": {
    "WriteTo": [
      {
        "Name": "File",
        "Args": {
          "path": "logs/axbus-.log",
          "rollingInterval": "Day",
          "retainedFileCountLimit": 10
        }
      }
    ]
  }
}
```

---

## Architecture

### Program Flow

```
Program.cs
  └─> AppBootstrapper.BuildHost()
       ├─> Configure Serilog
       ├─> Load appsettings.json
       ├─> Register Axbus Framework Services
       │    ├─> AddAxbusApplication()
       │    └─> AddAxbusInfrastructure()
       ├─> Register Plugins
       │    ├─> JsonReaderPlugin
       │    ├─> CsvWriterPlugin
       │    └─> ExcelWriterPlugin
       └─> AddHostedService<ConversionHostedService>()
            └─> ConversionHostedService.ExecuteAsync()
                 ├─> Subscribe to IEventPublisher
                 ├─> Create Progress<ConversionProgress>
                 └─> Call IConversionRunner.RunAsync()
```

### Dependency Injection

All services are registered in `AppBootstrapper.cs`:

```csharp
// Framework layers
services.AddAxbusApplication(configuration);
services.AddAxbusInfrastructure(configuration);

// Plugins (manual registration - framework controls lifecycle)
services.AddSingleton<IPlugin, JsonReaderPlugin>();
services.AddSingleton<IPlugin, CsvWriterPlugin>();
services.AddSingleton<IPlugin, ExcelWriterPlugin>();

// Hosted service that runs conversions
services.AddHostedService<ConversionHostedService>();
```

---

## Troubleshooting

### Issue: "Input path does not exist"

**Solution:** Ensure the `Source.Path` in `appsettings.json` is correct:
- Use relative paths: `".\\SampleData"`
- Or absolute paths: `"C:\\MyData\\Input"`

### Issue: "No files found matching pattern"

**Solution:** Check the `FilePattern` matches your files:
- All JSON files: `"*.json"`
- Specific file: `"customers.json"`

### Issue: "Permission denied writing to output folder"

**Solution:** Ensure the output folder is writable, or run with elevated permissions.

### Issue: "Plugin not found"

**Solution:** Verify all plugin projects are referenced in `Axbus.ConsoleApp.csproj` and built successfully.

---

## Advanced Usage

### Running with Custom Configuration

```bash
dotnet run --configuration Production
```

Uses `appsettings.Production.json` overrides.

### Using Environment Variables

Override settings via environment variables:

```bash
export Axbus__RunInParallel=true
dotnet run
```

### Command-Line Arguments

Pass configuration values:

```bash
dotnet run --RunInParallel=true
```

---

## Output Examples

### CSV Output (customers.csv)

```csv
customerId,name,contact.email,contact.phone,address.street,address.city,orders.0.orderId,orders.0.amount
1001,Acme Corporation,info@acme.com,+1-555-0100,123 Business Ave,New York,ORD-2024-001,1250.50
1001,Acme Corporation,info@acme.com,+1-555-0100,123 Business Ave,New York,ORD-2024-002,3400.75
1002,TechStart Inc,contact@techstart.io,+1-555-0200,456 Innovation Dr,San Francisco,ORD-2024-003,5600.25
```

### Excel Output

- **Sheet Name:** Data (default)
- **Headers:** Auto-generated from JSON schema
- **Formatting:** Basic table format with header row
- **Arrays:** Exploded into multiple rows (up to MaxExplosionDepth)

---

## Performance Tips

1. **Enable parallel processing** for multiple modules:
   ```json
   "RunInParallel": true
   ```

2. **Use FirstFile schema strategy** for faster startup:
   ```json
   "SchemaStrategy": "FirstFile"
   ```

3. **Skip error rows** instead of writing to error file:
   ```json
   "RowErrorStrategy": "Skip"
   ```

4. **Reduce MaxExplosionDepth** for deeply nested data:
   ```json
   "MaxExplosionDepth": 2
   ```

---

## Contributing

To extend the ConsoleApp:

1. Add new plugins by referencing them in `Axbus.ConsoleApp.csproj`
2. Register plugins in `AppBootstrapper.cs`
3. Configure new modules in `appsettings.json`
4. Add sample data files to `SampleData` folder

---

## Related Documentation

- [Axbus Framework Documentation](../../README.md)
- [Plugin Development Guide](../../docs/plugin-development.md)
- [Configuration Reference](../../docs/configuration.md)

---

## License

Copyright © 2026 Axel Johnson International. All rights reserved.
