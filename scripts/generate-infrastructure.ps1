# ==============================================================================
# generate-infrastructure.ps1
# Axbus Framework - Axbus.Infrastructure Layer Code Generation Script
# Copyright (c) 2026 Axel Johnson International. All rights reserved.
#
# USAGE:
#   PowerShell -ExecutionPolicy Bypass -File .\scripts\generate-infrastructure.ps1
#
# PREREQUISITES:
#   - Run generate-core.ps1 first
#   - Run generate-application.ps1 first
#   - Run from the repository root
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptVersion = "1.0.0"
$CompanyName   = "Axel Johnson International"
$CopyrightYear = "2026"
$RootPath      = "src/framework/Axbus.Infrastructure"

function Write-Banner {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "  Axbus.Infrastructure - Code Generation Script v$ScriptVersion" -ForegroundColor Cyan
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

if (-not (Test-Path ".git")) {
    Write-Host "  [FAILED] Run from repository root." -ForegroundColor Red; exit 1
}
if (-not (Test-Path $RootPath)) {
    Write-Host "  [FAILED] $RootPath not found. Run setup-axbus.ps1 first." -ForegroundColor Red; exit 1
}
if (-not (Test-Path "src/framework/Axbus.Application/Axbus.Application.csproj")) {
    Write-Host "  [FAILED] Axbus.Application not found. Run generate-application.ps1 first." -ForegroundColor Red; exit 1
}

Write-Banner

# ==============================================================================
# PHASE 1 - CONNECTORS
# ==============================================================================

Write-Phase "Phase 1 - Connectors (3 files)"

New-SourceFile "Connectors/LocalFileSourceConnector.cs" @'
// <copyright file="LocalFileSourceConnector.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Connectors;

using Axbus.Core.Abstractions.Connectors;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Microsoft.Extensions.Logging;

/// <summary>
/// Reads raw byte streams from the local file system.
/// This connector is format-agnostic and returns streams regardless of file type.
/// It is the default <see cref="ISourceConnector"/> implementation registered
/// for the <c>FileSystem</c> connector type.
/// Supports single-file and all-files read modes controlled by
/// <see cref="SourceOptions.ReadMode"/>.
/// </summary>
public sealed class LocalFileSourceConnector : ISourceConnector
{
    /// <summary>
    /// Logger instance for structured connector diagnostic output.
    /// </summary>
    private readonly ILogger<LocalFileSourceConnector> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="LocalFileSourceConnector"/>.
    /// </summary>
    /// <param name="logger">The logger for connector operations.</param>
    public LocalFileSourceConnector(ILogger<LocalFileSourceConnector> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Returns an asynchronous stream of raw byte streams from the local file system
    /// path described by <paramref name="options"/>.
    /// When <see cref="SourceOptions.ReadMode"/> is <c>AllFiles</c> all files matching
    /// <see cref="SourceOptions.FilePattern"/> in <see cref="SourceOptions.Path"/> are returned.
    /// When <see cref="SourceOptions.ReadMode"/> is <c>SingleFile</c> only the file at
    /// <see cref="SourceOptions.Path"/> is returned.
    /// </summary>
    /// <param name="options">The source configuration describing the local path and file pattern.</param>
    /// <param name="cancellationToken">A token to cancel the enumeration.</param>
    /// <returns>An asynchronous enumerable of raw file streams. Each stream must be disposed by the caller.</returns>
    /// <exception cref="AxbusConnectorException">
    /// Thrown when the path does not exist or cannot be accessed.
    /// </exception>
    public async IAsyncEnumerable<Stream> GetSourceStreamsAsync(
        SourceOptions options,
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(options);
        ArgumentException.ThrowIfNullOrWhiteSpace(options.Path);

        // Determine file paths to stream based on read mode
        var filePaths = GetFilePaths(options);

        foreach (var filePath in filePaths)
        {
            cancellationToken.ThrowIfCancellationRequested();

            logger.LogDebug("Opening source file: {FilePath}", filePath);

            Stream stream;

            try
            {
                // Open file as a read-only async stream
                stream = new FileStream(
                    filePath,
                    FileMode.Open,
                    FileAccess.Read,
                    FileShare.Read,
                    bufferSize: 81920,
                    useAsync: true);
            }
            catch (FileNotFoundException ex)
            {
                throw new AxbusConnectorException(
                    $"Source file not found: {filePath}", filePath, ex);
            }
            catch (UnauthorizedAccessException ex)
            {
                throw new AxbusConnectorException(
                    $"Access denied reading file: {filePath}", filePath, ex);
            }
            catch (IOException ex)
            {
                throw new AxbusConnectorException(
                    $"I/O error reading file: {filePath}", filePath, ex);
            }

            // Yield the stream - caller is responsible for disposal
            yield return stream;

            // Brief yield to keep the async enumerable cooperative
            await Task.Yield();
        }
    }

    /// <summary>
    /// Determines the list of file paths to process based on the source options.
    /// </summary>
    /// <param name="options">The source options containing path and file pattern.</param>
    /// <returns>An enumerable of absolute file paths to process.</returns>
    /// <exception cref="AxbusConnectorException">
    /// Thrown when the specified path does not exist.
    /// </exception>
    private IEnumerable<string> GetFilePaths(SourceOptions options)
    {
        // SingleFile mode: treat Path as a direct file path
        if (string.Equals(options.ReadMode, "SingleFile", StringComparison.OrdinalIgnoreCase))
        {
            if (!File.Exists(options.Path))
            {
                throw new AxbusConnectorException(
                    $"Source file not found: {options.Path}", options.Path);
            }

            logger.LogDebug("SingleFile mode: {FilePath}", options.Path);
            return new[] { options.Path };
        }

        // AllFiles mode: enumerate all matching files in the folder
        if (!Directory.Exists(options.Path))
        {
            throw new AxbusConnectorException(
                $"Source folder not found: {options.Path}", options.Path);
        }

        var pattern = string.IsNullOrWhiteSpace(options.FilePattern) ? "*.*" : options.FilePattern;
        var files = Directory.GetFiles(options.Path, pattern, SearchOption.TopDirectoryOnly);

        logger.LogDebug(
            "AllFiles mode: Found {Count} files matching '{Pattern}' in '{Path}'",
            files.Length,
            pattern,
            options.Path);

        return files.OrderBy(f => f);
    }
}
'@

New-SourceFile "Connectors/LocalFileTargetConnector.cs" @'
// <copyright file="LocalFileTargetConnector.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Connectors;

using Axbus.Core.Abstractions.Connectors;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Microsoft.Extensions.Logging;

/// <summary>
/// Writes raw byte streams to the local file system.
/// This connector is format-agnostic and writes any stream to disk.
/// It is the default <see cref="ITargetConnector"/> implementation registered
/// for the <c>FileSystem</c> connector type.
/// Creates the target directory if it does not already exist.
/// </summary>
public sealed class LocalFileTargetConnector : ITargetConnector
{
    /// <summary>
    /// Logger instance for structured connector diagnostic output.
    /// </summary>
    private readonly ILogger<LocalFileTargetConnector> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="LocalFileTargetConnector"/>.
    /// </summary>
    /// <param name="logger">The logger for connector operations.</param>
    public LocalFileTargetConnector(ILogger<LocalFileTargetConnector> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Writes the raw byte stream <paramref name="data"/> to the local file system
    /// folder described by <paramref name="options"/> using <paramref name="fileName"/>
    /// as the output file name. Creates the target folder if it does not exist.
    /// </summary>
    /// <param name="data">The raw output byte stream to write to disk.</param>
    /// <param name="fileName">The output file name (without path).</param>
    /// <param name="options">The target configuration describing the output folder path.</param>
    /// <param name="cancellationToken">A token to cancel the write operation.</param>
    /// <returns>The full path of the written output file.</returns>
    /// <exception cref="AxbusConnectorException">
    /// Thrown when the output file cannot be written due to an I/O or access error.
    /// </exception>
    public async Task<string> WriteAsync(
        Stream data,
        string fileName,
        TargetOptions options,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(data);
        ArgumentException.ThrowIfNullOrWhiteSpace(fileName);
        ArgumentNullException.ThrowIfNull(options);
        ArgumentException.ThrowIfNullOrWhiteSpace(options.Path);

        // Ensure the target directory exists
        try
        {
            if (!Directory.Exists(options.Path))
            {
                Directory.CreateDirectory(options.Path);
                logger.LogDebug("Created target directory: {Path}", options.Path);
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            throw new AxbusConnectorException(
                $"Failed to create target directory: {options.Path}", options.Path, ex);
        }

        // Build the full output file path
        var outputPath = Path.Combine(options.Path, fileName);

        logger.LogDebug("Writing output file: {OutputPath}", outputPath);

        try
        {
            await using var fileStream = new FileStream(
                outputPath,
                FileMode.Create,
                FileAccess.Write,
                FileShare.None,
                bufferSize: 81920,
                useAsync: true);

            await data.CopyToAsync(fileStream, cancellationToken).ConfigureAwait(false);
        }
        catch (UnauthorizedAccessException ex)
        {
            throw new AxbusConnectorException(
                $"Access denied writing to: {outputPath}", outputPath, ex);
        }
        catch (IOException ex)
        {
            throw new AxbusConnectorException(
                $"I/O error writing to: {outputPath}", outputPath, ex);
        }

        logger.LogInformation("Output file written: {OutputPath}", outputPath);

        return outputPath;
    }
}
'@

New-SourceFile "Connectors/ConnectorFactory.cs" @'
// <copyright file="ConnectorFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Connectors;

using Axbus.Core.Abstractions.Connectors;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

/// <summary>
/// Resolves the appropriate <see cref="ISourceConnector"/> or
/// <see cref="ITargetConnector"/> based on the connector type identifier
/// in the source or target options. Connectors are resolved from the
/// DI container by type so that new connector implementations can be
/// registered without modifying this factory.
/// </summary>
public sealed class ConnectorFactory : IConnectorFactory
{
    /// <summary>
    /// Logger instance for connector resolution diagnostic messages.
    /// </summary>
    private readonly ILogger<ConnectorFactory> logger;

    /// <summary>
    /// Service provider used to resolve connector implementations.
    /// </summary>
    private readonly IServiceProvider serviceProvider;

    /// <summary>
    /// Maps connector type identifiers to source connector service types.
    /// </summary>
    private static readonly Dictionary<string, Type> SourceConnectorMap =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["FileSystem"] = typeof(LocalFileSourceConnector),
        };

    /// <summary>
    /// Maps connector type identifiers to target connector service types.
    /// </summary>
    private static readonly Dictionary<string, Type> TargetConnectorMap =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["FileSystem"] = typeof(LocalFileTargetConnector),
        };

    /// <summary>
    /// Initializes a new instance of <see cref="ConnectorFactory"/>.
    /// </summary>
    /// <param name="logger">The logger for connector resolution messages.</param>
    /// <param name="serviceProvider">The service provider for connector resolution.</param>
    public ConnectorFactory(ILogger<ConnectorFactory> logger, IServiceProvider serviceProvider)
    {
        this.logger = logger;
        this.serviceProvider = serviceProvider;
    }

    /// <summary>
    /// Resolves the <see cref="ISourceConnector"/> for the type in <paramref name="options"/>.
    /// </summary>
    /// <param name="options">The source options containing the connector type identifier.</param>
    /// <returns>The matching <see cref="ISourceConnector"/> implementation.</returns>
    /// <exception cref="AxbusConfigurationException">
    /// Thrown when no connector is registered for the specified type.
    /// </exception>
    public ISourceConnector GetSourceConnector(SourceOptions options)
    {
        ArgumentNullException.ThrowIfNull(options);

        if (!SourceConnectorMap.TryGetValue(options.Type, out var connectorType))
        {
            throw new AxbusConfigurationException(
                $"No source connector registered for type '{options.Type}'. " +
                $"Supported types: {string.Join(", ", SourceConnectorMap.Keys)}",
                nameof(options.Type));
        }

        logger.LogDebug("Resolving source connector: {Type}", options.Type);

        return (ISourceConnector)serviceProvider.GetRequiredService(connectorType);
    }

    /// <summary>
    /// Resolves the <see cref="ITargetConnector"/> for the type in <paramref name="options"/>.
    /// </summary>
    /// <param name="options">The target options containing the connector type identifier.</param>
    /// <returns>The matching <see cref="ITargetConnector"/> implementation.</returns>
    /// <exception cref="AxbusConfigurationException">
    /// Thrown when no connector is registered for the specified type.
    /// </exception>
    public ITargetConnector GetTargetConnector(TargetOptions options)
    {
        ArgumentNullException.ThrowIfNull(options);

        if (!TargetConnectorMap.TryGetValue(options.Type, out var connectorType))
        {
            throw new AxbusConfigurationException(
                $"No target connector registered for type '{options.Type}'. " +
                $"Supported types: {string.Join(", ", TargetConnectorMap.Keys)}",
                nameof(options.Type));
        }

        logger.LogDebug("Resolving target connector: {Type}", options.Type);

        return (ITargetConnector)serviceProvider.GetRequiredService(connectorType);
    }
}
'@

# ==============================================================================
# PHASE 2 - FILE SYSTEM
# ==============================================================================

Write-Phase "Phase 2 - FileSystem (3 files)"

New-SourceFile "FileSystem/FileSystemScanner.cs" @'
// <copyright file="FileSystemScanner.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.FileSystem;

using Microsoft.Extensions.Logging;

/// <summary>
/// Scans folders on the local file system and returns matching file paths.
/// This scanner is format-agnostic and works with any file type.
/// Used by connectors and the plugin folder scanner to discover files
/// before they are opened as streams.
/// </summary>
public sealed class FileSystemScanner
{
    /// <summary>
    /// Logger instance for structured scanner diagnostic output.
    /// </summary>
    private readonly ILogger<FileSystemScanner> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="FileSystemScanner"/>.
    /// </summary>
    /// <param name="logger">The logger for scanner operations.</param>
    public FileSystemScanner(ILogger<FileSystemScanner> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Scans <paramref name="folderPath"/> for files matching <paramref name="pattern"/>
    /// and returns their absolute paths in alphabetical order.
    /// </summary>
    /// <param name="folderPath">The full path to the folder to scan.</param>
    /// <param name="pattern">
    /// The file name pattern to match, for example <c>*.json</c> or <c>*.*</c>.
    /// Defaults to <c>*.*</c> when null or empty.
    /// </param>
    /// <param name="recursive">
    /// When <c>true</c> sub-folders are also scanned.
    /// Defaults to <c>false</c>.
    /// </param>
    /// <returns>
    /// An alphabetically ordered enumerable of absolute file paths matching the pattern.
    /// Returns an empty enumerable when the folder does not exist.
    /// </returns>
    public IEnumerable<string> Scan(string folderPath, string? pattern = null, bool recursive = false)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(folderPath);

        if (!Directory.Exists(folderPath))
        {
            logger.LogWarning("Scan folder not found: {FolderPath}", folderPath);
            return Enumerable.Empty<string>();
        }

        var effectivePattern = string.IsNullOrWhiteSpace(pattern) ? "*.*" : pattern;
        var searchOption = recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;

        var files = Directory.GetFiles(folderPath, effectivePattern, searchOption)
            .OrderBy(f => f)
            .ToList();

        logger.LogDebug(
            "Scan complete: {Count} file(s) matching '{Pattern}' in '{Folder}' (recursive: {Recursive})",
            files.Count,
            effectivePattern,
            folderPath,
            recursive);

        return files;
    }

    /// <summary>
    /// Determines whether the specified <paramref name="folderPath"/> exists
    /// and contains at least one file matching <paramref name="pattern"/>.
    /// </summary>
    /// <param name="folderPath">The full path to the folder to check.</param>
    /// <param name="pattern">The file name pattern to match. Defaults to <c>*.*</c>.</param>
    /// <returns><c>true</c> if the folder exists and contains matching files; otherwise <c>false</c>.</returns>
    public bool HasFiles(string folderPath, string? pattern = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(folderPath);

        if (!Directory.Exists(folderPath))
        {
            return false;
        }

        var effectivePattern = string.IsNullOrWhiteSpace(pattern) ? "*.*" : pattern;
        return Directory.EnumerateFiles(folderPath, effectivePattern, SearchOption.TopDirectoryOnly).Any();
    }
}
'@

New-SourceFile "FileSystem/FileSystemWatcher.cs" @'
// <copyright file="FileSystemWatcher.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.FileSystem;

using Microsoft.Extensions.Logging;

/// <summary>
/// Watches a local file system folder for new files and raises events
/// when matching files are detected. This watcher is format-agnostic
/// and works with any file type. Useful for building file-drop conversion
/// workflows where files are processed as soon as they arrive.
/// Implements <see cref="IDisposable"/> - call <see cref="Dispose"/> to
/// stop watching and release resources.
/// </summary>
public sealed class FileSystemWatcher : IDisposable
{
    /// <summary>
    /// Logger instance for watcher diagnostic output.
    /// </summary>
    private readonly ILogger<FileSystemWatcher> logger;

    /// <summary>
    /// The underlying .NET file system watcher instance.
    /// </summary>
    private readonly System.IO.FileSystemWatcher watcher;

    /// <summary>
    /// Raised when a new file matching the configured pattern is detected.
    /// The event argument is the full path of the new file.
    /// </summary>
    public event EventHandler<string>? FileDetected;

    /// <summary>
    /// Gets the folder path currently being watched.
    /// </summary>
    public string WatchedFolder { get; }

    /// <summary>
    /// Gets the file pattern used to filter detected files.
    /// </summary>
    public string FilePattern { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="FileSystemWatcher"/> and starts watching.
    /// </summary>
    /// <param name="logger">The logger for watcher events.</param>
    /// <param name="folderPath">The full path to the folder to watch.</param>
    /// <param name="filePattern">
    /// The file name pattern to watch for, for example <c>*.json</c>.
    /// Defaults to <c>*.*</c>.
    /// </param>
    public FileSystemWatcher(ILogger<FileSystemWatcher> logger, string folderPath, string filePattern = "*.*")
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(folderPath);

        this.logger = logger;
        WatchedFolder = folderPath;
        FilePattern = filePattern;

        watcher = new System.IO.FileSystemWatcher(folderPath, filePattern)
        {
            NotifyFilter = NotifyFilters.FileName | NotifyFilters.CreationTime,
            EnableRaisingEvents = false,
        };

        watcher.Created += OnFileCreated;

        logger.LogDebug(
            "FileSystemWatcher initialised: {Folder} | Pattern: {Pattern}",
            folderPath,
            filePattern);
    }

    /// <summary>
    /// Starts watching the configured folder for new files.
    /// </summary>
    public void Start()
    {
        watcher.EnableRaisingEvents = true;
        logger.LogInformation("File watching started: {Folder}", WatchedFolder);
    }

    /// <summary>
    /// Stops watching the configured folder.
    /// </summary>
    public void Stop()
    {
        watcher.EnableRaisingEvents = false;
        logger.LogInformation("File watching stopped: {Folder}", WatchedFolder);
    }

    /// <summary>
    /// Handles the file created event from the underlying watcher.
    /// </summary>
    /// <param name="sender">The source of the event.</param>
    /// <param name="e">The file system event arguments containing the file path.</param>
    private void OnFileCreated(object sender, FileSystemEventArgs e)
    {
        logger.LogDebug("New file detected: {FilePath}", e.FullPath);
        FileDetected?.Invoke(this, e.FullPath);
    }

    /// <summary>
    /// Releases the underlying file system watcher resources.
    /// </summary>
    public void Dispose()
    {
        watcher.Created -= OnFileCreated;
        watcher.Dispose();
        logger.LogDebug("FileSystemWatcher disposed: {Folder}", WatchedFolder);
    }
}
'@

New-SourceFile "FileSystem/PluginFolderScanner.cs" @'
// <copyright file="PluginFolderScanner.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.FileSystem;

using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;

/// <summary>
/// Scans the configured plugin folder for plugin DLL and manifest file pairs.
/// Returns <see cref="PluginFileSet"/> instances that the Application layer
/// can then load and validate. This scanner does NOT load assemblies or
/// read manifests - those responsibilities belong to the Application layer.
/// </summary>
public sealed class PluginFolderScanner
{
    /// <summary>
    /// Logger instance for scanner diagnostic output.
    /// </summary>
    private readonly ILogger<PluginFolderScanner> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="PluginFolderScanner"/>.
    /// </summary>
    /// <param name="logger">The logger for scanner operations.</param>
    public PluginFolderScanner(ILogger<PluginFolderScanner> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Scans <paramref name="pluginsFolderPath"/> and returns a
    /// <see cref="PluginFileSet"/> for each DLL file that has an accompanying
    /// <c>*.manifest.json</c> file in the same folder.
    /// DLL files without a manifest are logged as warnings and skipped.
    /// </summary>
    /// <param name="pluginsFolderPath">The full path to the plugins folder to scan.</param>
    /// <param name="scanSubFolders">
    /// When <c>true</c> sub-folders are also scanned.
    /// Each sub-folder is treated as a separate plugin folder.
    /// </param>
    /// <returns>
    /// An enumerable of <see cref="PluginFileSet"/> instances for valid plugin pairs.
    /// Returns an empty enumerable when the folder does not exist.
    /// </returns>
    public IEnumerable<PluginFileSet> Scan(string pluginsFolderPath, bool scanSubFolders = true)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(pluginsFolderPath);

        if (!Directory.Exists(pluginsFolderPath))
        {
            logger.LogWarning("Plugin folder not found: {PluginsFolderPath}", pluginsFolderPath);
            return Enumerable.Empty<PluginFileSet>();
        }

        var results = new List<PluginFileSet>();

        // Scan the root plugins folder
        results.AddRange(ScanFolder(pluginsFolderPath));

        // Optionally scan sub-folders (each sub-folder = one plugin)
        if (scanSubFolders)
        {
            foreach (var subFolder in Directory.GetDirectories(pluginsFolderPath))
            {
                results.AddRange(ScanFolder(subFolder));
            }
        }

        logger.LogInformation(
            "Plugin scan complete: {Count} plugin(s) found in '{Folder}'",
            results.Count,
            pluginsFolderPath);

        return results;
    }

    /// <summary>
    /// Scans a single folder for DLL + manifest pairs.
    /// </summary>
    /// <param name="folderPath">The folder path to scan.</param>
    /// <returns>Plugin file sets found in this folder.</returns>
    private IEnumerable<PluginFileSet> ScanFolder(string folderPath)
    {
        var dllFiles = Directory.GetFiles(folderPath, "*.dll", SearchOption.TopDirectoryOnly);

        foreach (var dllPath in dllFiles)
        {
            // Look for matching manifest: AssemblyName.manifest.json
            var assemblyName = Path.GetFileNameWithoutExtension(dllPath);
            var manifestPath = Path.Combine(folderPath, $"{assemblyName}.manifest.json");

            if (!File.Exists(manifestPath))
            {
                logger.LogWarning(
                    "Plugin DLL '{DllPath}' has no accompanying manifest file '{ManifestPath}'. Skipping.",
                    dllPath,
                    manifestPath);
                continue;
            }

            logger.LogDebug(
                "Plugin file pair found: {AssemblyName} in '{Folder}'",
                assemblyName,
                folderPath);

            yield return new PluginFileSet
            {
                AssemblyPath = dllPath,
                ManifestPath = manifestPath,
                PluginFolder = folderPath,
            };
        }
    }
}
'@

# ==============================================================================
# PHASE 3 - LOGGING
# ==============================================================================

Write-Phase "Phase 3 - Logging (2 files)"

New-SourceFile "Logging/SerilogConfiguration.cs" @'
// <copyright file="SerilogConfiguration.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Logging;

using Microsoft.Extensions.Configuration;
using Serilog;
using Serilog.Events;

/// <summary>
/// Configures the Serilog logging pipeline for the Axbus framework.
/// Reads configuration from <c>appsettings.json</c> under the <c>Serilog</c>
/// section and applies sensible defaults when configuration is absent.
/// Default sinks: Console and rolling File (5 MB limit, 10 files retained).
/// </summary>
public static class SerilogConfiguration
{
    /// <summary>
    /// Creates and returns a fully configured <see cref="LoggerConfiguration"/>
    /// based on the provided <paramref name="configuration"/>. Reads the
    /// <c>Serilog</c> section from <c>appsettings.json</c> and enriches
    /// log events with machine name, thread ID and log context properties.
    /// </summary>
    /// <param name="configuration">
    /// The application configuration containing the <c>Serilog</c> section.
    /// </param>
    /// <returns>
    /// A configured <see cref="LoggerConfiguration"/> ready for
    /// <see cref="Log.Logger"/> assignment or hosting integration.
    /// </returns>
    public static LoggerConfiguration Create(IConfiguration configuration)
    {
        ArgumentNullException.ThrowIfNull(configuration);

        return new LoggerConfiguration()
            .ReadFrom.Configuration(configuration)
            .Enrich.FromLogContext()
            .Enrich.WithMachineName()
            .Enrich.WithThreadId()
            .WriteTo.Console(
                outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj} " +
                                "{Properties:j}{NewLine}{Exception}")
            .WriteTo.File(
                path: "logs/axbus-.log",
                rollingInterval: RollingInterval.Day,
                rollOnFileSizeLimit: true,
                fileSizeLimitBytes: 5 * 1024 * 1024, // 5 MB
                retainedFileCountLimit: 10,
                outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff} {Level:u3}] " +
                                "{SourceContext} {Message:lj} " +
                                "{Properties:j}{NewLine}{Exception}");
    }

    /// <summary>
    /// Creates a minimal <see cref="LoggerConfiguration"/> suitable for use
    /// during application bootstrap before the full configuration is loaded.
    /// Writes only to the console at <see cref="LogEventLevel.Information"/> level.
    /// </summary>
    /// <returns>A minimal bootstrap <see cref="LoggerConfiguration"/>.</returns>
    public static LoggerConfiguration CreateBootstrap()
    {
        return new LoggerConfiguration()
            .MinimumLevel.Information()
            .WriteTo.Console(
                outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] BOOTSTRAP {Message:lj}{NewLine}{Exception}");
    }
}
'@

