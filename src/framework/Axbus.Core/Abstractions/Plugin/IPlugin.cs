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