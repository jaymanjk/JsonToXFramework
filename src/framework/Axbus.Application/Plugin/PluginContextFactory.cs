// <copyright file="PluginContextFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using Axbus.Core.Abstractions.Factories;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;

/// <summary>
/// Creates <see cref="IPluginContext"/> instances for use during plugin initialisation.
/// Provides each plugin with its folder path, typed options, a scoped logger
/// and information about the running framework version.
/// </summary>
public sealed class PluginContextFactory
{
    /// <summary>
    /// Logger factory used to create scoped loggers for each plugin.
    /// </summary>
    private readonly ILoggerFactory loggerFactory;

    /// <summary>
    /// Factory for deserialising plugin-specific options from module configuration.
    /// </summary>
    private readonly IPluginOptionsFactory optionsFactory;

    /// <summary>
    /// The current framework version passed to plugins during initialisation.
    /// </summary>
    private readonly FrameworkInfo frameworkInfo;

    /// <summary>
    /// Initializes a new instance of <see cref="PluginContextFactory"/>.
    /// </summary>
    /// <param name="loggerFactory">Factory used to create per-plugin loggers.</param>
    /// <param name="optionsFactory">Factory for creating typed plugin options.</param>
    /// <param name="frameworkInfo">Current framework version and environment information.</param>
    public PluginContextFactory(
        ILoggerFactory loggerFactory,
        IPluginOptionsFactory optionsFactory,
        FrameworkInfo frameworkInfo)
    {
        this.loggerFactory = loggerFactory;
        this.optionsFactory = optionsFactory;
        this.frameworkInfo = frameworkInfo;
    }

    /// <summary>
    /// Creates an <see cref="IPluginContext"/> for the plugin identified by
    /// <paramref name="pluginId"/> using the options from <paramref name="module"/>.
    /// </summary>
    /// <param name="pluginId">The unique identifier of the plugin being initialised.</param>
    /// <param name="pluginFolder">The full path to the plugin folder.</param>
    /// <param name="module">The conversion module whose options should be provided to the plugin.</param>
    /// <returns>A configured <see cref="IPluginContext"/> ready for plugin initialisation.</returns>
    public IPluginContext Create(string pluginId, string pluginFolder, ConversionModule module)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(pluginId);
        ArgumentNullException.ThrowIfNull(module);

        // Create a scoped logger for this specific plugin
        var scopedLogger = loggerFactory.CreateLogger(pluginId);

        // Deserialise plugin options with an empty default if no options are configured
        var options = optionsFactory.Create<EmptyPluginOptions>(module);

        return new DefaultPluginContext(pluginId, pluginFolder, options, scopedLogger, frameworkInfo);
    }

    /// <summary>
    /// Default implementation of <see cref="IPluginContext"/> used during initialisation.
    /// </summary>
    private sealed class DefaultPluginContext : IPluginContext
    {
        /// <summary>Gets the unique identifier of the plugin being initialised.</summary>
        public string PluginId { get; }

        /// <summary>Gets the full path to the folder containing the plugin assembly.</summary>
        public string PluginFolder { get; }

        /// <summary>Gets the strongly-typed options for this plugin.</summary>
        public IPluginOptions Options { get; }

        /// <summary>Gets a scoped logger for the plugin to use during initialisation.</summary>
        public ILogger Logger { get; }

        /// <summary>Gets information about the running Axbus framework version.</summary>
        public FrameworkInfo Framework { get; }

        /// <summary>
        /// Initializes a new instance of <see cref="DefaultPluginContext"/>.
        /// </summary>
        public DefaultPluginContext(
            string pluginId,
            string pluginFolder,
            IPluginOptions options,
            ILogger logger,
            FrameworkInfo frameworkInfo)
        {
            PluginId = pluginId;
            PluginFolder = pluginFolder;
            Options = options;
            Logger = logger;
            Framework = frameworkInfo;
        }
    }

    /// <summary>
    /// Fallback empty options used when no plugin-specific options are configured.
    /// </summary>
    private sealed class EmptyPluginOptions : IPluginOptions
    {
    }
}
