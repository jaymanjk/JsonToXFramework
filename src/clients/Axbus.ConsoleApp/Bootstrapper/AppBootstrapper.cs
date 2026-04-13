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
[System.Diagnostics.CodeAnalysis.SuppressMessage(
    "Performance",
    "CA1812:Avoid uninstantiated internal classes",
    Justification = "Class is instantiated by DI container via AddHostedService<ConversionHostedService>() in BuildHost method")]
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
