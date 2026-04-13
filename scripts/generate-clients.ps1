# ==============================================================================
# generate-clients.ps1
# Axbus Framework - Client Projects Code Generation Script
# Copyright (c) 2026 Axel Johnson International. All rights reserved.
#
# USAGE:
#   PowerShell -ExecutionPolicy Bypass -File .\scripts\generate-clients.ps1
#
# GENERATES:
#   Axbus.ConsoleApp    (Program.cs + AppBootstrapper)
#   Axbus.WinFormsApp   (Program.cs + AppBootstrapper + FormFactory + Forms + ViewModels)
#
# PREREQUISITES:
#   - All previous generate-*.ps1 scripts must have been run first
#   - Run from the repository root
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptVersion = "1.0.0"
$CompanyName   = "Axel Johnson International"
$CopyrightYear = "2026"

function Write-Banner {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "  Axbus Clients - Code Generation Script v$ScriptVersion" -ForegroundColor Cyan
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
    param([string]$RootPath, [string]$RelativePath, [string]$Content)
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
if (-not (Test-Path "src/framework/Axbus.Core/Axbus.Core.csproj")) {
    Write-Host "  [FAILED] Axbus.Core not found. Run previous generate scripts first." -ForegroundColor Red; exit 1
}

Write-Banner

# ==============================================================================
# CLIENT 1 - AXBUS.CONSOLEAPP
# ==============================================================================

$ConsoleRoot = "src/clients/Axbus.ConsoleApp"

Write-Phase "Client 1 - Axbus.ConsoleApp (2 files)"

New-SourceFile $ConsoleRoot "Bootstrapper/AppBootstrapper.cs" @'
// <copyright file="AppBootstrapper.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.ConsoleApp.Bootstrapper;

using Axbus.Application.Extensions;
using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Abstractions.Notifications;
using Axbus.Core.Models.Notifications;
using Axbus.Infrastructure.Extensions;
using Axbus.Infrastructure.Logging;
using Axbus.Plugin.Reader.Json;
using Axbus.Plugin.Writer.Csv;
using Axbus.Plugin.Writer.Excel;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Serilog;

/// <summary>
/// Bootstraps the Axbus Console application by configuring the .NET Generic Host,
/// registering all framework and plugin services into the DI container,
/// and wiring up Serilog, progress reporting and cancellation.
/// Entry point: <see cref="BuildHost"/> returns a ready-to-run <see cref="IHost"/>.
/// </summary>
public static class AppBootstrapper
{
    /// <summary>
    /// Builds and configures the <see cref="IHost"/> for the console application.
    /// Registers all Axbus framework layers, all three plugins, Serilog logging,
    /// and wires up the console progress reporter and cancellation token source.
    /// </summary>
    /// <param name="args">Command-line arguments passed from <c>Program.cs</c>.</param>
    /// <returns>A fully configured <see cref="IHost"/> ready to call <c>RunAsync</c>.</returns>
    public static IHost BuildHost(string[] args)
    {
        // Bootstrap logger for startup errors before full config is loaded
        Log.Logger = SerilogConfiguration.CreateBootstrap().CreateLogger();

        try
        {
            var host = Host.CreateDefaultBuilder(args)
                .UseSerilog((context, services, loggerConfig) =>
                {
                    // Full Serilog config read from appsettings.json Serilog section
                    SerilogConfiguration.Create(context.Configuration)
                        .ReadFrom.Services(services)
                        .CreateLogger();
                })
                .ConfigureAppConfiguration((context, config) =>
                {
                    // Load appsettings.json and environment-specific overrides
                    config.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
                    config.AddJsonFile(
                        $"appsettings.{context.HostingEnvironment.EnvironmentName}.json",
                        optional: true,
                        reloadOnChange: true);
                    config.AddEnvironmentVariables();
                    config.AddCommandLine(args);
                })
                .ConfigureServices((context, services) =>
                {
                    // Register Axbus Application layer (pipeline, runner, factories)
                    services.AddAxbusApplication(context.Configuration);

                    // Register Axbus Infrastructure layer (connectors, file system, logging)
                    services.AddAxbusInfrastructure(context.Configuration);

                    // Register all plugins - framework controls registration, not plugins
                    services.AddSingleton<Axbus.Core.Abstractions.Plugin.IPlugin, JsonReaderPlugin>();
                    services.AddSingleton<Axbus.Core.Abstractions.Plugin.IPlugin, CsvWriterPlugin>();
                    services.AddSingleton<Axbus.Core.Abstractions.Plugin.IPlugin, ExcelWriterPlugin>();

                    // Register the hosted service that runs the conversion
                    services.AddHostedService<ConversionHostedService>();
                })
                .Build();

            Log.Information("Axbus ConsoleApp host built successfully.");
            return host;
        }
        catch (Exception ex)
        {
            Log.Fatal(ex, "Axbus ConsoleApp failed to start.");
            throw;
        }
    }
}

/// <summary>
/// A .NET Generic Host background service that runs the Axbus conversion runner
/// on application start and exits when all modules have completed or are cancelled.
/// Wires up a console progress reporter and Ctrl+C cancellation.
/// </summary>
internal sealed class ConversionHostedService : BackgroundService
{
    /// <summary>
    /// Logger instance for hosted service lifecycle messages.
    /// </summary>
    private readonly ILogger<ConversionHostedService> logger;

    /// <summary>
    /// The conversion runner that orchestrates all enabled modules.
    /// </summary>
    private readonly IConversionRunner conversionRunner;

    /// <summary>
    /// The event publisher for subscribing to conversion lifecycle events.
    /// </summary>
    private readonly IEventPublisher eventPublisher;

    /// <summary>
    /// The host application lifetime used to signal application stop.
    /// </summary>
    private readonly IHostApplicationLifetime lifetime;

    /// <summary>
    /// Initializes a new instance of <see cref="ConversionHostedService"/>.
    /// </summary>
    /// <param name="logger">Logger for hosted service messages.</param>
    /// <param name="conversionRunner">The conversion runner to execute.</param>
    /// <param name="eventPublisher">The event publisher for lifecycle events.</param>
    /// <param name="lifetime">The host application lifetime.</param>
    public ConversionHostedService(
        ILogger<ConversionHostedService> logger,
        IConversionRunner conversionRunner,
        IEventPublisher eventPublisher,
        IHostApplicationLifetime lifetime)
    {
        this.logger = logger;
        this.conversionRunner = conversionRunner;
        this.eventPublisher = eventPublisher;
        this.lifetime = lifetime;
    }

    /// <summary>
    /// Executes the conversion runner, reports progress to the console,
    /// and prints the final summary on completion.
    /// </summary>
    /// <param name="stoppingToken">Token signalled when the host is stopping.</param>
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("Axbus conversion starting...");

        // Subscribe to event stream for console output
        var subscription = eventPublisher.Events.Subscribe(evt =>
        {
            var level = evt.Exception != null ? "ERROR" : "INFO ";
            Console.WriteLine($"  [{level}] {evt.ModuleName} | {evt.Type} | {evt.Message}");
        });

        // Wire up console progress reporter
        var progress = new Progress<Axbus.Core.Models.Notifications.ConversionProgress>(p =>
        {
            // Write progress to same line for a clean console experience
            Console.Write(
                $"\r  [{p.ModuleName}] {p.Status} | " +
                $"Files: {p.ProcessedFiles}/{p.TotalFiles} | " +
                $"Progress: {p.PercentComplete:F1}%   ");
        });

        try
        {
            var summary = await conversionRunner.RunAsync(progress, stoppingToken)
                .ConfigureAwait(false);

            Console.WriteLine();
            Console.WriteLine();
            Console.WriteLine("  ===============================================================");
            Console.WriteLine("  Axbus Conversion Summary");
            Console.WriteLine("  ===============================================================");
            Console.WriteLine($"  Total modules  : {summary.TotalModules}");
            Console.WriteLine($"  Successful     : {summary.SuccessfulModules}");
            Console.WriteLine($"  Failed         : {summary.FailedModules}");
            Console.WriteLine($"  Skipped        : {summary.SkippedModules}");
            Console.WriteLine($"  Total files    : {summary.TotalFilesProcessed}");
            Console.WriteLine($"  Total rows     : {summary.TotalRowsWritten}");
            Console.WriteLine($"  Error rows     : {summary.TotalErrorRows}");
            Console.WriteLine($"  Duration       : {summary.TotalDuration.TotalSeconds:F2}s");
            Console.WriteLine("  ===============================================================");
            Console.WriteLine();

            foreach (var result in summary.Results)
            {
                var status = result.Status.ToString().PadRight(10);
                Console.WriteLine($"  {status} | {result.ModuleName} | Rows: {result.RowsWritten}");
                if (!string.IsNullOrEmpty(result.OutputFilePath))
                {
                    Console.WriteLine($"             Output: {result.OutputFilePath}");
                }
            }
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine();
            logger.LogWarning("Conversion cancelled by user.");
        }
        catch (Exception ex)
        {
            Console.WriteLine();
            logger.LogError(ex, "Conversion failed with an unhandled exception.");
        }
        finally
        {
            subscription.Dispose();
            // Signal the host to stop after conversion completes
            lifetime.StopApplication();
        }
    }
}
'@

