// <copyright file="PluginLoader.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using System.Reflection;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

/// <summary>
/// Loads plugin assemblies from disk into the appropriate
/// <see cref="System.Runtime.Loader.AssemblyLoadContext"/> and creates
/// <see cref="IPlugin"/> instances ready for registration.
/// Uses <see cref="PluginIsolationContext"/> when isolation is enabled.
/// </summary>
public sealed class PluginLoader : IPluginLoader
{
    /// <summary>
    /// Logger instance for plugin loading diagnostic messages.
    /// </summary>
    private readonly ILogger<PluginLoader> logger;

    /// <summary>
    /// Plugin settings controlling isolation mode.
    /// </summary>
    private readonly PluginSettings pluginSettings;

    /// <summary>
    /// Initializes a new instance of <see cref="PluginLoader"/>.
    /// </summary>
    /// <param name="logger">The logger for plugin loading messages.</param>
    /// <param name="options">Root settings containing plugin isolation configuration.</param>
    public PluginLoader(ILogger<PluginLoader> logger, IOptions<AxbusRootSettings> options)
    {
        this.logger = logger;
        this.pluginSettings = options.Value.PluginSettings;
    }

    /// <summary>
    /// Loads the plugin assembly identified by <paramref name="fileSet"/>
    /// and returns a <see cref="PluginDescriptor"/> with the created plugin instance.
    /// </summary>
    /// <param name="fileSet">The DLL and manifest file paths for the plugin to load.</param>
    /// <param name="cancellationToken">A token to cancel the load operation.</param>
    /// <returns>A populated <see cref="PluginDescriptor"/>.</returns>
    /// <exception cref="AxbusPluginException">
    /// Thrown when the assembly cannot be loaded or contains no valid <see cref="IPlugin"/> implementation.
    /// </exception>
    public async Task<PluginDescriptor> LoadAsync(PluginFileSet fileSet, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(fileSet);

        logger.LogDebug("Loading plugin assembly: {AssemblyPath}", fileSet.AssemblyPath);

        await Task.Yield(); // Ensure async context without blocking

        try
        {
            Assembly assembly;
            var isIsolated = pluginSettings.IsolatePlugins;

            if (isIsolated)
            {
                // Load into isolated AssemblyLoadContext
                var isolationContext = new PluginIsolationContext(fileSet.AssemblyPath);
                assembly = isolationContext.LoadFromAssemblyPath(fileSet.AssemblyPath);
            }
            else
            {
                // Load into default context (not recommended for production)
                assembly = Assembly.LoadFrom(fileSet.AssemblyPath);
            }

            // Find the IPlugin implementation in the loaded assembly
            var pluginType = assembly.GetTypes()
                .FirstOrDefault(t => typeof(IPlugin).IsAssignableFrom(t) && !t.IsAbstract && t.IsClass);

            if (pluginType == null)
            {
                throw new AxbusPluginException(
                    $"Assembly '{fileSet.AssemblyPath}' does not contain a class implementing IPlugin.",
                    Path.GetFileNameWithoutExtension(fileSet.AssemblyPath));
            }

            // Create the plugin instance using the parameterless constructor
            var pluginInstance = (IPlugin?)Activator.CreateInstance(pluginType)
                ?? throw new AxbusPluginException(
                    $"Failed to create instance of plugin type '{pluginType.FullName}'.",
                    pluginType.Name);

            logger.LogInformation(
                "Plugin loaded: {PluginId} v{Version} | Isolated: {Isolated}",
                pluginInstance.PluginId,
                pluginInstance.Version,
                isIsolated);

            return new PluginDescriptor
            {
                Instance = pluginInstance,
                Manifest = new PluginManifest
                {
                    PluginId = pluginInstance.PluginId,
                    Name = pluginInstance.Name,
                    Version = pluginInstance.Version.ToString(),
                },
                Assembly = assembly,
                IsIsolated = isIsolated,
            };
        }
        catch (AxbusPluginException)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw new AxbusPluginException(
                $"Failed to load plugin from '{fileSet.AssemblyPath}': {ex.Message}",
                Path.GetFileNameWithoutExtension(fileSet.AssemblyPath),
                ex);
        }
    }
}