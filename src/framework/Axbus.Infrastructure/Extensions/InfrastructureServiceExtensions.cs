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
        services.Configure<AxbusRootSettings>(options => configuration.Bind(options));

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