New-SourceFile $ConsoleRoot "Program.cs" @'
// <copyright file="Program.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

using Axbus.ConsoleApp.Bootstrapper;
using Serilog;

// Build and run the Axbus console host.
// All DI wiring, Serilog configuration and plugin registration
// is handled by AppBootstrapper.BuildHost().
// Maximum 15 lines - all complexity lives in AppBootstrapper.

try
{
    var host = AppBootstrapper.BuildHost(args);
    await host.RunAsync();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Axbus ConsoleApp terminated unexpectedly.");
}
finally
{
    await Log.CloseAndFlushAsync();
}
'@

# ==============================================================================
# CLIENT 2 - AXBUS.WINFORMSAPP
# ==============================================================================

$WinFormsRoot = "src/clients/Axbus.WinFormsApp"

Write-Phase "Client 2 - Axbus.WinFormsApp (13 files)"

New-SourceFile $WinFormsRoot "Bootstrapper/FormFactory.cs" @'
// <copyright file="FormFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.Bootstrapper;

using Microsoft.Extensions.DependencyInjection;

/// <summary>
/// A DI-aware factory for creating WinForms <see cref="Form"/> instances.
/// Resolves form instances from the DI container so that all form
/// constructor dependencies are satisfied automatically. Use this factory
/// instead of <c>new FormName()</c> to ensure proper DI integration.
/// Register forms as transient services in <see cref="AppBootstrapper"/>.
/// </summary>
public sealed class FormFactory
{
    /// <summary>
    /// The DI service provider used to resolve form instances.
    /// </summary>
    private readonly IServiceProvider serviceProvider;

    /// <summary>
    /// Initializes a new instance of <see cref="FormFactory"/>.
    /// </summary>
    /// <param name="serviceProvider">The application service provider.</param>
    public FormFactory(IServiceProvider serviceProvider)
    {
        this.serviceProvider = serviceProvider;
    }

    /// <summary>
    /// Creates a new instance of <typeparamref name="TForm"/> by resolving it
    /// from the DI container. All constructor dependencies of the form are
    /// automatically satisfied by the container.
    /// </summary>
    /// <typeparam name="TForm">
    /// The type of form to create. Must be a <see cref="Form"/> subclass
    /// registered in the DI container.
    /// </typeparam>
    /// <returns>A new <typeparamref name="TForm"/> instance with all dependencies injected.</returns>
    /// <exception cref="InvalidOperationException">
    /// Thrown when <typeparamref name="TForm"/> is not registered in the DI container.
    /// </exception>
    public TForm Create<TForm>() where TForm : Form
    {
        return serviceProvider.GetRequiredService<TForm>();
    }
}
'@

New-SourceFile $WinFormsRoot "Bootstrapper/AppBootstrapper.cs" @'
// <copyright file="AppBootstrapper.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.Bootstrapper;