New-SourceFile "Logging/ConversionLogContext.cs" @'
// <copyright file="ConversionLogContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Logging;

using Serilog.Context;

/// <summary>
/// Enriches Serilog log events with Axbus-specific contextual properties.
/// Push properties onto the log context before executing a conversion module
/// or pipeline stage so that all log messages within that scope automatically
/// include the relevant context. Use the returned <see cref="IDisposable"/>
/// in a <c>using</c> block to automatically pop the properties when the scope exits.
/// </summary>
public static class ConversionLogContext
{
    /// <summary>
    /// Pushes the <paramref name="moduleName"/> property onto the Serilog log context.
    /// All log messages emitted within the returned scope will include the
    /// <c>ConversionModule</c> property, making module-level filtering possible
    /// in log analysis tools.
    /// </summary>
    /// <param name="moduleName">The name of the conversion module being executed.</param>
    /// <returns>
    /// An <see cref="IDisposable"/> that removes the property when disposed.
    /// Use in a <c>using</c> statement to scope the enrichment to the module execution.
    /// </returns>
    public static IDisposable PushModule(string moduleName)
    {
        return LogContext.PushProperty("ConversionModule", moduleName);
    }

    /// <summary>
    /// Pushes both <paramref name="moduleName"/> and <paramref name="pluginId"/>
    /// properties onto the Serilog log context. All log messages within the
    /// returned scope will include both <c>ConversionModule</c> and <c>PluginId</c>
    /// properties for detailed pipeline stage tracing.
    /// </summary>
    /// <param name="moduleName">The name of the conversion module being executed.</param>
    /// <param name="pluginId">The identifier of the plugin executing the current stage.</param>
    /// <returns>
    /// An <see cref="IDisposable"/> that removes both properties when disposed.
    /// </returns>
    public static IDisposable PushModuleAndPlugin(string moduleName, string pluginId)
    {
        // Push both properties - each returns a disposable
        // Combine them into a composite disposable via a simple wrapper
        var moduleDisposable = LogContext.PushProperty("ConversionModule", moduleName);
        var pluginDisposable = LogContext.PushProperty("PluginId", pluginId);

        return new CompositeDisposable(moduleDisposable, pluginDisposable);
    }

