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