using Axbus.Application.Extensions;
using Axbus.Infrastructure.Extensions;
using Axbus.Infrastructure.Logging;
using Axbus.Plugin.Reader.Json;
using Axbus.Plugin.Writer.Csv;
using Axbus.Plugin.Writer.Excel;
using Axbus.WinFormsApp.Forms;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;

/// <summary>
/// Bootstraps the Axbus WinForms application. Configures the .NET Generic Host,
/// registers all framework services, plugins and WinForms-specific services
/// including the <see cref="FormFactory"/> and all form types.
/// </summary>
public static class AppBootstrapper
{
    /// <summary>
    /// Builds and returns the configured DI <see cref="IServiceProvider"/>
    /// for the WinForms application. Called from <c>Program.cs</c> before
    /// <see cref="Application.Run"/>.
    /// </summary>
    /// <returns>A fully configured <see cref="IServiceProvider"/>.</returns>
    public static IServiceProvider Bootstrap()
    {
        // Bootstrap Serilog before host is built
        Log.Logger = SerilogConfiguration.CreateBootstrap().CreateLogger();

        try
        {
            var configuration = BuildConfiguration();

            // Configure Serilog from appsettings.json
            Log.Logger = SerilogConfiguration.Create(configuration).CreateLogger();

            var services = new ServiceCollection();

            // Logging
            services.AddLogging(builder => builder.AddSerilog(dispose: true));

            // Axbus framework layers
            services.AddAxbusApplication(configuration);
            services.AddAxbusInfrastructure(configuration);

            // Plugins - framework controls registration
            services.AddSingleton<Axbus.Core.Abstractions.Plugin.IPlugin, JsonReaderPlugin>();
            services.AddSingleton<Axbus.Core.Abstractions.Plugin.IPlugin, CsvWriterPlugin>();
            services.AddSingleton<Axbus.Core.Abstractions.Plugin.IPlugin, ExcelWriterPlugin>();

            // WinForms-specific services
            services.AddSingleton<FormFactory>();

            // Register forms as transient so each Create<T>() call gets a new instance
            services.AddTransient<MainForm>();
            services.AddTransient<ProgressForm>();
            services.AddTransient<SummaryForm>();

            Log.Information("Axbus WinFormsApp bootstrapped successfully.");

            return services.BuildServiceProvider();
        }
        catch (Exception ex)
        {
            Log.Fatal(ex, "Axbus WinFormsApp failed to bootstrap.");
            throw;
        }
    }

    /// <summary>
    /// Builds the application configuration from appsettings.json files
    /// and environment variables.
    /// </summary>
    /// <returns>The built <see cref="IConfiguration"/>.</returns>
    private static IConfiguration BuildConfiguration()
    {
        var environment = Environment.GetEnvironmentVariable("DOTNET_ENVIRONMENT")
            ?? "Production";

        return new ConfigurationBuilder()
            .SetBasePath(AppContext.BaseDirectory)
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
            .AddJsonFile($"appsettings.{environment}.json", optional: true, reloadOnChange: false)
            .AddEnvironmentVariables()
            .Build();
    }
}
'@

New-SourceFile $WinFormsRoot "ViewModels/ConversionModuleViewModel.cs" @'
// <copyright file="ConversionModuleViewModel.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.ViewModels;

using Axbus.Core.Enums;
using Axbus.Core.Models.Configuration;

/// <summary>
/// View model that wraps a <see cref="ConversionModule"/> for display
/// in the main form module list. Exposes display-friendly properties
/// for binding to WinForms controls such as DataGridView.
/// </summary>
public sealed class ConversionModuleViewModel
{
    /// <summary>Gets the underlying conversion module configuration.</summary>
    public ConversionModule Module { get; }

    /// <summary>Gets the unique name of the conversion module.</summary>
    public string ConversionName => Module.ConversionName;

    /// <summary>Gets the description of the conversion module.</summary>
    public string Description => Module.Description;

    /// <summary>Gets a value indicating whether this module is enabled.</summary>
    public bool IsEnabled => Module.IsEnabled;

    /// <summary>Gets the source format identifier (e.g. json).</summary>
    public string SourceFormat => Module.SourceFormat;

    /// <summary>Gets the target format identifier (e.g. csv).</summary>
    public string TargetFormat => Module.TargetFormat;

    /// <summary>Gets or sets the current execution status of this module.</summary>
    public ConversionStatus Status { get; set; } = ConversionStatus.NotStarted;

    /// <summary>Gets a display-friendly status string for the module.</summary>
    public string StatusDisplay => Status.ToString();

    /// <summary>
    /// Initializes a new instance of <see cref="ConversionModuleViewModel"/>.
    /// </summary>
    /// <param name="module">The conversion module to wrap.</param>
    public ConversionModuleViewModel(ConversionModule module)
    {
        ArgumentNullException.ThrowIfNull(module);
        Module = module;
    }
}
'@

New-SourceFile $WinFormsRoot "ViewModels/ProgressViewModel.cs" @'
// <copyright file="ProgressViewModel.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.ViewModels;

using Axbus.Core.Enums;
using Axbus.Core.Models.Notifications;

/// <summary>
/// View model that maps <see cref="ConversionProgress"/> updates to
/// WinForms control properties. Designed for binding to a ProgressBar,
/// status label and current file label in the progress form.
/// </summary>
public sealed class ProgressViewModel
{
    /// <summary>Gets or sets the name of the module currently executing.</summary>
    public string ModuleName { get; set; } = string.Empty;

    /// <summary>Gets or sets the percentage complete as an integer 0-100 for ProgressBar.Value.</summary>
    public int PercentComplete { get; set; }

    /// <summary>Gets or sets the current file being processed.</summary>
    public string CurrentFile { get; set; } = string.Empty;

    /// <summary>Gets or sets the current conversion status.</summary>
    public ConversionStatus Status { get; set; }

    /// <summary>Gets or sets the total number of files to process.</summary>
    public int TotalFiles { get; set; }

    /// <summary>Gets or sets the number of files processed so far.</summary>
    public int ProcessedFiles { get; set; }

    /// <summary>Gets a display string combining file progress counts.</summary>
    public string FileProgressDisplay => $"Files: {ProcessedFiles} / {TotalFiles}";