    /// <summary>
    /// Combines multiple <see cref="IDisposable"/> instances into one.
    /// Disposes all contained disposables when <see cref="Dispose"/> is called.
    /// </summary>
    private sealed class CompositeDisposable : IDisposable
    {
        /// <summary>
        /// The disposables to combine and dispose together.
        /// </summary>
        private readonly IDisposable[] disposables;

        /// <summary>
        /// Initializes a new instance of <see cref="CompositeDisposable"/>.
        /// </summary>
        /// <param name="disposables">The disposables to combine.</param>
        public CompositeDisposable(params IDisposable[] disposables)
        {
            this.disposables = disposables;
        }

        /// <summary>
        /// Disposes all contained disposables in reverse order.
        /// </summary>
        public void Dispose()
        {
            // Dispose in reverse order to mirror push/pop semantics
            for (var i = disposables.Length - 1; i >= 0; i--)
            {
                disposables[i].Dispose();
            }
        }
    }
}
'@

# ==============================================================================
# PHASE 4 - DI EXTENSIONS
# ==============================================================================

Write-Phase "Phase 4 - Extensions (1 file)"

New-SourceFile "Extensions/InfrastructureServiceExtensions.cs" @'
// <copyright file="InfrastructureServiceExtensions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Extensions;

using Axbus.Core.Abstractions.Connectors;
using Axbus.Core.Models.Configuration;
using Axbus.Infrastructure.Connectors;
using Axbus.Infrastructure.FileSystem;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

