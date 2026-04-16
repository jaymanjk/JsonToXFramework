<!-- Copyright (c) 2026 Axel Johnson International. All rights reserved. -->

# Changelog

All notable changes to the Axbus Framework will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Initial solution structure for Axbus framework
- `Axbus.Core` — Pure abstractions, models, enums, exceptions
- `Axbus.Application` — Pipeline engine, plugin system, orchestration
- `Axbus.Infrastructure` — Generic file system connectors, Serilog
- `Axbus.Plugin.Reader.Json` — JSON reader, parser, transformer plugin
- `Axbus.Plugin.Writer.Csv` — CSV schema builder and writer plugin
- `Axbus.Plugin.Writer.Excel` — Excel schema builder and writer plugin
- `Axbus.ConsoleApp` — Console client with DI bootstrapper
- `Axbus.WinFormsApp` — WinForms client with DI bootstrapper
- Plugin isolation via `AssemblyLoadContext`
- Middleware pipeline (Logging, Timing, Retry, ErrorHandling)
- `IProgress<ConversionProgress>` for UI progress reporting
- `IObservable<ConversionEvent>` for reactive event streaming
- `CancellationToken` support throughout
- Parallel execution with `SemaphoreSlim` throttling
- Row-level error strategies (`SkipRow`, `WriteToErrorFile` etc)
- GitHub Copilot master instruction file
- `PluginRegistrationService` — `IHostedService` that reads each plugin's
  `*.manifest.json` at startup and populates `IPluginRegistry` before the first
  pipeline is created; registered automatically by `AddAxbusApplication()`
- `CompositePlugin` — internal `IPlugin` wrapper that combines a dedicated reader
  plugin (Read/Parse/Transform stages) with a dedicated writer plugin (Write stage),
  enabling the separated `JsonReaderPlugin` + `CsvWriterPlugin` architecture to work
  with the existing single-plugin `ConversionPipeline` model
- `ISourceConnector.GetSourcePathsAsync()` — new interface method that enumerates
  resolved file paths without opening them, allowing `ConversionRunner` to dispatch
  one pipeline execution per source file while staying file-system agnostic
- `<Content>` entries added to all three plugin `.csproj` files so each
  `*.manifest.json` is copied to the build output directory (`PreserveNewest`)

### Fixed
- **"No plugin registered for format pair 'json:csv'"** — `IPluginRegistry` was never
  populated at runtime. `PluginRegistrationService` now bridges DI-registered `IPlugin`
  singletons into the registry by reading their manifest files on startup.
  `PipelineFactory.Create()` now resolves reader and writer plugins separately and
  wraps them in a `CompositePlugin`.
- **"Access denied reading JSON file: .\\SampleData"** — `ConversionRunner` was passing
  the source folder path directly to `ConversionPipeline.ExecuteAsync()`, and
  `JsonSourceReader` was then trying to open the directory as a `FileStream`. Fixed by:
  (1) `ConversionRunner` now calls `connector.GetSourcePathsAsync()` to enumerate actual
  file paths and loops the pipeline once per file; (2) `ConversionPipeline.ExecuteAsync()`
  now builds a per-file `SourceOptions` (with `ReadMode = "SingleFile"` and
  `Path = specificFilePath`) before calling the reader.
- **Incorrect `ReadMode` documentation** — `QUICKSTART.md` and `README.md` incorrectly
  listed `"FirstFile"` as a valid `ReadMode` value; corrected to `"SingleFile"`.

---

## [1.0.0] — TBD

Initial stable release.