    /// <summary>Gets a display string for the status label.</summary>
    public string StatusDisplay => $"{ModuleName} - {Status}";

    /// <summary>
    /// Updates all properties from a <see cref="ConversionProgress"/> notification.
    /// </summary>
    /// <param name="progress">The progress notification to apply.</param>
    public void UpdateFrom(ConversionProgress progress)
    {
        ArgumentNullException.ThrowIfNull(progress);
        ModuleName = progress.ModuleName;
        PercentComplete = (int)Math.Clamp(progress.PercentComplete, 0, 100);
        CurrentFile = progress.CurrentFile;
        Status = progress.Status;
        TotalFiles = progress.TotalFiles;
        ProcessedFiles = progress.ProcessedFiles;
    }
}
'@

New-SourceFile $WinFormsRoot "ViewModels/ModuleResultViewModel.cs" @'
// <copyright file="ModuleResultViewModel.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.ViewModels;

using Axbus.Core.Enums;
using Axbus.Core.Models.Results;

/// <summary>
/// View model that wraps a <see cref="ModuleResult"/> for display
/// in the summary form results grid. Exposes display-friendly
/// properties for DataGridView column binding.
/// </summary>
public sealed class ModuleResultViewModel
{
    /// <summary>Gets the underlying module result.</summary>
    public ModuleResult Result { get; }

    /// <summary>Gets the name of the conversion module.</summary>
    public string ModuleName => Result.ModuleName;

    /// <summary>Gets the final status of the module as a display string.</summary>
    public string Status => Result.Status.ToString();

    /// <summary>Gets the number of rows successfully written.</summary>
    public int RowsWritten => Result.RowsWritten;

    /// <summary>Gets the number of rows written to the error file.</summary>
    public int ErrorRows => Result.ErrorRowsWritten;

    /// <summary>Gets the total duration formatted as seconds with 2 decimal places.</summary>
    public string Duration => $"{Result.Duration.TotalSeconds:F2}s";

    /// <summary>Gets the primary output file path.</summary>
    public string OutputPath => Result.OutputFilePath;

    /// <summary>Gets whether the module completed successfully.</summary>
    public bool IsSuccess => Result.Status == ConversionStatus.Completed;

    /// <summary>
    /// Initializes a new instance of <see cref="ModuleResultViewModel"/>.
    /// </summary>
    /// <param name="result">The module result to wrap.</param>
    public ModuleResultViewModel(ModuleResult result)
    {
        ArgumentNullException.ThrowIfNull(result);
        Result = result;
    }
}
'@

New-SourceFile $WinFormsRoot "ViewModels/ConversionSummaryViewModel.cs" @'
// <copyright file="ConversionSummaryViewModel.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.ViewModels;

using Axbus.Core.Models.Results;

/// <summary>
/// View model wrapping a <see cref="ConversionSummary"/> for display
/// in the summary form. Exposes display-friendly aggregate statistics
/// and a bindable list of per-module result view models.
/// </summary>
public sealed class ConversionSummaryViewModel
{
    /// <summary>Gets the underlying conversion summary.</summary>
    public ConversionSummary Summary { get; }

    /// <summary>Gets the total number of modules configured.</summary>
    public int TotalModules => Summary.TotalModules;

    /// <summary>Gets the number of modules that completed successfully.</summary>
    public int SuccessfulModules => Summary.SuccessfulModules;

    /// <summary>Gets the number of modules that failed.</summary>
    public int FailedModules => Summary.FailedModules;

    /// <summary>Gets the number of modules that were skipped.</summary>
    public int SkippedModules => Summary.SkippedModules;

    /// <summary>Gets the total number of rows written across all modules.</summary>
    public int TotalRowsWritten => Summary.TotalRowsWritten;

    /// <summary>Gets the total number of error rows across all modules.</summary>
    public int TotalErrorRows => Summary.TotalErrorRows;

    /// <summary>Gets the total duration formatted as seconds with 2 decimal places.</summary>
    public string TotalDuration => $"{Summary.TotalDuration.TotalSeconds:F2}s";

    /// <summary>Gets a display string indicating overall pass or fail.</summary>
    public string OverallStatus => Summary.FailedModules == 0 ? "Completed Successfully" : "Completed with Errors";

    /// <summary>Gets the per-module result view models for the results grid.</summary>
    public IReadOnlyList<ModuleResultViewModel> ModuleResults { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="ConversionSummaryViewModel"/>.
    /// </summary>
    /// <param name="summary">The conversion summary to wrap.</param>
    public ConversionSummaryViewModel(ConversionSummary summary)
    {
        ArgumentNullException.ThrowIfNull(summary);
        Summary = summary;
        ModuleResults = summary.Results
            .Select(r => new ModuleResultViewModel(r))
            .ToList()
            .AsReadOnly();
    }
}
'@

New-SourceFile $WinFormsRoot "ViewModels/PluginInfoViewModel.cs" @'
// <copyright file="PluginInfoViewModel.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.ViewModels;

using Axbus.Core.Abstractions.Plugin;

/// <summary>
/// View model that exposes loaded plugin information for display in a
/// plugin info panel or about dialog. Wraps an <see cref="IPlugin"/>
/// instance with display-friendly properties.
/// </summary>
public sealed class PluginInfoViewModel
{
    /// <summary>Gets the plugin's unique identifier.</summary>
    public string PluginId { get; }

    /// <summary>Gets the plugin's display name.</summary>
    public string Name { get; }

    /// <summary>Gets the plugin's version as a display string.</summary>
    public string Version { get; }

    /// <summary>Gets the pipeline capabilities as a comma-separated display string.</summary>
    public string Capabilities { get; }

