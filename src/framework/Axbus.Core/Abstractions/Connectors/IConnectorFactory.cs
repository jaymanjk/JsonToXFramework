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