/// <summary>
/// Provides extension methods for registering all Axbus Infrastructure layer
/// services into the dependency injection container. Call
/// <see cref="AddAxbusInfrastructure"/> from the application bootstrapper
/// after <c>AddAxbusApplication</c> to wire up connectors, file system
/// utilities and the Serilog logging pipeline.
/// </summary>
public static class InfrastructureServiceExtensions
{
    /// <summary>
    /// Registers all Axbus Infrastructure layer services into <paramref name="services"/>.
    /// </summary>
    /// <param name="services">The service collection to register services into.</param>
    /// <param name="configuration">
    /// The application configuration used to bind settings and configure Serilog.
    /// </param>
    /// <returns>The same <paramref name="services"/> instance for fluent chaining.</returns>
    public static IServiceCollection AddAxbusInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        ArgumentNullException.ThrowIfNull(services);
        ArgumentNullException.ThrowIfNull(configuration);

        // Bind root settings if not already bound by Application layer
        services.Configure<AxbusRootSettings>(configuration);

        // Connector factory - resolves source and target connectors by type string
        services.AddSingleton<IConnectorFactory, ConnectorFactory>();

        // Register built-in connector implementations
        // These are resolved by ConnectorFactory using their concrete types
        services.AddTransient<LocalFileSourceConnector>();
        services.AddTransient<LocalFileTargetConnector>();

