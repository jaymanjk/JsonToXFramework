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

---

## [1.0.0] — TBD

Initial stable release.