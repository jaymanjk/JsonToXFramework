// <copyright file="SerilogConfiguration.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Logging;

using System.Globalization;
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
                                "{Properties:j}{NewLine}{Exception}",
                formatProvider: CultureInfo.InvariantCulture)
            .WriteTo.File(
                path: "logs/axbus-.log",
                rollingInterval: RollingInterval.Day,
                rollOnFileSizeLimit: true,
                fileSizeLimitBytes: 5 * 1024 * 1024, // 5 MB
                retainedFileCountLimit: 10,
                outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss.fff} {Level:u3}] " +
                                "{SourceContext} {Message:lj} " +
                                "{Properties:j}{NewLine}{Exception}",
                formatProvider: CultureInfo.InvariantCulture);
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
                outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] BOOTSTRAP {Message:lj}{NewLine}{Exception}",
                formatProvider: CultureInfo.InvariantCulture);
    }
}