        // File system utilities
        services.AddSingleton<FileSystemScanner>();
        services.AddSingleton<PluginFolderScanner>();

        return services;
    }
}
'@

# ==============================================================================
# SUMMARY
# ==============================================================================

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "  [DONE] Axbus.Infrastructure - All files generated successfully!" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Files generated:" -ForegroundColor White
Write-Host "    [OK]  3 Connectors" -ForegroundColor Green
Write-Host "    [OK]  3 FileSystem" -ForegroundColor Green
Write-Host "    [OK]  2 Logging" -ForegroundColor Green
Write-Host "    [OK]  1 Extensions" -ForegroundColor Green
Write-Host ""
Write-Host "  Total: 9 source files" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next Steps:" -ForegroundColor Yellow
Write-Host "    1. Save to: scripts/generate-infrastructure.ps1" -ForegroundColor White
Write-Host "    2. Run: PowerShell -ExecutionPolicy Bypass -File .\scripts\generate-infrastructure.ps1" -ForegroundColor White
Write-Host "    3. Build all 3 framework layers together:" -ForegroundColor White
Write-Host "       dotnet build src/framework/Axbus.Infrastructure/Axbus.Infrastructure.csproj" -ForegroundColor White
Write-Host "    4. Verify: 0 errors" -ForegroundColor White
Write-Host "    5. Message 4 generates all 3 plugins" -ForegroundColor White
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
