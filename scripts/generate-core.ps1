# ==============================================================================
# generate-core.ps1
# Axbus Framework - Axbus.Core Layer Code Generation Script
# Copyright (c) 2026 Axel Johnson International. All rights reserved.
#
# USAGE:
#   PowerShell -ExecutionPolicy Bypass -File .\scripts\generate-core.ps1
#
# WHAT THIS GENERATES:
#   All source files for the Axbus.Core class library project.
#   Run from the repository root (same folder as Axbus.slnx).
#   Axbus.Core has ZERO NuGet dependencies by design.
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptVersion = "1.0.0"
$CompanyName   = "Axel Johnson International"
$CopyrightYear = "2026"
$RootPath      = "src/framework/Axbus.Core"

function Write-Banner {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "  Axbus.Core - Code Generation Script v$ScriptVersion" -ForegroundColor Cyan
    Write-Host "  Copyright (c) $CopyrightYear $CompanyName. All rights reserved." -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Phase {
    param([string]$Message)
    Write-Host ""
    Write-Host "  >> $Message" -ForegroundColor Yellow
    Write-Host "  $("-" * 70)" -ForegroundColor Yellow
}

function Write-Ok   { param([string]$m) Write-Host "      [OK] $m" -ForegroundColor Green }
function Write-Info { param([string]$m) Write-Host "      [..] $m" -ForegroundColor White }

function New-SourceFile {
    param([string]$RelativePath, [string]$Content)
    $fullPath  = Join-Path $RootPath $RelativePath
    $directory = Split-Path $fullPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    [System.IO.File]::WriteAllText(
        [System.IO.Path]::GetFullPath($fullPath),
        $Content,
        [System.Text.UTF8Encoding]::new($false)
    )
    Write-Ok $RelativePath
}

# ==============================================================================
# VALIDATE
# ==============================================================================

if (-not (Test-Path ".git")) {
    Write-Host "  [FAILED] Run from repository root." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $RootPath)) {
    Write-Host "  [FAILED] $RootPath not found. Run setup-axbus.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Banner

# ==============================================================================
# PHASE 1 - ENUMS
# ==============================================================================

Write-Phase "Phase 1 - Enums (10 files)"

New-SourceFile "Enums/OutputFormat.cs" @'
// <copyright file="OutputFormat.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Specifies the output format for conversion results.
/// This is a flags enumeration allowing multiple formats to be combined
/// using the pipe operator, for example <c>OutputFormat.Csv | OutputFormat.Excel</c>.
/// </summary>
[Flags]
public enum OutputFormat
{
    /// <summary>No output format specified.</summary>
    None = 0,

    /// <summary>
    /// Comma-separated values format (.csv).
    /// RFC 4180 compliant output written via <c>Axbus.Plugin.Writer.Csv</c>.
    /// </summary>
    Csv = 1,

    /// <summary>
    /// Microsoft Excel format (.xlsx).
    /// Output written via <c>Axbus.Plugin.Writer.Excel</c> using ClosedXML.
    /// </summary>
    Excel = 2,

    /// <summary>
    /// Plain text format (.txt).
    /// Reserved for future use via a text writer plugin.
    /// </summary>
    Text = 4,
}
'@

New-SourceFile "Enums/OutputMode.cs" @'
// <copyright file="OutputMode.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Specifies how output files are created during a conversion run.
/// Controls whether all converted data is written to a single file
/// or whether one output file is produced per input source file.
/// </summary>
public enum OutputMode
{
    /// <summary>
    /// All rows from all source files are written to a single output file.
    /// The schema is the union of all columns discovered across all files.
    /// This is the default mode.
    /// </summary>
    SingleFile = 0,

    /// <summary>
    /// One output file is produced for each input source file.
    /// Each output file uses the schema discovered from its own source file only.
    /// Output files are named after their corresponding source files.
    /// </summary>
    OnePerFile = 1,
}
'@

New-SourceFile "Enums/ConversionStatus.cs" @'
// <copyright file="ConversionStatus.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Represents the lifecycle status of a conversion module execution.
/// Used in <see cref="Axbus.Core.Models.Notifications.ConversionProgress"/>
/// and <see cref="Axbus.Core.Models.Results.ModuleResult"/> to communicate
/// the current state of a conversion operation.
/// </summary>
public enum ConversionStatus
{
    /// <summary>The conversion module has not yet started.</summary>
    NotStarted = 0,

    /// <summary>
    /// The conversion is in the schema discovery phase.
    /// Source files are being scanned to build the column schema.
    /// </summary>
    Discovering = 1,

    /// <summary>
    /// The conversion pipeline is actively processing rows and writing output.
    /// </summary>
    Converting = 2,

    /// <summary>The conversion module completed successfully.</summary>
    Completed = 3,

    /// <summary>
    /// The conversion module failed with one or more unrecoverable errors.
    /// Check <see cref="Axbus.Core.Models.Results.ModuleResult.Errors"/> for details.
    /// </summary>
    Failed = 4,

    /// <summary>
    /// The conversion module was skipped because
    /// <see cref="Axbus.Core.Models.Configuration.ConversionModule.IsEnabled"/> is false.
    /// </summary>
    Skipped = 5,
}
'@

New-SourceFile "Enums/PipelineStage.cs" @'
// <copyright file="PipelineStage.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Identifies a specific stage within the Axbus conversion pipeline.
/// The pipeline executes stages in the following order:
/// <see cref="Read"/> -> <see cref="Parse"/> -> <see cref="Transform"/>
/// -> <see cref="Write"/>.
/// <see cref="Validate"/> and <see cref="Filter"/> are optional stages
/// that execute between <see cref="Transform"/> and <see cref="Write"/>.
/// </summary>
public enum PipelineStage
{
    /// <summary>
    /// Stage 1: Raw data is read from the source connector as a byte stream.
    /// Implemented by <see cref="Axbus.Core.Abstractions.Pipeline.ISourceReader"/>.
    /// </summary>
    Read = 0,

    /// <summary>
    /// Stage 2: The raw byte stream is parsed into an internal element model.
    /// Implemented by <see cref="Axbus.Core.Abstractions.Pipeline.IFormatParser"/>.
    /// </summary>
    Parse = 1,

    /// <summary>
    /// Stage 3: Parsed elements are flattened and transformed into rows.
    /// Implemented by <see cref="Axbus.Core.Abstractions.Pipeline.IDataTransformer"/>.
    /// </summary>
    Transform = 2,

    /// <summary>
    /// Optional Stage: Rows are validated before writing.
    /// Implemented by <see cref="Axbus.Core.Abstractions.Pipeline.IDataValidator"/>.
    /// </summary>
    Validate = 3,

    /// <summary>
    /// Optional Stage: Rows are filtered based on configured rules.
    /// Implemented by <see cref="Axbus.Core.Abstractions.Pipeline.IDataFilter"/>.
    /// </summary>
    Filter = 4,

    /// <summary>
    /// Stage 4: Transformed rows are written to the target connector.
    /// Implemented by <see cref="Axbus.Core.Abstractions.Pipeline.IOutputWriter"/>.
    /// </summary>
    Write = 5,
}
'@

New-SourceFile "Enums/PluginCapabilities.cs" @'
// <copyright file="PluginCapabilities.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Describes which pipeline stages a plugin supports.
/// This is a flags enumeration allowing a plugin to declare support
/// for multiple stages simultaneously.
/// A plugin that supports all stages can use the convenience value
/// <see cref="Bundled"/>.
/// </summary>
[Flags]
public enum PluginCapabilities
{
    /// <summary>The plugin supports no pipeline stages.</summary>
    None = 0,

    /// <summary>
    /// The plugin implements <see cref="Axbus.Core.Abstractions.Pipeline.ISourceReader"/>
    /// and can read raw data from a source connector.
    /// </summary>
    Reader = 1,

    /// <summary>
    /// The plugin implements <see cref="Axbus.Core.Abstractions.Pipeline.IFormatParser"/>
    /// and can parse a raw stream into an internal element model.
    /// </summary>
    Parser = 2,

    /// <summary>
    /// The plugin implements <see cref="Axbus.Core.Abstractions.Pipeline.IDataTransformer"/>
    /// and can flatten and transform parsed elements into rows.
    /// </summary>
    Transformer = 4,

    /// <summary>
    /// The plugin implements <see cref="Axbus.Core.Abstractions.Pipeline.IOutputWriter"/>
    /// and can write rows to a target connector.
    /// </summary>
    Writer = 8,

    /// <summary>
    /// The plugin implements <see cref="Axbus.Core.Abstractions.Pipeline.IDataValidator"/>
    /// and can validate rows before writing.
    /// </summary>
    Validator = 16,

    /// <summary>
    /// The plugin implements <see cref="Axbus.Core.Abstractions.Pipeline.IDataFilter"/>
    /// and can filter rows based on configured rules.
    /// </summary>
    Filter = 32,

    /// <summary>
    /// Convenience value indicating the plugin supports all core pipeline stages:
    /// <see cref="Reader"/>, <see cref="Parser"/>, <see cref="Transformer"/> and <see cref="Writer"/>.
    /// </summary>
    Bundled = Reader | Parser | Transformer | Writer,
}
'@

New-SourceFile "Enums/SchemaStrategy.cs" @'
// <copyright file="SchemaStrategy.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Specifies how the output column schema is discovered during conversion.
/// The schema determines which columns appear in the output and in what order.
/// </summary>
public enum SchemaStrategy
{
    /// <summary>
    /// All source files are fully scanned before any output is written.
    /// The resulting schema is the union of all columns across all files
    /// in first-seen order. This is the safest strategy but requires
    /// two passes over the data.
    /// </summary>
    FullScan = 0,

    /// <summary>
    /// Schema is accumulated progressively as rows are streamed.
    /// New columns discovered mid-stream are added to the schema.
    /// Memory efficient but may require buffering rows until schema stabilises.
    /// </summary>
    Progressive = 1,

    /// <summary>
    /// Schema is determined from the first source file only.
    /// Fastest strategy but may miss columns present only in later files.
    /// </summary>
    FirstFile = 2,

    /// <summary>
    /// Schema is provided explicitly by the developer via plugin options.
    /// No discovery is performed. Columns not in the schema are ignored.
    /// </summary>
    Configurable = 3,
}
'@

New-SourceFile "Enums/RowErrorStrategy.cs" @'
// <copyright file="RowErrorStrategy.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Specifies how the pipeline handles a row-level processing error.
/// Row errors can occur during transformation, validation or writing.
/// </summary>
public enum RowErrorStrategy
{
    /// <summary>
    /// The entire conversion module is stopped on the first row error.
    /// The module result status is set to <see cref="ConversionStatus.Failed"/>.
    /// </summary>
    StopModule = 0,

    /// <summary>
    /// The failing row is skipped and processing continues with the next row.
    /// Skipped rows are logged as warnings with their row number and error message.
    /// </summary>
    SkipRow = 1,

    /// <summary>
    /// Failing rows are written to a separate error output file alongside the
    /// main output. The error file path is configured in
    /// <see cref="Axbus.Core.Models.Configuration.TargetOptions.ErrorOutputPath"/>.
    /// An additional error column is appended to each error row.
    /// </summary>
    WriteToErrorFile = 2,

    /// <summary>
    /// Field values that fail processing are replaced with the configured
    /// <see cref="Axbus.Core.Models.Configuration.PipelineOptions.NullPlaceholder"/>
    /// and the row is included in the output as normal.
    /// </summary>
    UseDefaultValues = 3,
}
'@

New-SourceFile "Enums/PluginConflictStrategy.cs" @'
// <copyright file="PluginConflictStrategy.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Specifies how the plugin registry resolves conflicts when two or more
/// plugins are registered that can handle the same source and target format.
/// </summary>
public enum PluginConflictStrategy
{
    /// <summary>
    /// The plugin with the highest semantic version number is used.
    /// This is the default and recommended strategy for production environments.
    /// </summary>
    UseLatestVersion = 0,

    /// <summary>
    /// The first plugin registered for a given format combination is used.
    /// Subsequent conflicting registrations are ignored with a warning logged.
    /// </summary>
    UseFirstRegistered = 1,

    /// <summary>
    /// An <see cref="Axbus.Core.Exceptions.AxbusPluginException"/> is thrown
    /// immediately when a conflicting plugin is registered.
    /// Use this strategy to fail fast and force explicit resolution via
    /// <see cref="Axbus.Core.Models.Configuration.ConversionModule.PluginOverride"/>.
    /// </summary>
    ThrowException = 2,

    /// <summary>
    /// Only the plugin explicitly named in
    /// <see cref="Axbus.Core.Models.Configuration.ConversionModule.PluginOverride"/>
    /// is used. All automatic resolution is disabled.
    /// </summary>
    UseExplicitOverride = 3,
}
'@

New-SourceFile "Enums/PluginIsolationMode.cs" @'
// <copyright file="PluginIsolationMode.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Specifies how plugin assemblies are loaded into the host process.
/// Isolation prevents dependency version conflicts between plugins
/// and between plugins and the host application.
/// </summary>
public enum PluginIsolationMode
{
    /// <summary>
    /// Each plugin is loaded into its own
    /// <see cref="System.Runtime.Loader.AssemblyLoadContext"/>.
    /// This prevents DLL version conflicts between plugins and between
    /// plugins and the host. This is the default and recommended mode
    /// for production environments.
    /// </summary>
    Isolated = 0,

    /// <summary>
    /// All plugins are loaded into the default
    /// <see cref="System.Runtime.Loader.AssemblyLoadContext"/>.
    /// Simpler but susceptible to DLL version conflicts.
    /// Use only for debugging or in controlled environments
    /// where all plugins share the same dependency versions.
    /// </summary>
    Shared = 1,
}
'@

New-SourceFile "Enums/ConversionEventType.cs" @'
// <copyright file="ConversionEventType.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Identifies the type of event published to the
/// <see cref="Axbus.Core.Abstractions.Notifications.IEventPublisher"/> observable stream.
/// Consumers can filter the event stream by type to react to specific lifecycle events.
/// </summary>
public enum ConversionEventType
{
    /// <summary>A conversion module has started execution.</summary>
    ModuleStarted = 0,

    /// <summary>A conversion module completed successfully.</summary>
    ModuleCompleted = 1,

    /// <summary>A conversion module failed with an unrecoverable error.</summary>
    ModuleFailed = 2,

    /// <summary>A conversion module was skipped because it is disabled.</summary>
    ModuleSkipped = 3,

    /// <summary>Processing of a single source file has started.</summary>
    FileStarted = 4,

    /// <summary>Processing of a single source file completed successfully.</summary>
    FileCompleted = 5,

    /// <summary>Processing of a single source file failed.</summary>
    FileFailed = 6,

    /// <summary>Schema discovery across source files has started.</summary>
    SchemaDiscoveryStarted = 7,

    /// <summary>Schema discovery completed and the column schema is finalised.</summary>
    SchemaDiscoveryCompleted = 8,

    /// <summary>A single row has been successfully processed and written.</summary>
    RowProcessed = 9,

    /// <summary>A row failed to process and was handled per the configured row error strategy.</summary>
    RowFailed = 10,

    /// <summary>An output file has been written to the target connector.</summary>
    OutputWritten = 11,
}
'@

# ==============================================================================
# PHASE 2 - EXCEPTIONS
# ==============================================================================

Write-Phase "Phase 2 - Exceptions (4 files)"

New-SourceFile "Exceptions/AxbusPipelineException.cs" @'
// <copyright file="AxbusPipelineException.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Exceptions;

using Axbus.Core.Enums;

/// <summary>
/// Represents an error that occurs within the Axbus conversion pipeline.
/// This exception is thrown when a pipeline stage fails in a way that
/// cannot be handled by the configured
/// <see cref="RowErrorStrategy"/>.
/// </summary>
public sealed class AxbusPipelineException : Exception
{
    /// <summary>
    /// Gets the pipeline stage at which the failure occurred.
    /// </summary>
    public PipelineStage Stage { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusPipelineException"/>
    /// with a specified error message.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    public AxbusPipelineException(string message)
        : base(message)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusPipelineException"/>
    /// with a specified error message and a reference to the inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="innerException">The exception that caused this exception.</param>
    public AxbusPipelineException(string message, Exception innerException)
        : base(message, innerException)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusPipelineException"/>
    /// with a specified error message, the pipeline stage, and an optional inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="stage">The pipeline stage at which the failure occurred.</param>
    /// <param name="innerException">The exception that caused this exception, or null.</param>
    public AxbusPipelineException(string message, PipelineStage stage, Exception? innerException = null)
        : base(message, innerException)
    {
        Stage = stage;
    }
}
'@

New-SourceFile "Exceptions/AxbusPluginException.cs" @'
// <copyright file="AxbusPluginException.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Exceptions;

/// <summary>
/// Represents an error that occurs during plugin loading, initialisation,
/// registration or resolution within the Axbus plugin system.
/// </summary>
public sealed class AxbusPluginException : Exception
{
    /// <summary>
    /// Gets the identifier of the plugin that caused the exception, if known.
    /// </summary>
    public string? PluginId { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusPluginException"/>
    /// with a specified error message.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    public AxbusPluginException(string message)
        : base(message)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusPluginException"/>
    /// with a specified error message and a reference to the inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="innerException">The exception that caused this exception.</param>
    public AxbusPluginException(string message, Exception innerException)
        : base(message, innerException)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusPluginException"/>
    /// with a specified error message, the plugin identifier, and an optional inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="pluginId">The identifier of the plugin that caused the exception.</param>
    /// <param name="innerException">The exception that caused this exception, or null.</param>
    public AxbusPluginException(string message, string pluginId, Exception? innerException = null)
        : base(message, innerException)
    {
        PluginId = pluginId;
    }
}
'@

New-SourceFile "Exceptions/AxbusConnectorException.cs" @'
// <copyright file="AxbusConnectorException.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Exceptions;

/// <summary>
/// Represents an error that occurs within an Axbus source or target connector.
/// Connector exceptions are typically caused by file system access failures,
/// network errors, or permission issues when reading from or writing to
/// a data source or target.
/// </summary>
public sealed class AxbusConnectorException : Exception
{
    /// <summary>
    /// Gets the path or URI of the resource that caused the exception, if known.
    /// </summary>
    public string? ResourcePath { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusConnectorException"/>
    /// with a specified error message.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    public AxbusConnectorException(string message)
        : base(message)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusConnectorException"/>
    /// with a specified error message and a reference to the inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="innerException">The exception that caused this exception.</param>
    public AxbusConnectorException(string message, Exception innerException)
        : base(message, innerException)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusConnectorException"/>
    /// with a specified error message, the resource path, and an optional inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="resourcePath">The path or URI of the resource that caused the exception.</param>
    /// <param name="innerException">The exception that caused this exception, or null.</param>
    public AxbusConnectorException(string message, string resourcePath, Exception? innerException = null)
        : base(message, innerException)
    {
        ResourcePath = resourcePath;
    }
}
'@

New-SourceFile "Exceptions/AxbusConfigurationException.cs" @'
// <copyright file="AxbusConfigurationException.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Exceptions;

/// <summary>
/// Represents an error caused by invalid or missing configuration within
/// the Axbus framework. This exception is thrown during application startup
/// or module initialisation when required configuration values are absent,
/// malformed or mutually inconsistent.
/// </summary>
public sealed class AxbusConfigurationException : Exception
{
    /// <summary>
    /// Gets the name of the configuration key or section that caused the exception, if known.
    /// </summary>
    public string? ConfigurationKey { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusConfigurationException"/>
    /// with a specified error message.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    public AxbusConfigurationException(string message)
        : base(message)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusConfigurationException"/>
    /// with a specified error message and a reference to the inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="innerException">The exception that caused this exception.</param>
    public AxbusConfigurationException(string message, Exception innerException)
        : base(message, innerException)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusConfigurationException"/>
    /// with a specified error message, the configuration key, and an optional inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="configurationKey">The name of the configuration key or section.</param>
    /// <param name="innerException">The exception that caused this exception, or null.</param>
    public AxbusConfigurationException(string message, string configurationKey, Exception? innerException = null)
        : base(message, innerException)
    {
        ConfigurationKey = configurationKey;
    }
}
'@

# ==============================================================================
# PHASE 3 - MODELS - CONFIGURATION
# ==============================================================================

Write-Phase "Phase 3 - Models/Configuration (7 files)"

New-SourceFile "Models/Configuration/ParallelSettings.cs" @'
// <copyright file="ParallelSettings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

/// <summary>
/// Controls the degree of parallelism used when executing multiple
/// conversion modules concurrently. These settings act as throttles
/// to prevent resource exhaustion on production servers.
/// Configured under <c>ParallelSettings</c> in <c>appsettings.json</c>.
/// </summary>
public sealed class ParallelSettings
{
    /// <summary>
    /// Gets or sets the maximum number of conversion modules
    /// that may execute concurrently.
    /// Defaults to <see cref="Environment.ProcessorCount"/>.
    /// </summary>
    public int MaxDegreeOfParallelism { get; set; } = Environment.ProcessorCount;

    /// <summary>
    /// Gets or sets the maximum number of source files that may be
    /// read concurrently within a single conversion module.
    /// Defaults to <c>4</c>.
    /// </summary>
    public int MaxConcurrentFileReads { get; set; } = 4;

    /// <summary>
    /// Gets or sets the maximum number of output files that may be
    /// written concurrently within a single conversion module.
    /// Defaults to <c>2</c>.
    /// </summary>
    public int MaxConcurrentFileWrites { get; set; } = 2;
}
'@

New-SourceFile "Models/Configuration/SourceOptions.cs" @'
// <copyright file="SourceOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

/// <summary>
/// Configures the source from which input data is read for a conversion module.
/// This is a pure infrastructure concern and is independent of the source file format.
/// Configured under <c>Source</c> within a <see cref="ConversionModule"/> entry
/// in <c>appsettings.json</c>.
/// </summary>
public sealed class SourceOptions
{
    /// <summary>
    /// Gets or sets the connector type used to access the source.
    /// Built-in values: <c>FileSystem</c>.
    /// Future values: <c>AzureBlob</c>, <c>S3</c>, <c>Http</c>, <c>FTP</c>.
    /// </summary>
    public string Type { get; set; } = "FileSystem";

    /// <summary>
    /// Gets or sets the path to the source data.
    /// For <c>FileSystem</c> type this is the folder path containing source files.
    /// </summary>
    public string Path { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the file pattern used to filter source files.
    /// Supports wildcards, for example <c>*.json</c> or <c>orders_*.json</c>.
    /// Defaults to <c>*.*</c> (all files).
    /// </summary>
    public string FilePattern { get; set; } = "*.*";

    /// <summary>
    /// Gets or sets the read mode controlling how files are selected.
    /// Supported values: <c>AllFiles</c>, <c>SingleFile</c>.
    /// Defaults to <c>AllFiles</c>.
    /// </summary>
    public string ReadMode { get; set; } = "AllFiles";
}
'@

New-SourceFile "Models/Configuration/TargetOptions.cs" @'
// <copyright file="TargetOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

using Axbus.Core.Enums;

/// <summary>
/// Configures the target to which converted output is written for a conversion module.
/// This is a pure infrastructure concern and is independent of the output file format.
/// Configured under <c>Target</c> within a <see cref="ConversionModule"/> entry
/// in <c>appsettings.json</c>.
/// </summary>
public sealed class TargetOptions
{
    /// <summary>
    /// Gets or sets the connector type used to access the target.
    /// Built-in values: <c>FileSystem</c>.
    /// Future values: <c>AzureBlob</c>, <c>S3</c>, <c>Http</c>, <c>FTP</c>.
    /// </summary>
    public string Type { get; set; } = "FileSystem";

    /// <summary>
    /// Gets or sets the path to which output files are written.
    /// For <c>FileSystem</c> type this is the target folder path.
    /// </summary>
    public string Path { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets how output files are created.
    /// <see cref="OutputMode.SingleFile"/> merges all rows into one file.
    /// <see cref="OutputMode.OnePerFile"/> creates one output file per source file.
    /// </summary>
    public OutputMode OutputMode { get; set; } = OutputMode.SingleFile;

    /// <summary>
    /// Gets or sets the output format or combination of formats.
    /// Use the pipe operator to specify multiple formats,
    /// for example <c>OutputFormat.Csv | OutputFormat.Excel</c>.
    /// </summary>
    public OutputFormat OutputFormat { get; set; } = OutputFormat.Csv;

    /// <summary>
    /// Gets or sets the path to which error rows are written when
    /// <see cref="Axbus.Core.Models.Configuration.PipelineOptions.RowErrorStrategy"/>
    /// is set to <see cref="RowErrorStrategy.WriteToErrorFile"/>.
    /// Defaults to the same folder as <see cref="Path"/> when null or empty.
    /// </summary>
    public string? ErrorOutputPath { get; set; }

    /// <summary>
    /// Gets or sets the suffix appended to the output file name to produce
    /// the error file name. For example a suffix of <c>.errors</c> produces
    /// <c>result.errors.csv</c> alongside <c>result.csv</c>.
    /// Defaults to <c>.errors</c>.
    /// </summary>
    public string ErrorFileSuffix { get; set; } = ".errors";
}
'@

New-SourceFile "Models/Configuration/PipelineOptions.cs" @'
// <copyright file="PipelineOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

using Axbus.Core.Enums;

/// <summary>
/// Controls the behaviour of the conversion pipeline for a specific module.
/// These settings govern schema discovery, error handling and data transformation
/// behaviour. Configured under <c>Pipeline</c> within a <see cref="ConversionModule"/>
/// entry in <c>appsettings.json</c>.
/// </summary>
public sealed class PipelineOptions
{
    /// <summary>
    /// Gets or sets the strategy used to discover the output column schema.
    /// Defaults to <see cref="SchemaStrategy.FullScan"/> which scans all source
    /// files before writing any output.
    /// </summary>
    public SchemaStrategy SchemaStrategy { get; set; } = SchemaStrategy.FullScan;

    /// <summary>
    /// Gets or sets the strategy used when a row-level processing error occurs.
    /// Defaults to <see cref="RowErrorStrategy.WriteToErrorFile"/>.
    /// </summary>
    public RowErrorStrategy RowErrorStrategy { get; set; } = RowErrorStrategy.WriteToErrorFile;

    /// <summary>
    /// Gets or sets the maximum depth to which nested arrays are exploded
    /// into multiple rows. Arrays nested beyond this depth are serialised
    /// as a JSON string in a single column instead.
    /// Defaults to <c>3</c>.
    /// </summary>
    public int MaxExplosionDepth { get; set; } = 3;

    /// <summary>
    /// Gets or sets the value written to output columns when the source
    /// row does not contain a value for that column.
    /// Defaults to an empty string.
    /// </summary>
    public string NullPlaceholder { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the key used to locate the root array within the source data.
    /// When <c>null</c> the framework auto-detects the root array.
    /// When set to <c>root</c> the entire root object is treated as a single record.
    /// When set to any other value the framework drills into that key to find the array.
    /// </summary>
    public string? RootArrayKey { get; set; }
}
'@

New-SourceFile "Models/Configuration/PluginSettings.cs" @'
// <copyright file="PluginSettings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

using Axbus.Core.Enums;

/// <summary>
/// Configures how plugins are discovered, loaded and registered at application startup.
/// Configured under <c>PluginSettings</c> in <c>appsettings.json</c>.
/// </summary>
public sealed class PluginSettings
{
    /// <summary>
    /// Gets or sets the path to the folder containing plugin assemblies.
    /// When <c>null</c> or empty the framework looks for a <c>plugins</c>
    /// folder relative to the application executable.
    /// </summary>
    public string? PluginsFolder { get; set; }

    /// <summary>
    /// Gets or sets a value indicating whether sub-folders of
    /// <see cref="PluginsFolder"/> are also scanned for plugin assemblies.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool ScanSubFolders { get; set; } = true;

    /// <summary>
    /// Gets or sets a value indicating whether each plugin is loaded
    /// into its own <see cref="System.Runtime.Loader.AssemblyLoadContext"/>.
    /// Set to <c>false</c> only for debugging in controlled environments.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool IsolatePlugins { get; set; } = true;

    /// <summary>
    /// Gets or sets the strategy used when two or more registered plugins
    /// can handle the same source and target format combination.
    /// Defaults to <see cref="PluginConflictStrategy.UseLatestVersion"/>.
    /// </summary>
    public PluginConflictStrategy ConflictStrategy { get; set; } = PluginConflictStrategy.UseLatestVersion;

    /// <summary>
    /// Gets or sets the list of plugin assembly names to load.
    /// The framework scans these assemblies for types implementing
    /// <see cref="Axbus.Core.Abstractions.Plugin.IPlugin"/>.
    /// Example: <c>[ "Axbus.Plugin.Reader.Json", "Axbus.Plugin.Writer.Csv" ]</c>.
    /// </summary>
    public List<string> Plugins { get; set; } = new();
}
'@

New-SourceFile "Models/Configuration/ConversionModule.cs" @'
// <copyright file="ConversionModule.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

using System.Text.Json;

/// <summary>
/// Defines a single named conversion job within the Axbus framework.
/// Each module specifies its own source, target, pipeline behaviour and plugin options.
/// Modules are listed under <c>ConversionModules</c> in <c>appsettings.json</c>.
/// </summary>
public sealed class ConversionModule
{
    /// <summary>
    /// Gets or sets the unique name identifying this conversion module.
    /// Used in log output and progress notifications.
    /// Example: <c>ACT001-SalesOrder</c>.
    /// </summary>
    public string ConversionName { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets a human-readable description of the conversion module.
    /// Displayed in the WinForms UI and included in log output.
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets a value indicating whether this module is active.
    /// Disabled modules are skipped with a <see cref="ConversionStatus.Skipped"/> status.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool IsEnabled { get; set; } = true;

    /// <summary>
    /// Gets or sets the order in which this module executes relative to
    /// other modules in the same run. Lower numbers execute first.
    /// Defaults to <c>0</c>.
    /// </summary>
    public int ExecutionOrder { get; set; } = 0;

    /// <summary>
    /// Gets or sets a value indicating whether a failure in this module
    /// should allow remaining modules to continue executing.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool ContinueOnError { get; set; } = true;

    /// <summary>
    /// Gets or sets a value indicating whether this module may run concurrently
    /// with other modules that also have <see cref="RunInParallel"/> set to <c>true</c>.
    /// This flag is overridden by the root-level <c>RunInParallel</c> setting
    /// in <see cref="AxbusRootSettings"/>.
    /// Defaults to <c>false</c>.
    /// </summary>
    public bool RunInParallel { get; set; } = false;

    /// <summary>
    /// Gets or sets the format identifier of the source data.
    /// Example values: <c>json</c>, <c>xml</c>, <c>csv</c>.
    /// Used to resolve the appropriate reader plugin.
    /// </summary>
    public string SourceFormat { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the format identifier of the conversion target.
    /// Example values: <c>csv</c>, <c>excel</c>, <c>text</c>.
    /// Used to resolve the appropriate writer plugin.
    /// </summary>
    public string TargetFormat { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the explicit plugin identifier to use for this module.
    /// When <c>null</c> the framework automatically resolves the best plugin
    /// based on <see cref="SourceFormat"/> and <see cref="TargetFormat"/>.
    /// </summary>
    public string? PluginOverride { get; set; }

    /// <summary>
    /// Gets or sets the source configuration for this module.
    /// </summary>
    public SourceOptions Source { get; set; } = new();

    /// <summary>
    /// Gets or sets the target configuration for this module.
    /// </summary>
    public TargetOptions Target { get; set; } = new();

    /// <summary>
    /// Gets or sets the pipeline behaviour configuration for this module.
    /// </summary>
    public PipelineOptions Pipeline { get; set; } = new();

    /// <summary>
    /// Gets or sets plugin-specific options as a raw JSON element dictionary.
    /// The framework deserialises these into the plugin's strongly-typed options
    /// class at runtime using <see cref="Axbus.Core.Abstractions.Factories.IPluginOptionsFactory"/>.
    /// </summary>
    public Dictionary<string, JsonElement> PluginOptions { get; set; } = new();
}
'@

New-SourceFile "Models/Configuration/AxbusRootSettings.cs" @'
// <copyright file="AxbusRootSettings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

/// <summary>
/// Root configuration model for the Axbus framework.
/// Bind this to the root section of <c>appsettings.json</c> using
/// <c>services.Configure&lt;AxbusRootSettings&gt;(configuration)</c>.
/// </summary>
public sealed class AxbusRootSettings
{
    /// <summary>
    /// Gets or sets the master parallel execution switch.
    /// When <c>false</c> all modules run sequentially regardless of their
    /// individual <see cref="ConversionModule.RunInParallel"/> settings.
    /// This acts as a global safety switch for production environments.
    /// When <c>null</c> each module decides independently.
    /// Defaults to <c>false</c>.
    /// </summary>
    public bool? RunInParallel { get; set; } = false;

    /// <summary>
    /// Gets or sets the parallelism throttle settings applied when
    /// modules run concurrently.
    /// </summary>
    public ParallelSettings ParallelSettings { get; set; } = new();

    /// <summary>
    /// Gets or sets the plugin discovery and loading configuration.
    /// </summary>
    public PluginSettings PluginSettings { get; set; } = new();

    /// <summary>
    /// Gets or sets the list of conversion modules to execute.
    /// Modules are executed in ascending <see cref="ConversionModule.ExecutionOrder"/> order
    /// unless parallel execution is enabled.
    /// </summary>
    public List<ConversionModule> ConversionModules { get; set; } = new();
}
'@

# ==============================================================================
# PHASE 4 - MODELS - PIPELINE
# ==============================================================================

Write-Phase "Phase 4 - Models/Pipeline (9 files)"

New-SourceFile "Models/Pipeline/FlattenedRow.cs" @'
// <copyright file="FlattenedRow.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

/// <summary>
/// Represents a single flattened row produced by the data transformer stage.
/// Each entry maps a column name (which may use dot-notation for nested fields,
/// for example <c>customer.address.city</c>) to its string value.
/// Missing columns produce no entry; the writer fills gaps using the configured
/// <see cref="Axbus.Core.Models.Configuration.PipelineOptions.NullPlaceholder"/>.
/// </summary>
public sealed class FlattenedRow
{
    /// <summary>
    /// Gets the dictionary of column-name-to-value pairs for this row.
    /// Keys use dot-notation for nested fields.
    /// Values are always strings; numeric and boolean values are converted
    /// to their invariant string representations.
    /// </summary>
    public Dictionary<string, string> Values { get; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>
    /// Gets or sets the one-based row number within the source file.
    /// Used in error reporting and logging.
    /// </summary>
    public int RowNumber { get; set; }

    /// <summary>
    /// Gets or sets the path of the source file from which this row originated.
    /// </summary>
    public string SourceFilePath { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets a value indicating whether this row resulted from
    /// an array explosion. When <c>true</c> the row shares its
    /// <see cref="RowNumber"/> with sibling rows from the same parent record.
    /// </summary>
    public bool IsExploded { get; set; }

    /// <summary>
    /// Gets or sets the zero-based index of this row within its explosion group.
    /// Only meaningful when <see cref="IsExploded"/> is <c>true</c>.
    /// </summary>
    public int ExplosionIndex { get; set; }
}
'@

New-SourceFile "Models/Pipeline/ErrorRow.cs" @'
// <copyright file="ErrorRow.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

/// <summary>
/// Represents a row that failed to process during the conversion pipeline.
/// When <see cref="Axbus.Core.Enums.RowErrorStrategy.WriteToErrorFile"/> is configured,
/// error rows are collected and written to a separate error output file with an
/// additional <c>_AxbusError</c> column appended.
/// </summary>
public sealed class ErrorRow
{
    /// <summary>
    /// Gets or sets the original flattened row that failed to process.
    /// May be <c>null</c> if the failure occurred before flattening was complete.
    /// </summary>
    public FlattenedRow? OriginalRow { get; set; }

    /// <summary>
    /// Gets or sets a human-readable description of the error that occurred.
    /// </summary>
    public string ErrorMessage { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the path of the source file from which the failing row originated.
    /// </summary>
    public string SourceFilePath { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the one-based row number within the source file at which the error occurred.
    /// </summary>
    public int RowNumber { get; set; }

    /// <summary>
    /// Gets or sets the exception that caused the row to fail, if available.
    /// </summary>
    public Exception? Exception { get; set; }
}
'@

New-SourceFile "Models/Pipeline/SourceData.cs" @'
// <copyright file="SourceData.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

/// <summary>
/// Immutable record representing the output of pipeline Stage 1 (Read).
/// Contains the raw byte stream from the source connector together with
/// metadata about the source. Passed as input to Stage 2 (Parse).
/// </summary>
/// <param name="RawData">
/// The raw byte stream read from the source connector.
/// The caller is responsible for disposing this stream.
/// </param>
/// <param name="SourcePath">The path or URI of the source resource.</param>
/// <param name="Format">The format identifier of the source data, for example <c>json</c>.</param>
/// <param name="ContentLength">The content length in bytes, or <c>-1</c> if unknown.</param>
public sealed record SourceData(
    Stream RawData,
    string SourcePath,
    string Format,
    long ContentLength = -1);
'@

New-SourceFile "Models/Pipeline/ParsedData.cs" @'
// <copyright file="ParsedData.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

using System.Text.Json;

/// <summary>
/// Immutable record representing the output of pipeline Stage 2 (Parse).
/// Contains a streaming sequence of parsed elements together with metadata
/// about the source format. Passed as input to Stage 3 (Transform).
/// Elements are produced lazily and should be consumed only once.
/// </summary>
/// <param name="Elements">
/// An asynchronous stream of parsed <see cref="JsonElement"/> values.
/// Each element represents one top-level item from the source data.
/// </param>
/// <param name="SourcePath">The path or URI of the source resource.</param>
/// <param name="Format">The format identifier of the parsed data, for example <c>json</c>.</param>
/// <param name="EstimatedElementCount">
/// An estimated count of elements in the stream, or <c>-1</c> if unknown.
/// Used for progress reporting only and may not be exact.
/// </param>
public sealed record ParsedData(
    IAsyncEnumerable<JsonElement> Elements,
    string SourcePath,
    string Format,
    int EstimatedElementCount = -1);
'@

New-SourceFile "Models/Pipeline/TransformedData.cs" @'
// <copyright file="TransformedData.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

/// <summary>
/// Immutable record representing the output of pipeline Stage 3 (Transform).
/// Contains a streaming sequence of flattened rows ready for optional
/// validation and filtering before being passed to Stage 4 (Write).
/// Rows are produced lazily and should be consumed only once.
/// </summary>
/// <param name="Rows">
/// An asynchronous stream of <see cref="FlattenedRow"/> values.
/// Each row represents one record ready for output.
/// </param>
/// <param name="SourcePath">The path or URI of the source resource.</param>
/// <param name="EstimatedRowCount">
/// An estimated count of rows in the stream, or <c>-1</c> if unknown.
/// Used for progress reporting only and may not be exact.
/// </param>
public sealed record TransformedData(
    IAsyncEnumerable<FlattenedRow> Rows,
    string SourcePath,
    int EstimatedRowCount = -1);
'@

New-SourceFile "Models/Pipeline/WriteResult.cs" @'
// <copyright file="WriteResult.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

using Axbus.Core.Enums;

/// <summary>
/// Immutable record representing the output of pipeline Stage 4 (Write).
/// Contains statistics about the write operation including row counts,
/// output paths and duration. Returned to the conversion runner after
/// the writer completes.
/// </summary>
/// <param name="RowsWritten">The number of rows successfully written to the output.</param>
/// <param name="ErrorRowsWritten">The number of rows written to the error output file.</param>
/// <param name="OutputPath">The full path to the primary output file that was written.</param>
/// <param name="ErrorFilePath">The full path to the error output file, or <c>null</c> if no error file was written.</param>
/// <param name="Format">The output format that was written.</param>
/// <param name="Duration">The elapsed time taken to complete the write operation.</param>
public sealed record WriteResult(
    int RowsWritten,
    int ErrorRowsWritten,
    string OutputPath,
    string? ErrorFilePath,
    OutputFormat Format,
    TimeSpan Duration);
'@

New-SourceFile "Models/Pipeline/ValidationResult.cs" @'
// <copyright file="ValidationResult.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

/// <summary>
/// Represents the result of validating a single <see cref="FlattenedRow"/>
/// in the optional validation pipeline stage.
/// Returned by implementations of
/// <see cref="Axbus.Core.Abstractions.Pipeline.IDataValidator"/>.
/// </summary>
public sealed class ValidationResult
{
    /// <summary>
    /// Gets or sets a value indicating whether the row passed validation.
    /// When <c>false</c> the row is handled according to the configured
    /// <see cref="Axbus.Core.Enums.RowErrorStrategy"/>.
    /// </summary>
    public bool IsValid { get; set; } = true;

    /// <summary>
    /// Gets the list of validation error messages for this row.
    /// Empty when <see cref="IsValid"/> is <c>true</c>.
    /// </summary>
    public List<string> Errors { get; } = new();

    /// <summary>
    /// Gets a pre-built instance representing a successful validation result.
    /// </summary>
    public static ValidationResult Success { get; } = new() { IsValid = true };

    /// <summary>
    /// Creates a failed <see cref="ValidationResult"/> with one or more error messages.
    /// </summary>
    /// <param name="errors">One or more validation error messages describing why the row failed.</param>
    /// <returns>A new <see cref="ValidationResult"/> with <see cref="IsValid"/> set to <c>false</c>.</returns>
    public static ValidationResult Fail(params string[] errors)
    {
        var result = new ValidationResult { IsValid = false };
        result.Errors.AddRange(errors);
        return result;
    }
}
'@

New-SourceFile "Models/Pipeline/PipelineStageResult.cs" @'
// <copyright file="PipelineStageResult.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

using Axbus.Core.Enums;

/// <summary>
/// Wraps the result of a single pipeline stage execution.
/// Used by <see cref="Axbus.Core.Abstractions.Middleware.IPipelineMiddleware"/>
/// implementations to carry success/failure state, the stage output object,
/// and timing information through the middleware chain.
/// </summary>
public sealed class PipelineStageResult
{
    /// <summary>
    /// Gets or sets a value indicating whether the stage completed successfully.
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// Gets or sets the output object produced by the stage.
    /// The actual type depends on the stage:
    /// <see cref="PipelineStage.Read"/> produces <see cref="SourceData"/>,
    /// <see cref="PipelineStage.Parse"/> produces <see cref="ParsedData"/>, and so on.
    /// </summary>
    public object? Output { get; set; }

    /// <summary>
    /// Gets or sets the exception that caused the stage to fail, if applicable.
    /// <c>null</c> when <see cref="Success"/> is <c>true</c>.
    /// </summary>
    public Exception? Exception { get; set; }

    /// <summary>
    /// Gets or sets the elapsed time taken to execute this stage.
    /// </summary>
    public TimeSpan Duration { get; set; }

    /// <summary>
    /// Gets or sets the pipeline stage that produced this result.
    /// </summary>
    public PipelineStage Stage { get; set; }
}
'@

# ==============================================================================
# PHASE 5 - MODELS - PLUGIN
# ==============================================================================

Write-Phase "Phase 5 - Models/Plugin (5 files)"

New-SourceFile "Models/Plugin/PluginFileSet.cs" @'
// <copyright file="PluginFileSet.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Plugin;

/// <summary>
/// Represents a pair of files discovered by the plugin folder scanner:
/// the plugin assembly DLL and its accompanying manifest JSON file.
/// Used by <see cref="Axbus.Core.Abstractions.Plugin.IPluginLoader"/>
/// to load and validate plugins before registering them.
/// </summary>
public sealed class PluginFileSet
{
    /// <summary>
    /// Gets or sets the full path to the plugin assembly file (.dll).
    /// </summary>
    public string AssemblyPath { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the full path to the plugin manifest file (.manifest.json).
    /// </summary>
    public string ManifestPath { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the path to the folder containing both the assembly
    /// and the manifest file.
    /// </summary>
    public string PluginFolder { get; set; } = string.Empty;
}
'@

New-SourceFile "Models/Plugin/PluginManifest.cs" @'
// <copyright file="PluginManifest.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Plugin;

/// <summary>
/// Represents the contents of a plugin manifest file (<c>*.manifest.json</c>).
/// Each plugin assembly must be accompanied by a manifest file that declares
/// its identity, supported formats and framework version compatibility.
/// The manifest is read by <see cref="Axbus.Core.Abstractions.Plugin.IPluginManifestReader"/>
/// before the assembly is loaded.
/// </summary>
public sealed class PluginManifest
{
    /// <summary>Gets or sets the display name of the plugin.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the unique reverse-domain identifier of the plugin.
    /// Example: <c>axbus.plugin.reader.json</c>.
    /// </summary>
    public string PluginId { get; set; } = string.Empty;

    /// <summary>Gets or sets the semantic version of the plugin assembly.</summary>
    public string Version { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the minimum Axbus framework version this plugin is compatible with.
    /// </summary>
    public string FrameworkVersion { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the source format this plugin can read.
    /// <c>null</c> for writer-only plugins.
    /// </summary>
    public string? SourceFormat { get; set; }

    /// <summary>
    /// Gets or sets the target format this plugin can write.
    /// <c>null</c> for reader-only plugins.
    /// </summary>
    public string? TargetFormat { get; set; }

    /// <summary>
    /// Gets or sets the pipeline stages this plugin supports.
    /// Example: <c>[ "Read", "Parse", "Transform" ]</c>.
    /// </summary>
    public List<string> SupportedStages { get; set; } = new();

    /// <summary>
    /// Gets or sets a value indicating whether this plugin implements
    /// all core pipeline stages (Reader + Parser + Transformer + Writer).
    /// </summary>
    public bool IsBundled { get; set; }

    /// <summary>Gets or sets the name of the plugin author or organisation.</summary>
    public string Author { get; set; } = string.Empty;

    /// <summary>Gets or sets a human-readable description of the plugin.</summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the names of NuGet packages this plugin depends on.
    /// Used for documentation purposes only; dependency resolution is handled by NuGet.
    /// </summary>
    public List<string> Dependencies { get; set; } = new();
}
'@

New-SourceFile "Models/Plugin/PluginDescriptor.cs" @'
// <copyright file="PluginDescriptor.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Plugin;

using System.Reflection;
using Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Holds runtime information about a loaded plugin.
/// Created by the plugin loader after an assembly has been successfully
/// loaded and an <see cref="IPlugin"/> instance has been created.
/// Stored in the plugin registry for resolution at pipeline build time.
/// </summary>
public sealed class PluginDescriptor
{
    /// <summary>
    /// Gets or sets the <see cref="IPlugin"/> instance created from the loaded assembly.
    /// </summary>
    public IPlugin Instance { get; set; } = null!;

    /// <summary>
    /// Gets or sets the deserialized manifest for this plugin.
    /// </summary>
    public PluginManifest Manifest { get; set; } = null!;

    /// <summary>
    /// Gets or sets the loaded assembly containing the plugin implementation.
    /// </summary>
    public Assembly Assembly { get; set; } = null!;

    /// <summary>
    /// Gets or sets a value indicating whether this plugin was loaded
    /// into an isolated <see cref="System.Runtime.Loader.AssemblyLoadContext"/>.
    /// </summary>
    public bool IsIsolated { get; set; }
}
'@

New-SourceFile "Models/Plugin/PluginCompatibility.cs" @'
// <copyright file="PluginCompatibility.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Plugin;

/// <summary>
/// Represents the result of a plugin framework version compatibility check.
/// Produced by the plugin compatibility checker before a plugin is registered.
/// </summary>
public sealed class PluginCompatibility
{
    /// <summary>
    /// Gets or sets a value indicating whether the plugin is compatible
    /// with the running Axbus framework version.
    /// </summary>
    public bool IsCompatible { get; set; }

    /// <summary>
    /// Gets or sets a human-readable explanation of why the plugin is
    /// incompatible. <c>null</c> when <see cref="IsCompatible"/> is <c>true</c>.
    /// </summary>
    public string? Reason { get; set; }

    /// <summary>Gets a pre-built instance representing a compatible result.</summary>
    public static PluginCompatibility Compatible { get; } = new() { IsCompatible = true };

    /// <summary>
    /// Creates an incompatible <see cref="PluginCompatibility"/> result with a reason.
    /// </summary>
    /// <param name="reason">A description of why the plugin is incompatible.</param>
    /// <returns>A new <see cref="PluginCompatibility"/> with <see cref="IsCompatible"/> set to <c>false</c>.</returns>
    public static PluginCompatibility Incompatible(string reason) =>
        new() { IsCompatible = false, Reason = reason };
}
'@

New-SourceFile "Models/Plugin/FrameworkInfo.cs" @'
// <copyright file="FrameworkInfo.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Plugin;

/// <summary>
/// Provides information about the running Axbus framework version.
/// Passed to plugins via <see cref="Axbus.Core.Abstractions.Plugin.IPluginContext"/>
/// during initialisation so that plugins can perform their own
/// version compatibility checks.
/// </summary>
/// <param name="Version">The semantic version of the running Axbus framework.</param>
/// <param name="Environment">
/// The name of the hosting environment, for example <c>Development</c>,
/// <c>Staging</c> or <c>Production</c>.
/// </param>
public sealed record FrameworkInfo(Version Version, string Environment);
'@

# ==============================================================================
# PHASE 6 - MODELS - NOTIFICATIONS AND RESULTS
# ==============================================================================

Write-Phase "Phase 6 - Models/Notifications + Models/Results (4 files)"

New-SourceFile "Models/Notifications/ConversionProgress.cs" @'
// <copyright file="ConversionProgress.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Notifications;

using Axbus.Core.Enums;

/// <summary>
/// Carries progress information reported via <see cref="IProgress{T}"/>
/// to UI consumers such as the WinForms progress bar or console output.
/// Published by the conversion runner as each file and row is processed.
/// </summary>
public sealed class ConversionProgress
{
    /// <summary>Gets or sets the name of the conversion module currently executing.</summary>
    public string ModuleName { get; set; } = string.Empty;

    /// <summary>Gets or sets the total number of source files to process in this module.</summary>
    public int TotalFiles { get; set; }

    /// <summary>Gets or sets the number of source files processed so far.</summary>
    public int ProcessedFiles { get; set; }

    /// <summary>
    /// Gets or sets the estimated total number of rows across all source files.
    /// May be <c>-1</c> if the total is not yet known.
    /// </summary>
    public int TotalRows { get; set; }

    /// <summary>Gets or sets the number of rows processed and written so far.</summary>
    public int ProcessedRows { get; set; }

    /// <summary>
    /// Gets or sets the percentage of work completed, from <c>0.0</c> to <c>100.0</c>.
    /// </summary>
    public double PercentComplete { get; set; }

    /// <summary>Gets or sets the name of the source file currently being processed.</summary>
    public string CurrentFile { get; set; } = string.Empty;

    /// <summary>Gets or sets the current lifecycle status of the conversion module.</summary>
    public ConversionStatus Status { get; set; }
}
'@

New-SourceFile "Models/Notifications/ConversionEvent.cs" @'
// <copyright file="ConversionEvent.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Notifications;

using Axbus.Core.Enums;

/// <summary>
/// Represents a discrete lifecycle event published to the
/// <see cref="Axbus.Core.Abstractions.Notifications.IEventPublisher"/> observable stream.
/// UI consumers can subscribe to this stream to build live event logs, dashboards
/// or audit trails. Each event is identified by its <see cref="Type"/> and
/// includes contextual information such as the module name and affected file.
/// </summary>
public sealed class ConversionEvent
{
    /// <summary>Gets or sets the UTC timestamp at which this event occurred.</summary>
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    /// <summary>Gets or sets the name of the conversion module that raised this event.</summary>
    public string ModuleName { get; set; } = string.Empty;

    /// <summary>Gets or sets the type of lifecycle event that occurred.</summary>
    public ConversionEventType Type { get; set; }

    /// <summary>Gets or sets a human-readable message describing the event.</summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the name of the file associated with this event, if applicable.
    /// </summary>
    public string? FileName { get; set; }

    /// <summary>
    /// Gets or sets the exception associated with this event, if applicable.
    /// Only set for failure events such as <see cref="ConversionEventType.ModuleFailed"/>
    /// or <see cref="ConversionEventType.FileFailed"/>.
    /// </summary>
    public Exception? Exception { get; set; }
}
'@

New-SourceFile "Models/Results/ModuleResult.cs" @'
// <copyright file="ModuleResult.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Results;

using Axbus.Core.Enums;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Holds the outcome of executing a single <see cref="Axbus.Core.Models.Configuration.ConversionModule"/>.
/// Included in <see cref="ConversionSummary.Results"/> after the conversion run completes.
/// </summary>
public sealed class ModuleResult
{
    /// <summary>Gets or sets the name of the conversion module.</summary>
    public string ModuleName { get; set; } = string.Empty;

    /// <summary>Gets or sets the final lifecycle status of the module.</summary>
    public ConversionStatus Status { get; set; }

    /// <summary>Gets or sets the number of source files processed by this module.</summary>
    public int FilesProcessed { get; set; }

    /// <summary>Gets or sets the total number of rows successfully written.</summary>
    public int RowsWritten { get; set; }

    /// <summary>Gets or sets the number of rows written to the error output file.</summary>
    public int ErrorRowsWritten { get; set; }

    /// <summary>Gets or sets the full path to the primary output file.</summary>
    public string OutputFilePath { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the full path to the error output file.
    /// <c>null</c> when no error file was produced.
    /// </summary>
    public string? ErrorFilePath { get; set; }

    /// <summary>
    /// Gets or sets the list of output file paths produced by this module.
    /// Contains multiple entries when <see cref="Axbus.Core.Enums.OutputMode.OnePerFile"/> is used
    /// or when multiple output formats are configured.
    /// </summary>
    public List<string> OutputFiles { get; set; } = new();

    /// <summary>
    /// Gets or sets the column schema that was used for this module's output.
    /// </summary>
    public SchemaDefinition? SchemaUsed { get; set; }

    /// <summary>Gets or sets the total elapsed time for this module's execution.</summary>
    public TimeSpan Duration { get; set; }

    /// <summary>Gets or sets the list of error messages collected during execution.</summary>
    public List<string> Errors { get; set; } = new();

    /// <summary>Gets or sets the list of warning messages collected during execution.</summary>
    public List<string> Warnings { get; set; } = new();
}
'@

New-SourceFile "Models/Results/ConversionSummary.cs" @'
// <copyright file="ConversionSummary.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Results;

/// <summary>
/// Contains the aggregated results of a complete Axbus conversion run.
/// Returned by <see cref="Axbus.Core.Abstractions.Conversion.IConversionRunner.RunAsync"/>
/// after all conversion modules have been executed.
/// Suitable for display in the WinForms summary form, console output or audit logging.
/// </summary>
public sealed class ConversionSummary
{
    /// <summary>Gets or sets the total number of modules that were configured.</summary>
    public int TotalModules { get; set; }

    /// <summary>Gets or sets the number of modules that completed successfully.</summary>
    public int SuccessfulModules { get; set; }

    /// <summary>Gets or sets the number of modules that failed.</summary>
    public int FailedModules { get; set; }

    /// <summary>Gets or sets the number of modules that were skipped because they were disabled.</summary>
    public int SkippedModules { get; set; }

    /// <summary>Gets or sets the total number of source files processed across all modules.</summary>
    public int TotalFilesProcessed { get; set; }

    /// <summary>Gets or sets the total number of rows written across all modules.</summary>
    public int TotalRowsWritten { get; set; }

    /// <summary>Gets or sets the total number of error rows written across all modules.</summary>
    public int TotalErrorRows { get; set; }

    /// <summary>Gets or sets the total elapsed time for the entire conversion run.</summary>
    public TimeSpan TotalDuration { get; set; }

    /// <summary>
    /// Gets or sets the individual results for each conversion module.
    /// Ordered by <see cref="Axbus.Core.Models.Configuration.ConversionModule.ExecutionOrder"/>.
    /// </summary>
    public List<ModuleResult> Results { get; set; } = new();
}
'@

# ==============================================================================
# PHASE 7 - MODELS - SCHEMA
# ==============================================================================

Write-Phase "Phase 7 - Models/Pipeline/SchemaDefinition (1 file)"

New-SourceFile "Models/Pipeline/SchemaDefinition.cs" @'
// <copyright file="SchemaDefinition.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines the ordered set of column names that make up the output schema
/// for a conversion module. The schema is discovered by the writer plugin
/// (which implements <see cref="Axbus.Core.Abstractions.Pipeline.ISchemaAwareWriter"/>)
/// and determines which columns appear in the output and in what order.
/// </summary>
public sealed class SchemaDefinition
{
    /// <summary>
    /// Gets the ordered, read-only list of column names.
    /// Column names use dot-notation for nested fields,
    /// for example <c>customer.address.city</c>.
    /// Order is determined by the configured
    /// <see cref="Axbus.Core.Enums.SchemaStrategy"/> (default: first-seen).
    /// </summary>
    public IReadOnlyList<string> Columns { get; }

    /// <summary>
    /// Gets the format identifier of the output for which this schema was built.
    /// </summary>
    public string Format { get; }

    /// <summary>
    /// Gets the number of source files that contributed to this schema.
    /// </summary>
    public int SourceFileCount { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="SchemaDefinition"/>.
    /// </summary>
    /// <param name="columns">The ordered list of column names.</param>
    /// <param name="format">The output format identifier.</param>
    /// <param name="sourceFileCount">The number of source files that contributed columns.</param>
    public SchemaDefinition(IReadOnlyList<string> columns, string format, int sourceFileCount = 0)
    {
        Columns = columns;
        Format = format;
        SourceFileCount = sourceFileCount;
    }
}
'@

# ==============================================================================
# PHASE 8 - ABSTRACTIONS - PIPELINE
# ==============================================================================

Write-Phase "Phase 8 - Abstractions/Pipeline (7 files)"

New-SourceFile "Abstractions/Pipeline/ISourceReader.cs" @'
// <copyright file="ISourceReader.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines Stage 1 of the Axbus conversion pipeline.
/// Reads raw data from the source connector and returns it as a byte stream.
/// Implementations are format-agnostic and work with raw bytes only.
/// Implemented by reader plugins, for example <c>Axbus.Plugin.Reader.Json</c>.
/// </summary>
public interface ISourceReader
{
    /// <summary>
    /// Reads raw data from the source described by <paramref name="options"/>
    /// and returns it as a <see cref="SourceData"/> record containing the stream
    /// and metadata. The caller is responsible for disposing the stream.
    /// </summary>
    /// <param name="options">The source configuration describing where to read from.</param>
    /// <param name="cancellationToken">A token to cancel the read operation.</param>
    /// <returns>
    /// A <see cref="SourceData"/> record containing the raw stream and source metadata.
    /// </returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusConnectorException">
    /// Thrown when the source cannot be read due to an I/O or access error.
    /// </exception>
    Task<SourceData> ReadAsync(SourceOptions options, CancellationToken cancellationToken);
}
'@

New-SourceFile "Abstractions/Pipeline/IFormatParser.cs" @'
// <copyright file="IFormatParser.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines Stage 2 of the Axbus conversion pipeline.
/// Parses the raw byte stream produced by <see cref="ISourceReader"/> into
/// a streaming sequence of parsed elements. Implementations are format-specific
/// and are provided by reader plugins, for example <c>Axbus.Plugin.Reader.Json</c>.
/// </summary>
public interface IFormatParser
{
    /// <summary>
    /// Parses the raw stream contained in <paramref name="sourceData"/>
    /// and returns a <see cref="ParsedData"/> record containing a lazy
    /// asynchronous stream of parsed elements.
    /// Elements are produced on demand and should be consumed only once.
    /// </summary>
    /// <param name="sourceData">The raw stream produced by Stage 1 (Read).</param>
    /// <param name="cancellationToken">A token to cancel the parse operation.</param>
    /// <returns>
    /// A <see cref="ParsedData"/> record containing the element stream and metadata.
    /// </returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPipelineException">
    /// Thrown when the raw stream cannot be parsed as the expected format.
    /// </exception>
    Task<ParsedData> ParseAsync(SourceData sourceData, CancellationToken cancellationToken);
}
'@

New-SourceFile "Abstractions/Pipeline/IDataTransformer.cs" @'
// <copyright file="IDataTransformer.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines Stage 3 of the Axbus conversion pipeline.
/// Transforms the parsed element stream produced by <see cref="IFormatParser"/>
/// into a stream of flat <see cref="FlattenedRow"/> records.
/// Handles nested object flattening (dot-notation), array explosion and
/// depth limiting. Implemented by reader plugins.
/// </summary>
public interface IDataTransformer
{
    /// <summary>
    /// Transforms the parsed element stream into a lazy asynchronous stream
    /// of <see cref="FlattenedRow"/> records. Nested objects are flattened
    /// using dot-notation and arrays are exploded into multiple rows up to
    /// <see cref="PipelineOptions.MaxExplosionDepth"/>.
    /// </summary>
    /// <param name="parsedData">The element stream produced by Stage 2 (Parse).</param>
    /// <param name="options">The pipeline options controlling explosion depth and null handling.</param>
    /// <param name="cancellationToken">A token to cancel the transform operation.</param>
    /// <returns>
    /// A <see cref="TransformedData"/> record containing the flattened row stream.
    /// </returns>
    Task<TransformedData> TransformAsync(
        ParsedData parsedData,
        PipelineOptions options,
        CancellationToken cancellationToken);
}
'@

New-SourceFile "Abstractions/Pipeline/IOutputWriter.cs" @'
// <copyright file="IOutputWriter.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines Stage 4 of the Axbus conversion pipeline.
/// Writes the transformed row stream to the target connector in the
/// appropriate output format. Implemented by writer plugins such as
/// <c>Axbus.Plugin.Writer.Csv</c> and <c>Axbus.Plugin.Writer.Excel</c>.
/// Writer plugins that perform schema discovery should also implement
/// <see cref="ISchemaAwareWriter"/>.
/// </summary>
public interface IOutputWriter
{
    /// <summary>
    /// Writes the rows from <paramref name="transformedData"/> to the target
    /// described by <paramref name="targetOptions"/> and returns a
    /// <see cref="WriteResult"/> with statistics about the write operation.
    /// </summary>
    /// <param name="transformedData">The flattened row stream produced by Stage 3 (Transform).</param>
    /// <param name="targetOptions">The target configuration describing where to write.</param>
    /// <param name="pipelineOptions">Pipeline options controlling null placeholders and error strategy.</param>
    /// <param name="cancellationToken">A token to cancel the write operation.</param>
    /// <returns>
    /// A <see cref="WriteResult"/> containing row counts, output paths and duration.
    /// </returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPipelineException">
    /// Thrown when a write failure occurs that cannot be handled by the configured row error strategy.
    /// </exception>
    Task<WriteResult> WriteAsync(
        TransformedData transformedData,
        TargetOptions targetOptions,
        PipelineOptions pipelineOptions,
        CancellationToken cancellationToken);
}
'@

New-SourceFile "Abstractions/Pipeline/ISchemaAwareWriter.cs" @'
// <copyright file="ISchemaAwareWriter.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Pipeline;

/// <summary>
/// Optional capability interface implemented by writer plugins that need
/// to perform schema discovery before writing output. Schema building is
/// an internal writer concern and is not a public pipeline stage.
/// Writers that implement this interface are detected by the pipeline factory
/// and given the opportunity to build a schema before <see cref="IOutputWriter.WriteAsync"/>
/// is called.
/// </summary>
public interface ISchemaAwareWriter : IOutputWriter
{
    /// <summary>
    /// Discovers the output column schema by streaming through the transformed rows.
    /// This method is called by the pipeline factory before
    /// <see cref="IOutputWriter.WriteAsync"/> when
    /// <see cref="Axbus.Core.Enums.SchemaStrategy.FullScan"/> is configured.
    /// </summary>
    /// <param name="rows">
    /// The asynchronous stream of flattened rows to scan for column names.
    /// </param>
    /// <param name="cancellationToken">A token to cancel the schema build operation.</param>
    /// <returns>
    /// A <see cref="SchemaDefinition"/> containing the discovered column names
    /// in first-seen order.
    /// </returns>
    Task<SchemaDefinition> BuildSchemaAsync(
        IAsyncEnumerable<FlattenedRow> rows,
        CancellationToken cancellationToken);
}
'@

New-SourceFile "Abstractions/Pipeline/IDataValidator.cs" @'
// <copyright file="IDataValidator.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines the optional validation stage of the Axbus conversion pipeline.
/// When a validator is registered the pipeline executes it between the
/// Transform and Write stages. Invalid rows are handled according to the
/// configured <see cref="Axbus.Core.Enums.RowErrorStrategy"/>.
/// Implement this interface in a plugin to add custom business rule validation.
/// </summary>
public interface IDataValidator
{
    /// <summary>
    /// Validates a single <see cref="FlattenedRow"/> and returns a
    /// <see cref="ValidationResult"/> indicating whether the row is valid.
    /// </summary>
    /// <param name="row">The flattened row to validate.</param>
    /// <param name="cancellationToken">A token to cancel the validation operation.</param>
    /// <returns>
    /// A <see cref="ValidationResult"/> with <see cref="ValidationResult.IsValid"/> set to
    /// <c>true</c> if the row passes validation, or <c>false</c> with error messages otherwise.
    /// </returns>
    Task<ValidationResult> ValidateAsync(FlattenedRow row, CancellationToken cancellationToken);
}
'@

New-SourceFile "Abstractions/Pipeline/IDataFilter.cs" @'
// <copyright file="IDataFilter.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines the optional filter stage of the Axbus conversion pipeline.
/// When a filter is registered the pipeline executes it between the
/// Transform and Write stages. Rows for which the filter returns <c>false</c>
/// are excluded from the output without being treated as errors.
/// Implement this interface in a plugin to add row inclusion/exclusion logic.
/// </summary>
public interface IDataFilter
{
    /// <summary>
    /// Determines whether the specified <see cref="FlattenedRow"/> should be
    /// included in the output.
    /// </summary>
    /// <param name="row">The flattened row to evaluate.</param>
    /// <param name="cancellationToken">A token to cancel the filter evaluation.</param>
    /// <returns>
    /// <c>true</c> if the row should be included in the output;
    /// <c>false</c> if the row should be excluded silently.
    /// </returns>
    Task<bool> ShouldIncludeAsync(FlattenedRow row, CancellationToken cancellationToken);
}
'@

# ==============================================================================
# PHASE 9 - ABSTRACTIONS - MIDDLEWARE
# ==============================================================================

Write-Phase "Phase 9 - Abstractions/Middleware (3 files)"

New-SourceFile "Abstractions/Middleware/PipelineStageDelegate.cs" @'
// <copyright file="PipelineStageDelegate.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Middleware;

using Axbus.Core.Models.Pipeline;

/// <summary>
/// Represents the next action in the middleware pipeline chain.
/// Each <see cref="IPipelineMiddleware"/> implementation invokes this delegate
/// to pass control to the next middleware in the chain or, for the last middleware,
/// to the actual pipeline stage implementation.
/// This pattern mirrors the ASP.NET Core middleware pipeline design.
/// </summary>
/// <returns>
/// A task returning a <see cref="PipelineStageResult"/> from the next middleware or stage.
/// </returns>
public delegate Task<PipelineStageResult> PipelineStageDelegate();
'@

New-SourceFile "Abstractions/Middleware/IPipelineMiddlewareContext.cs" @'
// <copyright file="IPipelineMiddlewareContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Middleware;

using Axbus.Core.Enums;

/// <summary>
/// Provides contextual information to each <see cref="IPipelineMiddleware"/>
/// about the pipeline stage being executed. Allows middleware to produce
/// meaningful log messages and metrics that include the module name,
/// plugin identifier and stage name.
/// </summary>
public interface IPipelineMiddlewareContext
{
    /// <summary>Gets the name of the conversion module being executed.</summary>
    string ModuleName { get; }

    /// <summary>Gets the identifier of the plugin executing this stage.</summary>
    string PluginId { get; }

    /// <summary>Gets the pipeline stage being executed.</summary>
    PipelineStage Stage { get; }

    /// <summary>
    /// Gets additional properties associated with this stage execution.
    /// Can be used by middleware to pass arbitrary contextual data.
    /// </summary>
    IReadOnlyDictionary<string, object> Properties { get; }
}
'@

New-SourceFile "Abstractions/Middleware/IPipelineMiddleware.cs" @'
// <copyright file="IPipelineMiddleware.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Middleware;

using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines a middleware component that wraps pipeline stage execution.
/// Middleware components are chained together in a defined order so that
/// each component can perform work before and after the next component
/// in the chain, mirroring the ASP.NET Core middleware pipeline pattern.
/// Built-in implementations include logging, timing, retry and error handling.
/// </summary>
public interface IPipelineMiddleware
{
    /// <summary>
    /// Executes this middleware component, optionally calling <paramref name="next"/>
    /// to pass control to the next component in the chain.
    /// </summary>
    /// <param name="context">
    /// Contextual information about the pipeline stage being executed,
    /// including the module name, plugin identifier and stage type.
    /// </param>
    /// <param name="next">
    /// A delegate representing the next middleware in the chain or the actual
    /// pipeline stage. Call this to proceed; omit to short-circuit the pipeline.
    /// </param>
    /// <returns>
    /// A <see cref="PipelineStageResult"/> representing the outcome of this
    /// middleware execution and any downstream execution.
    /// </returns>
    Task<PipelineStageResult> InvokeAsync(
        IPipelineMiddlewareContext context,
        PipelineStageDelegate next);
}
'@

# ==============================================================================
# PHASE 10 - ABSTRACTIONS - CONNECTORS
# ==============================================================================

Write-Phase "Phase 10 - Abstractions/Connectors (3 files)"

New-SourceFile "Abstractions/Connectors/ISourceConnector.cs" @'
// <copyright file="ISourceConnector.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Connectors;

using Axbus.Core.Models.Configuration;

/// <summary>
/// Defines an abstraction over the physical source of input data.
/// Source connectors are format-agnostic; they return raw byte streams
/// that are subsequently parsed by the appropriate format parser plugin.
/// The default implementation reads from the local file system.
/// Future implementations may read from Azure Blob Storage, S3, HTTP endpoints, etc.
/// </summary>
public interface ISourceConnector
{
    /// <summary>
    /// Returns an asynchronous stream of raw byte streams from the source
    /// described by <paramref name="options"/>. Each stream corresponds to
    /// one source item (for example one file on disk).
    /// </summary>
    /// <param name="options">The source configuration describing where to read from.</param>
    /// <param name="cancellationToken">A token to cancel the enumeration.</param>
    /// <returns>
    /// An asynchronous enumerable of raw <see cref="Stream"/> instances.
    /// Each stream must be disposed by the caller after use.
    /// </returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusConnectorException">
    /// Thrown when the source cannot be accessed due to an I/O or permission error.
    /// </exception>
    IAsyncEnumerable<Stream> GetSourceStreamsAsync(
        SourceOptions options,
        CancellationToken cancellationToken);
}
'@

New-SourceFile "Abstractions/Connectors/ITargetConnector.cs" @'
// <copyright file="ITargetConnector.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Connectors;

using Axbus.Core.Models.Configuration;

/// <summary>
/// Defines an abstraction over the physical target for output data.
/// Target connectors are format-agnostic; they accept a raw byte stream
/// from the writer plugin and persist it to the target location.
/// The default implementation writes to the local file system.
/// Future implementations may write to Azure Blob Storage, S3, FTP, etc.
/// </summary>
public interface ITargetConnector
{
    /// <summary>
    /// Writes the raw byte stream in <paramref name="data"/> to the target
    /// described by <paramref name="options"/> using the provided
    /// <paramref name="fileName"/> as the output file name.
    /// </summary>
    /// <param name="data">The raw output byte stream to persist.</param>
    /// <param name="fileName">The file name (without path) to use for the output.</param>
    /// <param name="options">The target configuration describing where to write.</param>
    /// <param name="cancellationToken">A token to cancel the write operation.</param>
    /// <returns>The full path or URI of the persisted output.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusConnectorException">
    /// Thrown when the target cannot be written to due to an I/O or permission error.
    /// </exception>
    Task<string> WriteAsync(
        Stream data,
        string fileName,
        TargetOptions options,
        CancellationToken cancellationToken);
}
'@

New-SourceFile "Abstractions/Connectors/IConnectorFactory.cs" @'
// <copyright file="IConnectorFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Connectors;

using Axbus.Core.Models.Configuration;

/// <summary>
/// Resolves the appropriate <see cref="ISourceConnector"/> or
/// <see cref="ITargetConnector"/> implementation based on the
/// <see cref="SourceOptions.Type"/> or <see cref="TargetOptions.Type"/> value.
/// Registered connectors are matched by their type identifier string,
/// for example <c>FileSystem</c>.
/// </summary>
public interface IConnectorFactory
{
    /// <summary>
    /// Resolves the <see cref="ISourceConnector"/> registered for the
    /// type specified in <paramref name="options"/>.
    /// </summary>
    /// <param name="options">The source options containing the connector type identifier.</param>
    /// <returns>The matching <see cref="ISourceConnector"/> implementation.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusConfigurationException">
    /// Thrown when no connector is registered for the specified type.
    /// </exception>
    ISourceConnector GetSourceConnector(SourceOptions options);

    /// <summary>
    /// Resolves the <see cref="ITargetConnector"/> registered for the
    /// type specified in <paramref name="options"/>.
    /// </summary>
    /// <param name="options">The target options containing the connector type identifier.</param>
    /// <returns>The matching <see cref="ITargetConnector"/> implementation.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusConfigurationException">
    /// Thrown when no connector is registered for the specified type.
    /// </exception>
    ITargetConnector GetTargetConnector(TargetOptions options);
}
'@

# ==============================================================================
# PHASE 11 - ABSTRACTIONS - PLUGIN
# ==============================================================================

Write-Phase "Phase 11 - Abstractions/Plugin (8 files)"

New-SourceFile "Abstractions/Plugin/IPluginOptions.cs" @'
// <copyright file="IPluginOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Marker interface for plugin-specific options classes.
/// Each plugin declares a strongly-typed options class that implements
/// this interface. The framework deserialises the <c>PluginOptions</c>
/// section from the conversion module configuration into the plugin's
/// declared options type using
/// <see cref="Axbus.Core.Abstractions.Factories.IPluginOptionsFactory"/>.
/// Unknown configuration keys are captured in the overflow dictionary
/// using <c>[JsonExtensionData]</c>.
/// </summary>
public interface IPluginOptions
{
}
'@

New-SourceFile "Abstractions/Plugin/IPluginOptionsValidator.cs" @'
// <copyright file="IPluginOptionsValidator.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Validates plugin-specific options before the plugin is initialised.
/// Each plugin should provide an implementation that checks for required
/// fields, valid value ranges and internally consistent configurations.
/// The framework validates options at startup after deserialisation.
/// </summary>
public interface IPluginOptionsValidator
{
    /// <summary>
    /// Validates the specified plugin options instance.
    /// </summary>
    /// <param name="options">The options instance to validate.</param>
    /// <returns>
    /// An empty enumerable when options are valid, or one or more
    /// validation error messages when options are invalid.
    /// </returns>
    IEnumerable<string> Validate(IPluginOptions options);
}
'@

New-SourceFile "Abstractions/Plugin/IPluginManifest.cs" @'
// <copyright file="IPluginManifest.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Defines the contract for a plugin manifest.
/// The manifest provides identity and version information about a plugin
/// and is read from the <c>*.manifest.json</c> file before the plugin
/// assembly is loaded.
/// The concrete implementation is <see cref="Axbus.Core.Models.Plugin.PluginManifest"/>.
/// </summary>
public interface IPluginManifest
{
    /// <summary>Gets the display name of the plugin.</summary>
    string Name { get; }

    /// <summary>Gets the unique reverse-domain identifier of the plugin.</summary>
    string PluginId { get; }

    /// <summary>Gets the semantic version string of the plugin assembly.</summary>
    string Version { get; }

    /// <summary>Gets the minimum Axbus framework version this plugin requires.</summary>
    string FrameworkVersion { get; }
}
'@

New-SourceFile "Abstractions/Plugin/IPluginContext.cs" @'
// <copyright file="IPluginContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;

/// <summary>
/// Provides a plugin with access to its runtime environment during initialisation.
/// An instance of this interface is passed to
/// <see cref="IPlugin.InitializeAsync"/> so that the plugin can access its
/// configuration options, a scoped logger and information about the running
/// framework version. Plugins must not cache the context beyond initialisation.
/// </summary>
public interface IPluginContext
{
    /// <summary>Gets the unique identifier of the plugin being initialised.</summary>
    string PluginId { get; }

    /// <summary>Gets the full path to the folder containing the plugin assembly.</summary>
    string PluginFolder { get; }

    /// <summary>Gets the strongly-typed options for this plugin.</summary>
    IPluginOptions Options { get; }

    /// <summary>Gets a scoped logger for the plugin to use during initialisation.</summary>
    ILogger Logger { get; }

    /// <summary>Gets information about the running Axbus framework version.</summary>
    FrameworkInfo Framework { get; }
}
'@

New-SourceFile "Abstractions/Plugin/IPlugin.cs" @'
// <copyright file="IPlugin.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Enums;

/// <summary>
/// The base contract that every Axbus plugin must implement.
/// A plugin declares which pipeline stages it supports via
/// <see cref="Capabilities"/> and provides factory methods to create
/// stage implementations. Stage factory methods return <c>null</c>
/// for stages the plugin does not support. The framework calls
/// <see cref="InitializeAsync"/> after loading and before the first
/// pipeline execution, and <see cref="ShutdownAsync"/> on application exit.
/// </summary>
public interface IPlugin
{
    /// <summary>
    /// Gets the unique reverse-domain identifier of this plugin.
    /// Example: <c>axbus.plugin.reader.json</c>.
    /// </summary>
    string PluginId { get; }

    /// <summary>Gets the display name of this plugin.</summary>
    string Name { get; }

    /// <summary>Gets the semantic version of this plugin assembly.</summary>
    Version Version { get; }

    /// <summary>
    /// Gets the minimum Axbus framework version required by this plugin.
    /// </summary>
    Version MinFrameworkVersion { get; }

    /// <summary>
    /// Gets the pipeline stages this plugin supports.
    /// </summary>
    PluginCapabilities Capabilities { get; }

    /// <summary>
    /// Creates the <see cref="ISourceReader"/> implementation for this plugin.
    /// </summary>
    /// <param name="services">The application service provider for dependency resolution.</param>
    /// <returns>An <see cref="ISourceReader"/> instance, or <c>null</c> if not supported.</returns>
    ISourceReader? CreateReader(IServiceProvider services);

    /// <summary>
    /// Creates the <see cref="IFormatParser"/> implementation for this plugin.
    /// </summary>
    /// <param name="services">The application service provider for dependency resolution.</param>
    /// <returns>An <see cref="IFormatParser"/> instance, or <c>null</c> if not supported.</returns>
    IFormatParser? CreateParser(IServiceProvider services);

    /// <summary>
    /// Creates the <see cref="IDataTransformer"/> implementation for this plugin.
    /// </summary>
    /// <param name="services">The application service provider for dependency resolution.</param>
    /// <returns>An <see cref="IDataTransformer"/> instance, or <c>null</c> if not supported.</returns>
    IDataTransformer? CreateTransformer(IServiceProvider services);

    /// <summary>
    /// Creates the <see cref="IOutputWriter"/> implementation for this plugin.
    /// </summary>
    /// <param name="services">The application service provider for dependency resolution.</param>
    /// <returns>An <see cref="IOutputWriter"/> instance, or <c>null</c> if not supported.</returns>
    IOutputWriter? CreateWriter(IServiceProvider services);

    /// <summary>
    /// Initializes this plugin with its context, validates options and prepares
    /// any internal state required before the first pipeline execution.
    /// Called once by the framework after the plugin is loaded.
    /// </summary>
    /// <param name="context">The plugin context providing options, logger and framework info.</param>
    /// <param name="cancellationToken">A token to cancel the initialisation.</param>
    Task InitializeAsync(IPluginContext context, CancellationToken cancellationToken);

    /// <summary>
    /// Releases resources held by this plugin.
    /// Called by the framework on application shutdown or when the plugin is unloaded.
    /// </summary>
    /// <param name="cancellationToken">A token to cancel the shutdown.</param>
    Task ShutdownAsync(CancellationToken cancellationToken);
}
'@

New-SourceFile "Abstractions/Plugin/IPluginLoader.cs" @'
// <copyright file="IPluginLoader.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

using Axbus.Core.Models.Plugin;

/// <summary>
/// Loads a plugin assembly from disk into an
/// <see cref="System.Runtime.Loader.AssemblyLoadContext"/> and creates
/// an <see cref="IPlugin"/> instance from the assembly.
/// Works with the manifest read by <see cref="IPluginManifestReader"/>
/// to produce a <see cref="PluginDescriptor"/> for registration.
/// </summary>
public interface IPluginLoader
{
    /// <summary>
    /// Loads the plugin assembly identified by <paramref name="fileSet"/>
    /// and returns a <see cref="PluginDescriptor"/> containing the
    /// <see cref="IPlugin"/> instance, manifest and assembly reference.
    /// </summary>
    /// <param name="fileSet">The DLL and manifest file paths for the plugin to load.</param>
    /// <param name="cancellationToken">A token to cancel the load operation.</param>
    /// <returns>
    /// A <see cref="PluginDescriptor"/> containing the loaded plugin information.
    /// </returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPluginException">
    /// Thrown when the assembly cannot be loaded or does not contain a valid <see cref="IPlugin"/> implementation.
    /// </exception>
    Task<PluginDescriptor> LoadAsync(PluginFileSet fileSet, CancellationToken cancellationToken);
}
'@

New-SourceFile "Abstractions/Plugin/IPluginRegistry.cs" @'
// <copyright file="IPluginRegistry.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

using Axbus.Core.Models.Plugin;

/// <summary>
/// Maintains the registry of loaded plugins and resolves the appropriate
/// plugin for a given source and target format combination.
/// Conflict resolution between multiple plugins supporting the same format
/// pair is governed by the configured
/// <see cref="Axbus.Core.Enums.PluginConflictStrategy"/>.
/// </summary>
public interface IPluginRegistry
{
    /// <summary>
    /// Registers a loaded plugin described by <paramref name="descriptor"/>
    /// in the registry. Applies conflict resolution if a plugin for the
    /// same format combination is already registered.
    /// </summary>
    /// <param name="descriptor">The descriptor of the plugin to register.</param>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPluginException">
    /// Thrown when <see cref="Axbus.Core.Enums.PluginConflictStrategy.ThrowException"/>
    /// is configured and a conflicting plugin is already registered.
    /// </exception>
    void Register(PluginDescriptor descriptor);

    /// <summary>
    /// Resolves the best available <see cref="IPlugin"/> for the specified
    /// source and target format combination.
    /// </summary>
    /// <param name="sourceFormat">The source format identifier, for example <c>json</c>.</param>
    /// <param name="targetFormat">The target format identifier, for example <c>csv</c>.</param>
    /// <returns>The resolved <see cref="IPlugin"/> instance.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPluginException">
    /// Thrown when no plugin is registered for the specified format combination.
    /// </exception>
    IPlugin Resolve(string sourceFormat, string targetFormat);

    /// <summary>
    /// Resolves a plugin by its explicit plugin identifier.
    /// Used when <see cref="Axbus.Core.Models.Configuration.ConversionModule.PluginOverride"/>
    /// is specified.
    /// </summary>
    /// <param name="pluginId">The unique identifier of the plugin to resolve.</param>
    /// <returns>The <see cref="IPlugin"/> with the specified identifier.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPluginException">
    /// Thrown when no plugin with the specified identifier is registered.
    /// </exception>
    IPlugin ResolveById(string pluginId);

    /// <summary>
    /// Gets all currently registered plugin descriptors.
    /// </summary>
    IReadOnlyCollection<PluginDescriptor> GetAll();
}
'@

New-SourceFile "Abstractions/Plugin/IPluginManifestReader.cs" @'
// <copyright file="IPluginManifestReader.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

using Axbus.Core.Models.Plugin;

/// <summary>
/// Deserialises a plugin manifest file (<c>*.manifest.json</c>) into a
/// <see cref="PluginManifest"/> model. The manifest is read before the
/// plugin assembly is loaded so that version compatibility can be checked
/// without incurring the cost of loading the full assembly.
/// </summary>
public interface IPluginManifestReader
{
    /// <summary>
    /// Reads and deserialises the manifest file at <paramref name="manifestPath"/>.
    /// </summary>
    /// <param name="manifestPath">The full path to the <c>*.manifest.json</c> file.</param>
    /// <param name="cancellationToken">A token to cancel the read operation.</param>
    /// <returns>A <see cref="PluginManifest"/> populated from the manifest file.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPluginException">
    /// Thrown when the manifest file cannot be read or is malformed.
    /// </exception>
    Task<PluginManifest> ReadAsync(string manifestPath, CancellationToken cancellationToken);
}
'@

# ==============================================================================
# PHASE 12 - ABSTRACTIONS - CONVERSION
# ==============================================================================

Write-Phase "Phase 12 - Abstractions/Conversion (3 files)"

New-SourceFile "Abstractions/Conversion/IConversionContext.cs" @'
// <copyright file="IConversionContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Conversion;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Carries accumulated state through the conversion pipeline stages for a
/// single source file within a module execution. Each stage reads from and
/// writes to the context so that results are available to subsequent stages
/// and middleware components.
/// </summary>
public interface IConversionContext
{
    /// <summary>Gets the conversion module configuration for this execution.</summary>
    ConversionModule Module { get; }

    /// <summary>Gets or sets the output of Stage 1 (Read). Set after Read completes.</summary>
    SourceData? SourceData { get; set; }

    /// <summary>Gets or sets the output of Stage 2 (Parse). Set after Parse completes.</summary>
    ParsedData? ParsedData { get; set; }

    /// <summary>Gets or sets the output of Stage 3 (Transform). Set after Transform completes.</summary>
    TransformedData? TransformedData { get; set; }

    /// <summary>Gets or sets the output of Stage 4 (Write). Set after Write completes.</summary>
    WriteResult? WriteResult { get; set; }

    /// <summary>Gets the path of the source file currently being processed.</summary>
    string CurrentSourcePath { get; }

    /// <summary>
    /// Gets or sets a value indicating whether processing of this source file
    /// should be cancelled. Set by error handling middleware when a non-recoverable
    /// error occurs and <see cref="ConversionModule.ContinueOnError"/> is <c>false</c>.
    /// </summary>
    bool IsCancelled { get; set; }
}
'@

New-SourceFile "Abstractions/Conversion/IConversionPipeline.cs" @'
// <copyright file="IConversionPipeline.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Conversion;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Orchestrates the execution of all pipeline stages for a single source file
/// within a conversion module. Assembles the stage chain
/// (Read -> Parse -> Transform -> Write) and wraps each stage in the
/// configured middleware. One pipeline instance is created per conversion module.
/// </summary>
public interface IConversionPipeline
{
    /// <summary>
    /// Executes the full pipeline for the source file at <paramref name="sourcePath"/>
    /// within the context of the specified <paramref name="module"/> configuration.
    /// Returns a <see cref="WriteResult"/> with statistics about the completed write.
    /// </summary>
    /// <param name="module">The conversion module configuration to use.</param>
    /// <param name="sourcePath">The full path or URI of the source file to process.</param>
    /// <param name="cancellationToken">A token to cancel the pipeline execution.</param>
    /// <returns>A <see cref="WriteResult"/> containing row counts and output paths.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPipelineException">
    /// Thrown when a stage fails and the error cannot be handled by the configured strategy.
    /// </exception>
    Task<WriteResult> ExecuteAsync(
        ConversionModule module,
        string sourcePath,
        CancellationToken cancellationToken);
}
'@

New-SourceFile "Abstractions/Conversion/IConversionRunner.cs" @'
// <copyright file="IConversionRunner.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Conversion;

using Axbus.Core.Models.Notifications;
using Axbus.Core.Models.Results;

/// <summary>
/// Orchestrates the execution of all enabled conversion modules defined in
/// <see cref="Axbus.Core.Models.Configuration.AxbusRootSettings.ConversionModules"/>.
/// Handles sequential and parallel execution, progress reporting and event publishing.
/// The primary entry point for both the ConsoleApp and WinFormsApp clients.
/// </summary>
public interface IConversionRunner
{
    /// <summary>
    /// Executes all enabled conversion modules and returns a
    /// <see cref="ConversionSummary"/> with aggregated results.
    /// Modules are executed sequentially or in parallel based on the
    /// root and module-level <c>RunInParallel</c> configuration.
    /// </summary>
    /// <param name="progress">
    /// An optional progress reporter. When provided, the runner reports
    /// <see cref="ConversionProgress"/> updates as each file and row is processed.
    /// Safe to pass <c>null</c> when progress reporting is not needed.
    /// </param>
    /// <param name="cancellationToken">
    /// A token to cancel the entire run. When cancelled, the current module
    /// completes its current file and then stops.
    /// </param>
    /// <returns>
    /// A <see cref="ConversionSummary"/> containing per-module results
    /// and aggregated statistics for the entire run.
    /// </returns>
    Task<ConversionSummary> RunAsync(
        IProgress<ConversionProgress>? progress = null,
        CancellationToken cancellationToken = default);
}
'@

# ==============================================================================
# PHASE 13 - ABSTRACTIONS - FACTORIES + NOTIFICATIONS
# ==============================================================================

Write-Phase "Phase 13 - Abstractions/Factories + Notifications (5 files)"

New-SourceFile "Abstractions/Factories/IPipelineFactory.cs" @'
// <copyright file="IPipelineFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Factories;

using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Models.Configuration;

/// <summary>
/// Creates a configured <see cref="IConversionPipeline"/> for a specific
/// conversion module. Resolves the appropriate reader and writer plugins
/// from the registry and assembles the middleware chain.
/// </summary>
public interface IPipelineFactory
{
    /// <summary>
    /// Creates a fully configured <see cref="IConversionPipeline"/> for
    /// the specified <paramref name="module"/>.
    /// Resolves reader and writer plugins from the registry based on
    /// <see cref="ConversionModule.SourceFormat"/>, <see cref="ConversionModule.TargetFormat"/>
    /// and <see cref="ConversionModule.PluginOverride"/>.
    /// </summary>
    /// <param name="module">The conversion module to build a pipeline for.</param>
    /// <returns>A ready-to-execute <see cref="IConversionPipeline"/>.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPluginException">
    /// Thrown when no suitable plugin can be resolved for the module's format combination.
    /// </exception>
    IConversionPipeline Create(ConversionModule module);
}
'@

New-SourceFile "Abstractions/Factories/IPluginOptionsFactory.cs" @'
// <copyright file="IPluginOptionsFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Factories;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Models.Configuration;

/// <summary>
/// Deserialises the raw <see cref="ConversionModule.PluginOptions"/> dictionary
/// into a strongly-typed <see cref="IPluginOptions"/> instance appropriate
/// for the specified plugin. Unknown keys are captured in an overflow
/// dictionary decorated with <c>[JsonExtensionData]</c>.
/// </summary>
public interface IPluginOptionsFactory
{
    /// <summary>
    /// Deserialises the plugin options from <paramref name="module"/> into
    /// a strongly-typed options instance of type <typeparamref name="TOptions"/>.
    /// </summary>
    /// <typeparam name="TOptions">
    /// The plugin-specific options type that implements <see cref="IPluginOptions"/>.
    /// </typeparam>
    /// <param name="module">
    /// The conversion module whose <see cref="ConversionModule.PluginOptions"/>
    /// dictionary is to be deserialised.
    /// </param>
    /// <returns>A populated <typeparamref name="TOptions"/> instance.</returns>
    TOptions Create<TOptions>(ConversionModule module) where TOptions : IPluginOptions, new();
}
'@

New-SourceFile "Abstractions/Factories/IMiddlewareFactory.cs" @'
// <copyright file="IMiddlewareFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Factories;

using Axbus.Core.Abstractions.Middleware;

/// <summary>
/// Resolves and orders the middleware components to be applied to each
/// pipeline stage execution. The default chain always includes logging,
/// timing and error handling middleware. Retry middleware is included
/// when configured.
/// </summary>
public interface IMiddlewareFactory
{
    /// <summary>
    /// Creates the ordered list of <see cref="IPipelineMiddleware"/> components
    /// to apply to pipeline stage executions.
    /// Components are applied in list order: the first component in the list
    /// is the outermost wrapper.
    /// </summary>
    /// <returns>
    /// An ordered list of <see cref="IPipelineMiddleware"/> instances.
    /// </returns>
    IReadOnlyList<IPipelineMiddleware> Create();
}
'@

New-SourceFile "Abstractions/Notifications/IProgressReporter.cs" @'
// <copyright file="IProgressReporter.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Notifications;

using Axbus.Core.Models.Notifications;

/// <summary>
/// Reports conversion progress to UI consumers via the standard
/// <see cref="IProgress{T}"/> mechanism. Implementations calculate
/// the percentage complete from file and row counts and invoke the
/// registered <see cref="IProgress{ConversionProgress}"/> callback
/// on the correct synchronisation context.
/// </summary>
public interface IProgressReporter
{
    /// <summary>
    /// Reports the current <see cref="ConversionProgress"/> to all registered consumers.
    /// </summary>
    /// <param name="progress">The current progress state to report.</param>
    void Report(ConversionProgress progress);

    /// <summary>
    /// Registers an <see cref="IProgress{ConversionProgress}"/> consumer.
    /// Can be called by UI layers (WinForms, Console) to receive progress updates.
    /// </summary>
    /// <param name="consumer">The progress consumer to register.</param>
    void Register(IProgress<ConversionProgress> consumer);
}
'@

New-SourceFile "Abstractions/Notifications/IEventPublisher.cs" @'
// <copyright file="IEventPublisher.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Notifications;

using Axbus.Core.Models.Notifications;

/// <summary>
/// Publishes conversion lifecycle events to an observable stream.
/// Implemented using <c>System.Reactive</c> subjects. UI consumers can
/// subscribe to <see cref="Events"/> to receive a real-time stream of
/// <see cref="ConversionEvent"/> notifications.
/// </summary>
public interface IEventPublisher
{
    /// <summary>
    /// Gets the observable stream of conversion events.
    /// Subscribe before calling
    /// <see cref="Axbus.Core.Abstractions.Conversion.IConversionRunner.RunAsync"/>
    /// to ensure no events are missed.
    /// </summary>
    IObservable<ConversionEvent> Events { get; }

    /// <summary>
    /// Publishes a <see cref="ConversionEvent"/> to all current subscribers.
    /// Called internally by the conversion runner and pipeline components.
    /// </summary>
    /// <param name="conversionEvent">The event to publish.</param>
    void Publish(ConversionEvent conversionEvent);

    /// <summary>
    /// Signals that the event stream has completed and no further events will be published.
    /// Called by the conversion runner after all modules have finished executing.
    /// </summary>
    void Complete();
}
'@

# ==============================================================================
# FINAL BUILD VERIFICATION HINT
# ==============================================================================

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "  [DONE] Axbus.Core - All files generated successfully!" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Files generated:" -ForegroundColor White
Write-Host "    [OK] 10 Enums" -ForegroundColor Green
Write-Host "    [OK]  4 Exceptions" -ForegroundColor Green
Write-Host "    [OK]  7 Models/Configuration" -ForegroundColor Green
Write-Host "    [OK]  9 Models/Pipeline" -ForegroundColor Green
Write-Host "    [OK]  1 Models/Pipeline/SchemaDefinition" -ForegroundColor Green
Write-Host "    [OK]  5 Models/Plugin" -ForegroundColor Green
Write-Host "    [OK]  2 Models/Notifications" -ForegroundColor Green
Write-Host "    [OK]  2 Models/Results" -ForegroundColor Green
Write-Host "    [OK]  7 Abstractions/Pipeline" -ForegroundColor Green
Write-Host "    [OK]  3 Abstractions/Middleware" -ForegroundColor Green
Write-Host "    [OK]  3 Abstractions/Connectors" -ForegroundColor Green
Write-Host "    [OK]  8 Abstractions/Plugin" -ForegroundColor Green
Write-Host "    [OK]  3 Abstractions/Conversion" -ForegroundColor Green
Write-Host "    [OK]  5 Abstractions/Factories + Notifications" -ForegroundColor Green
Write-Host ""
Write-Host "  Total: 69 source files" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next Steps:" -ForegroundColor Yellow
Write-Host "    1. Build Axbus.Core: dotnet build src/framework/Axbus.Core" -ForegroundColor White
Write-Host "    2. Verify: 0 errors" -ForegroundColor White
Write-Host "    3. Run generate-application.ps1 for Message 2" -ForegroundColor White
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
