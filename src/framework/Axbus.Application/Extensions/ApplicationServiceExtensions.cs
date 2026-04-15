// <copyright file="ApplicationServiceExtensions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Extensions;

using Axbus.Application.Conversion;
using Axbus.Application.Factories;
using Axbus.Application.Notifications;
using Axbus.Application.Plugin;
using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Abstractions.Factories;
using Axbus.Core.Abstractions.Notifications;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

/// <summary>
/// Provides extension methods for registering all Axbus Application layer
/// services into the dependency injection container. Call
/// <see cref="AddAxbusApplication"/> from the application bootstrapper
/// to wire up the conversion runner, pipeline factory, plugin registry,
/// middleware factory and notification services.
/// </summary>
public static class ApplicationServiceExtensions
{
    /// <summary>
    /// Registers all Axbus Application layer services into <paramref name="services"/>.
    /// </summary>
    /// <param name="services">The service collection to register services into.</param>
    /// <param name="configuration">The application configuration used to bind <see cref="AxbusRootSettings"/>.</param>
    /// <returns>The same <paramref name="services"/> instance for fluent chaining.</returns>
    public static IServiceCollection AddAxbusApplication(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        ArgumentNullException.ThrowIfNull(services);
        ArgumentNullException.ThrowIfNull(configuration);

        // Bind root settings from configuration (binds from root since config properties match AxbusRootSettings)
        services.Configure<AxbusRootSettings>(options => configuration.Bind(options));

        // Register framework version info
        services.AddSingleton(new FrameworkInfo(new Version(1, 0, 0), "Production"));

        // Conversion runner - main entry point
        services.AddSingleton<IConversionRunner, ConversionRunner>();

        // Pipeline factory - creates pipelines per module
        services.AddSingleton<IPipelineFactory, PipelineFactory>();

        // Middleware factory - builds the stage middleware chain
        services.AddSingleton<IMiddlewareFactory>(sp =>
        {
            var loggerFactory = sp.GetRequiredService<Microsoft.Extensions.Logging.ILoggerFactory>();
            // Use default pipeline options for the middleware factory
            // Individual module options are applied per execution
            return new MiddlewareFactory(loggerFactory, new PipelineOptions());
        });

        // Plugin registry - stores and resolves loaded plugins
        services.AddSingleton<IPluginRegistry, PluginRegistry>();

        // Plugin loader - loads assemblies into AssemblyLoadContext
        services.AddSingleton<IPluginLoader, PluginLoader>();

        // Plugin manifest reader - deserialises manifest JSON files
        services.AddSingleton<IPluginManifestReader, PluginManifestReader>();

        // Plugin options factory - deserialises module plugin options
        services.AddSingleton<IPluginOptionsFactory, PluginOptionsFactory>();

        // Plugin context factory - creates IPluginContext for initialisation
        services.AddSingleton<PluginContextFactory>();

        // Notifications - progress and event publishing
        services.AddSingleton<IProgressReporter, ProgressReporter>();
        services.AddSingleton<IEventPublisher, EventPublisher>();

        // Plugin registration service - must be registered before ConversionHostedService
        // so the registry is fully populated before any pipeline is created
        services.AddHostedService<PluginRegistrationService>();

        return services;
    }
}