    /// <summary>Gets the minimum framework version required by this plugin.</summary>
    public string MinFrameworkVersion { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="PluginInfoViewModel"/>
    /// from a loaded <see cref="IPlugin"/> instance.
    /// </summary>
    /// <param name="plugin">The loaded plugin to wrap.</param>
    public PluginInfoViewModel(IPlugin plugin)
    {
        ArgumentNullException.ThrowIfNull(plugin);
        PluginId = plugin.PluginId;
        Name = plugin.Name;
        Version = plugin.Version.ToString();
        Capabilities = plugin.Capabilities.ToString();
        MinFrameworkVersion = plugin.MinFrameworkVersion.ToString();
    }
}
'@

New-SourceFile $WinFormsRoot "ViewModels/ErrorViewModel.cs" @'
// <copyright file="ErrorViewModel.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.ViewModels;

/// <summary>
/// View model representing a single error entry for display in an error
/// list or log panel within the WinForms application. Used to surface
/// module and row-level errors collected during conversion execution.
/// </summary>
public sealed class ErrorViewModel
{
    /// <summary>Gets the timestamp at which the error occurred.</summary>
    public DateTime Timestamp { get; }

    /// <summary>Gets the name of the conversion module where the error occurred.</summary>
    public string ModuleName { get; }

    /// <summary>Gets the human-readable error message.</summary>
    public string Message { get; }

    /// <summary>Gets the optional file name associated with the error.</summary>
    public string? FileName { get; }

    /// <summary>Gets the exception type name if an exception caused this error, or empty string.</summary>
    public string ExceptionType { get; }

    /// <summary>Gets a display-friendly timestamp string.</summary>
    public string TimestampDisplay => Timestamp.ToString("HH:mm:ss.fff");

    /// <summary>
    /// Initializes a new instance of <see cref="ErrorViewModel"/>.
    /// </summary>
    /// <param name="moduleName">The module where the error occurred.</param>
    /// <param name="message">The error message.</param>
    /// <param name="fileName">Optional file name associated with the error.</param>
    /// <param name="exception">Optional exception that caused the error.</param>
    public ErrorViewModel(
        string moduleName,
        string message,
        string? fileName = null,
        Exception? exception = null)
    {
        Timestamp = DateTime.Now;
        ModuleName = moduleName;
        Message = message;
        FileName = fileName;
        ExceptionType = exception?.GetType().Name ?? string.Empty;
    }
}
'@

New-SourceFile $WinFormsRoot "Forms/ProgressForm.cs" @'
// <copyright file="ProgressForm.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.Forms;

using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Abstractions.Notifications;
using Axbus.Core.Models.Notifications;
using Axbus.Core.Models.Results;
using Axbus.WinFormsApp.ViewModels;
using Microsoft.Extensions.Logging;

/// <summary>
/// Displays real-time conversion progress including a progress bar,
/// current module status, current file name and a live event log.
/// Runs the conversion asynchronously and allows the user to cancel
/// via a Cancel button. Shows the <see cref="SummaryForm"/> on completion.
/// </summary>
public sealed class ProgressForm : Form
{
    /// <summary>Logger for progress form diagnostic output.</summary>
    private readonly ILogger<ProgressForm> logger;

    /// <summary>The conversion runner that executes all modules.</summary>
    private readonly IConversionRunner conversionRunner;

    /// <summary>The event publisher for subscribing to lifecycle events.</summary>
    private readonly IEventPublisher eventPublisher;

    /// <summary>The factory used to create the summary form on completion.</summary>
    private readonly Bootstrapper.FormFactory formFactory;

    /// <summary>View model tracking current progress state.</summary>
    private readonly ProgressViewModel progressViewModel = new();

    /// <summary>Cancellation token source wired to the Cancel button.</summary>
    private CancellationTokenSource cancellationTokenSource = new();

    // Controls
    private ProgressBar progressBar = null!;
    private Label labelStatus = null!;
    private Label labelCurrentFile = null!;
    private Label labelFileProgress = null!;
    private ListBox listBoxEvents = null!;
    private Button buttonCancel = null!;

    /// <summary>
    /// Initializes a new instance of <see cref="ProgressForm"/>.
    /// </summary>
    /// <param name="logger">The logger for form operations.</param>
    /// <param name="conversionRunner">The conversion runner to execute.</param>
    /// <param name="eventPublisher">The event publisher for live event log.</param>
    /// <param name="formFactory">Factory for creating the summary form.</param>
    public ProgressForm(
        ILogger<ProgressForm> logger,
        IConversionRunner conversionRunner,
        IEventPublisher eventPublisher,
        Bootstrapper.FormFactory formFactory)
    {
        this.logger = logger;
        this.conversionRunner = conversionRunner;
        this.eventPublisher = eventPublisher;
        this.formFactory = formFactory;

        InitialiseComponents();
    }

    /// <summary>
    /// Initialises all WinForms controls and wires up event handlers.
    /// </summary>
    private void InitialiseComponents()
    {
        Text = "Axbus - Conversion Progress";
        Size = new Size(800, 500);
        StartPosition = FormStartPosition.CenterScreen;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;

        // Status label
        labelStatus = new Label
        {
            Location = new Point(12, 12),
            Size = new Size(760, 20),
            Text = "Initialising...",
            Font = new Font("Segoe UI", 9f, FontStyle.Bold),
        };

        // Progress bar
        progressBar = new ProgressBar
        {
            Location = new Point(12, 40),
            Size = new Size(760, 23),
            Minimum = 0,
            Maximum = 100,
            Style = ProgressBarStyle.Continuous,
        };

        // File progress label
        labelFileProgress = new Label
        {
            Location = new Point(12, 70),
            Size = new Size(300, 18),
            Text = "Files: 0 / 0",
        };

        // Current file label
        labelCurrentFile = new Label
        {
            Location = new Point(12, 90),
            Size = new Size(760, 18),
            Text = string.Empty,
            ForeColor = Color.DimGray,
        };

        // Event log list
        listBoxEvents = new ListBox
        {
            Location = new Point(12, 118),
            Size = new Size(760, 300),
            Font = new Font("Consolas", 8.5f),
            HorizontalScrollbar = true,
            SelectionMode = SelectionMode.None,
        };

        // Cancel button
        buttonCancel = new Button
        {
            Location = new Point(697, 430),
            Size = new Size(75, 28),
            Text = "Cancel",
            DialogResult = DialogResult.Cancel,
        };
        buttonCancel.Click += OnCancelClicked;

        Controls.AddRange(new Control[]
        {
            labelStatus, progressBar, labelFileProgress,
            labelCurrentFile, listBoxEvents, buttonCancel,
        });

        Shown += OnFormShown;
    }

