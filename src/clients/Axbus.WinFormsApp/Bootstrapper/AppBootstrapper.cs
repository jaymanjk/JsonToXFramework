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