    /// <summary>
    /// Starts the conversion run when the form is first shown.
    /// </summary>
    private async void OnFormShown(object? sender, EventArgs e)
    {
        await RunConversionAsync().ConfigureAwait(false);
    }

    /// <summary>
    /// Executes the conversion runner, updating the UI via progress and event callbacks.
    /// </summary>
    private async Task RunConversionAsync()
    {
        cancellationTokenSource = new CancellationTokenSource();

        // Subscribe to event stream - marshal to UI thread
        var subscription = eventPublisher.Events.Subscribe(evt =>
        {
            if (InvokeRequired)
            {
                Invoke(() => AppendEvent(evt));
            }
            else
            {
                AppendEvent(evt);
            }
        });

        // Wire up progress reporter - marshals to UI thread via Progress<T>
        var progress = new Progress<ConversionProgress>(p =>
        {
            progressViewModel.UpdateFrom(p);
            progressBar.Value = progressViewModel.PercentComplete;
            labelStatus.Text = progressViewModel.StatusDisplay;
            labelCurrentFile.Text = progressViewModel.CurrentFile;
            labelFileProgress.Text = progressViewModel.FileProgressDisplay;
        });

        ConversionSummary? summary = null;

        try
        {
            summary = await conversionRunner.RunAsync(progress, cancellationTokenSource.Token)
                .ConfigureAwait(true); // ConfigureAwait(true) to return to UI thread
        }
        catch (OperationCanceledException)
        {
            labelStatus.Text = "Conversion cancelled.";
            logger.LogWarning("Conversion cancelled by user via ProgressForm.");
        }
        catch (Exception ex)
        {
            labelStatus.Text = "Conversion failed. See log for details.";
            logger.LogError(ex, "Conversion failed in ProgressForm.");
            MessageBox.Show(
                $"Conversion failed:\n{ex.Message}",
                "Axbus - Error",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
        finally
        {
            subscription.Dispose();
            buttonCancel.Text = "Close";
        }

        // Show summary form if conversion completed
        if (summary != null)
        {
            var summaryForm = formFactory.Create<SummaryForm>();
            summaryForm.SetSummary(summary);
            Hide();
            summaryForm.ShowDialog(Owner);
            Close();
        }
    }

    /// <summary>
    /// Appends a conversion event to the live event log list box.
    /// </summary>
    /// <param name="evt">The conversion event to append.</param>
    private void AppendEvent(ConversionEvent evt)
    {
        var entry = $"[{evt.Timestamp:HH:mm:ss}] {evt.Type,-25} {evt.ModuleName} | {evt.Message}";
        listBoxEvents.Items.Add(entry);

        // Auto-scroll to latest entry
        if (listBoxEvents.Items.Count > 0)
        {
            listBoxEvents.TopIndex = listBoxEvents.Items.Count - 1;
        }
    }

    /// <summary>
    /// Cancels the running conversion when the Cancel button is clicked.
    /// </summary>
    private void OnCancelClicked(object? sender, EventArgs e)
    {
        if (!cancellationTokenSource.IsCancellationRequested)
        {
            cancellationTokenSource.Cancel();
            buttonCancel.Enabled = false;
            labelStatus.Text = "Cancelling...";
        }
        else
        {
            Close();
        }
    }
}
'@

New-SourceFile $WinFormsRoot "Forms/SummaryForm.cs" @'
// <copyright file="SummaryForm.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.Forms;

using Axbus.Core.Models.Results;
using Axbus.WinFormsApp.ViewModels;

/// <summary>
/// Displays the final <see cref="ConversionSummary"/> after all modules
/// have completed. Shows aggregate statistics (total modules, rows written,
/// duration) and a per-module results grid with output file paths.
/// </summary>
public sealed class SummaryForm : Form
{
    // Aggregate stat labels
    private Label labelOverallStatus = null!;
    private Label labelTotalModules = null!;
    private Label labelSuccessful = null!;
    private Label labelFailed = null!;
    private Label labelTotalRows = null!;
    private Label labelErrorRows = null!;
    private Label labelDuration = null!;

    // Per-module results grid
    private DataGridView gridResults = null!;

    // Close button
    private Button buttonClose = null!;

    /// <summary>
    /// Initializes a new instance of <see cref="SummaryForm"/>.
    /// </summary>
    public SummaryForm()
    {
        InitialiseComponents();
    }

    /// <summary>
    /// Populates the form with data from the provided <see cref="ConversionSummary"/>.
    /// Call this before <see cref="Form.ShowDialog()"/>.
    /// </summary>
    /// <param name="summary">The conversion summary to display.</param>
    public void SetSummary(ConversionSummary summary)
    {
        ArgumentNullException.ThrowIfNull(summary);

        var vm = new ConversionSummaryViewModel(summary);

        labelOverallStatus.Text = vm.OverallStatus;
        labelOverallStatus.ForeColor = summary.FailedModules == 0 ? Color.DarkGreen : Color.DarkRed;
        labelTotalModules.Text = $"Total modules : {vm.TotalModules}";
        labelSuccessful.Text   = $"Successful    : {vm.SuccessfulModules}";
        labelFailed.Text       = $"Failed        : {vm.FailedModules}";
        labelTotalRows.Text    = $"Rows written  : {vm.TotalRowsWritten}";
        labelErrorRows.Text    = $"Error rows    : {vm.TotalErrorRows}";
        labelDuration.Text     = $"Duration      : {vm.TotalDuration}";

        // Bind per-module results to grid
        gridResults.DataSource = vm.ModuleResults
            .Select(r => new
            {
                r.ModuleName,
                r.Status,
                r.RowsWritten,
                r.ErrorRows,
                r.Duration,
                r.OutputPath,
            })
            .ToList();

        gridResults.AutoResizeColumns();
    }

    /// <summary>Initialises all WinForms controls.</summary>
    private void InitialiseComponents()
    {
        Text = "Axbus - Conversion Summary";
        Size = new Size(900, 520);
        StartPosition = FormStartPosition.CenterScreen;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;

        var panelStats = new Panel
        {
            Location = new Point(12, 12),
            Size = new Size(860, 130),
            BorderStyle = BorderStyle.FixedSingle,
        };

        labelOverallStatus = new Label
        {
            Location = new Point(6, 6),
            Size = new Size(840, 24),
            Font = new Font("Segoe UI", 11f, FontStyle.Bold),
            Text = "Completed",
        };

        var statFont = new Font("Consolas", 9f);

        labelTotalModules = new Label { Location = new Point(6, 35),  Size = new Size(280, 18), Font = statFont };
        labelSuccessful   = new Label { Location = new Point(6, 53),  Size = new Size(280, 18), Font = statFont };
        labelFailed       = new Label { Location = new Point(6, 71),  Size = new Size(280, 18), Font = statFont };
        labelTotalRows    = new Label { Location = new Point(300, 35), Size = new Size(280, 18), Font = statFont };
        labelErrorRows    = new Label { Location = new Point(300, 53), Size = new Size(280, 18), Font = statFont };
        labelDuration     = new Label { Location = new Point(300, 71), Size = new Size(280, 18), Font = statFont };

        panelStats.Controls.AddRange(new Control[]
        {
            labelOverallStatus, labelTotalModules, labelSuccessful, labelFailed,
            labelTotalRows, labelErrorRows, labelDuration,
        });

        gridResults = new DataGridView
        {
            Location = new Point(12, 155),
            Size = new Size(860, 290),
            ReadOnly = true,
            AllowUserToAddRows = false,
            AllowUserToDeleteRows = false,
            SelectionMode = DataGridViewSelectionMode.FullRowSelect,
            AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
            RowHeadersVisible = false,
            BackgroundColor = Color.White,
        };

        buttonClose = new Button
        {
            Location = new Point(797, 455),
            Size = new Size(75, 28),
            Text = "Close",
            DialogResult = DialogResult.OK,
        };

        Controls.AddRange(new Control[] { panelStats, gridResults, buttonClose });
        AcceptButton = buttonClose;
    }
}
'@

New-SourceFile $WinFormsRoot "Forms/MainForm.cs" @'
// <copyright file="MainForm.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.Forms;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Models.Configuration;
using Axbus.WinFormsApp.Bootstrapper;
using Axbus.WinFormsApp.ViewModels;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

/// <summary>
/// The main application form. Displays the list of configured conversion modules,
/// shows loaded plugin information, and provides Start and Exit buttons.
/// Clicking Start launches the <see cref="ProgressForm"/> which runs the conversion.
/// </summary>
public sealed class MainForm : Form
{
    /// <summary>Logger for main form operations.</summary>
    private readonly ILogger<MainForm> logger;

    /// <summary>Axbus root settings containing the module list.</summary>
    private readonly AxbusRootSettings settings;

    /// <summary>All registered plugins for the plugin info panel.</summary>
    private readonly IEnumerable<IPlugin> plugins;

    /// <summary>Factory for creating child forms via DI.</summary>
    private readonly FormFactory formFactory;

    // Controls
    private DataGridView gridModules = null!;
    private ListBox listBoxPlugins = null!;
    private Button buttonStart = null!;
    private Button buttonExit = null!;
    private Label labelModules = null!;
    private Label labelPlugins = null!;
    private StatusStrip statusStrip = null!;
    private ToolStripStatusLabel statusLabel = null!;

    /// <summary>
    /// Initializes a new instance of <see cref="MainForm"/>.
    /// </summary>
    /// <param name="logger">The logger for form operations.</param>
    /// <param name="options">Root Axbus settings.</param>
    /// <param name="plugins">All registered plugins.</param>
    /// <param name="formFactory">DI-aware form factory.</param>
    public MainForm(
        ILogger<MainForm> logger,
        IOptions<AxbusRootSettings> options,
        IEnumerable<IPlugin> plugins,
        FormFactory formFactory)
    {
        this.logger = logger;
        this.settings = options.Value;
        this.plugins = plugins;
        this.formFactory = formFactory;

        InitialiseComponents();
        PopulateModuleGrid();
        PopulatePluginList();
    }

    /// <summary>Initialises all WinForms controls and layout.</summary>
    private void InitialiseComponents()
    {
        Text = "Axbus Framework - Data Conversion Tool";
        Size = new Size(1000, 620);
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(900, 560);

        labelModules = new Label
        {
            Text = "Conversion Modules",
            Location = new Point(12, 10),
            Size = new Size(640, 18),
            Font = new Font("Segoe UI", 9f, FontStyle.Bold),
        };

        gridModules = new DataGridView
        {
            Location = new Point(12, 30),
            Size = new Size(640, 500),
            ReadOnly = true,
            AllowUserToAddRows = false,
            AllowUserToDeleteRows = false,
            SelectionMode = DataGridViewSelectionMode.FullRowSelect,
            AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
            RowHeadersVisible = false,
            BackgroundColor = Color.White,
            Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Bottom,
        };

        labelPlugins = new Label
        {
            Text = "Loaded Plugins",
            Location = new Point(665, 10),
            Size = new Size(300, 18),
            Font = new Font("Segoe UI", 9f, FontStyle.Bold),
        };

        listBoxPlugins = new ListBox
        {
            Location = new Point(665, 30),
            Size = new Size(300, 200),
            Font = new Font("Consolas", 8.5f),
        };

        buttonStart = new Button
        {
            Location = new Point(665, 250),
            Size = new Size(140, 35),
            Text = "Start Conversion",
            Font = new Font("Segoe UI", 9f, FontStyle.Bold),
            BackColor = Color.FromArgb(0, 120, 212),
            ForeColor = Color.White,
            FlatStyle = FlatStyle.Flat,
        };
        buttonStart.Click += OnStartClicked;

        buttonExit = new Button
        {
            Location = new Point(825, 250),
            Size = new Size(140, 35),
            Text = "Exit",
            Font = new Font("Segoe UI", 9f),
        };
        buttonExit.Click += (_, _) => Close();

        statusStrip = new StatusStrip();
        statusLabel = new ToolStripStatusLabel("Ready");
        statusStrip.Items.Add(statusLabel);

        Controls.AddRange(new Control[]
        {
            labelModules, gridModules,
            labelPlugins, listBoxPlugins,
            buttonStart, buttonExit,
            statusStrip,
        });
    }

    /// <summary>Populates the module grid from the settings.</summary>
    private void PopulateModuleGrid()
    {
        var viewModels = settings.ConversionModules
            .Select(m => new ConversionModuleViewModel(m))
            .ToList();

        gridModules.DataSource = viewModels
            .Select(vm => new
            {
                vm.ConversionName,
                vm.Description,
                Enabled = vm.IsEnabled ? "Yes" : "No",
                Source = vm.SourceFormat,
                Target = vm.TargetFormat,
                vm.StatusDisplay,
            })
            .ToList();

        gridModules.AutoResizeColumns();

        statusLabel.Text = $"Ready - {viewModels.Count} module(s) configured | " +
                           $"{viewModels.Count(v => v.IsEnabled)} enabled";
    }

    /// <summary>Populates the plugin list from registered plugins.</summary>
    private void PopulatePluginList()
    {
        foreach (var plugin in plugins)
        {
            listBoxPlugins.Items.Add($"{plugin.Name} v{plugin.Version}");
        }
    }

    /// <summary>Launches the progress form when Start is clicked.</summary>
    private void OnStartClicked(object? sender, EventArgs e)
    {
        logger.LogInformation("Conversion started from MainForm.");
        buttonStart.Enabled = false;
        statusLabel.Text = "Conversion running...";

        try
        {
            var progressForm = formFactory.Create<ProgressForm>();
            progressForm.Owner = this;
            progressForm.FormClosed += (_, _) =>
            {
                buttonStart.Enabled = true;
                statusLabel.Text = "Ready";
                PopulateModuleGrid();
            };
            progressForm.Show(this);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to open ProgressForm.");
            buttonStart.Enabled = true;
            statusLabel.Text = "Error - see log";
            MessageBox.Show(
                $"Failed to start conversion:\n{ex.Message}",
                "Axbus - Error",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
    }
}
'@

New-SourceFile $WinFormsRoot "Program.cs" @'
// <copyright file="Program.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

using Axbus.WinFormsApp.Bootstrapper;
using Axbus.WinFormsApp.Forms;
using Serilog;

// Enable per-monitor DPI awareness for sharp rendering on high-DPI displays
Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
Application.EnableVisualStyles();
Application.SetCompatibleTextRenderingDefault(false);

// Bootstrap DI container - all wiring lives in AppBootstrapper
IServiceProvider? serviceProvider = null;

try
{
    serviceProvider = AppBootstrapper.Bootstrap();

    // Resolve FormFactory from DI and create the main form
    var formFactory = serviceProvider.GetService(typeof(FormFactory)) as FormFactory
        ?? throw new InvalidOperationException("FormFactory not registered.");

    var mainForm = formFactory.Create<MainForm>();

    // Run the WinForms message loop
    Application.Run(mainForm);
}
catch (Exception ex)
{
    Log.Fatal(ex, "Axbus WinFormsApp terminated unexpectedly.");
    MessageBox.Show(
        $"Axbus failed to start:\n\n{ex.Message}",
        "Axbus - Fatal Error",
        MessageBoxButtons.OK,
        MessageBoxIcon.Error);
}
finally
{
    // Dispose the service provider if it supports it
    if (serviceProvider is IDisposable disposable)
    {
        disposable.Dispose();
    }

    await Log.CloseAndFlushAsync();
}
'@

# ==============================================================================
# SUMMARY
# ==============================================================================

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "  [DONE] Axbus Clients - All files generated successfully!" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Axbus.ConsoleApp (2 files):" -ForegroundColor White
Write-Host "    [OK] Bootstrapper/AppBootstrapper.cs" -ForegroundColor Green
Write-Host "    [OK] Program.cs" -ForegroundColor Green
Write-Host ""
Write-Host "  Axbus.WinFormsApp (11 files):" -ForegroundColor White
Write-Host "    [OK] Bootstrapper/FormFactory.cs" -ForegroundColor Green
Write-Host "    [OK] Bootstrapper/AppBootstrapper.cs" -ForegroundColor Green
Write-Host "    [OK] ViewModels/ConversionModuleViewModel.cs" -ForegroundColor Green
Write-Host "    [OK] ViewModels/ProgressViewModel.cs" -ForegroundColor Green
Write-Host "    [OK] ViewModels/ModuleResultViewModel.cs" -ForegroundColor Green
Write-Host "    [OK] ViewModels/ConversionSummaryViewModel.cs" -ForegroundColor Green
Write-Host "    [OK] ViewModels/PluginInfoViewModel.cs" -ForegroundColor Green
Write-Host "    [OK] ViewModels/ErrorViewModel.cs" -ForegroundColor Green
Write-Host "    [OK] Forms/ProgressForm.cs" -ForegroundColor Green
Write-Host "    [OK] Forms/SummaryForm.cs" -ForegroundColor Green
Write-Host "    [OK] Forms/MainForm.cs" -ForegroundColor Green
Write-Host "    [OK] Program.cs" -ForegroundColor Green
Write-Host ""
Write-Host "  Total: 13 source files across 2 client projects" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next Steps:" -ForegroundColor Yellow
Write-Host "    1. Save to: scripts/generate-clients.ps1" -ForegroundColor White
Write-Host "    2. Run: PowerShell -ExecutionPolicy Bypass -File .\scripts\generate-clients.ps1" -ForegroundColor White
Write-Host "    3. Build ConsoleApp:" -ForegroundColor White
Write-Host "       dotnet build src/clients/Axbus.ConsoleApp" -ForegroundColor White
Write-Host "    4. Build WinFormsApp:" -ForegroundColor White
Write-Host "       dotnet build src/clients/Axbus.WinFormsApp" -ForegroundColor White
Write-Host "    5. Verify: 0 errors across both clients" -ForegroundColor White
Write-Host "    6. Message 6 generates all test projects" -ForegroundColor White
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
