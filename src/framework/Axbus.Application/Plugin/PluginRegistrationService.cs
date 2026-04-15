// <copyright file="PluginRegistrationService.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

/// <summary>
/// A startup hosted service that registers all DI-injected <see cref="IPlugin"/>
/// instances into the <see cref="IPluginRegistry"/> before the conversion run begins.
/// For each bundled plugin, the corresponding manifest file is read from the
/// application base directory to obtain the source and target format identifiers.
/// This service implements <see cref="IHostedService"/> directly (not
/// <see cref="BackgroundService"/>) so that <c>StartAsync</c> completes
/// synchronously before the host starts any subsequent service, guaranteeing the
/// registry is fully populated when <c>ConversionHostedService</c> first accesses it.
/// </summary>
internal sealed class PluginRegistrationService : IHostedService
{
    /// <summary>
    /// All <see cref="IPlugin"/> instances registered in the DI container.
    /// </summary>
    private readonly IEnumerable<IPlugin> plugins;

    /// <summary>
    /// The registry that all discovered plugins are registered into.
    /// </summary>
    private readonly IPluginRegistry registry;

    /// <summary>
    /// Reader used to deserialise each plugin's manifest JSON file.
    /// </summary>
    private readonly IPluginManifestReader manifestReader;

    /// <summary>
    /// Logger for registration lifecycle messages.
    /// </summary>
    private readonly ILogger<PluginRegistrationService> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="PluginRegistrationService"/>.
    /// </summary>
    /// <param name="plugins">All DI-registered plugin instances.</param>
    /// <param name="registry">The plugin registry to populate.</param>
    /// <param name="manifestReader">The manifest reader for deserialising manifest files.</param>
    /// <param name="logger">The logger for registration messages.</param>
    public PluginRegistrationService(
        IEnumerable<IPlugin> plugins,
        IPluginRegistry registry,
        IPluginManifestReader manifestReader,
        ILogger<PluginRegistrationService> logger)
    {
        this.plugins = plugins;
        this.registry = registry;
        this.manifestReader = manifestReader;
        this.logger = logger;
    }

    /// <summary>
    /// Reads the manifest file for each DI-registered plugin and registers a
    /// <see cref="PluginDescriptor"/> in the <see cref="IPluginRegistry"/>.
    /// Called synchronously by the host before any other hosted service starts.
    /// </summary>
    /// <param name="cancellationToken">A token to cancel the startup operation.</param>
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        logger.LogInformation("Registering bundled plugins into the plugin registry...");

        // Register each DI-injected plugin using its manifest file
        foreach (var plugin in plugins)
        {
            cancellationToken.ThrowIfCancellationRequested();
            await RegisterPluginAsync(plugin, cancellationToken).ConfigureAwait(false);
        }

        logger.LogInformation(
            "Plugin registration complete. {Count} plugin(s) registered.",
            registry.GetAll().Count);
    }

    /// <summary>Stops the service — no cleanup required.</summary>
    /// <param name="cancellationToken">A token to cancel the stop operation.</param>
    /// <returns>A completed task.</returns>
    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    /// <summary>
    /// Reads the manifest file for a single plugin and registers it in the registry.
    /// The manifest is resolved by convention:
    /// <c>{AssemblyDirectory}/{AssemblyName}.manifest.json</c>.
    /// </summary>
    /// <param name="plugin">The plugin instance to register.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    private async Task RegisterPluginAsync(IPlugin plugin, CancellationToken cancellationToken)
    {
        // Resolve the manifest path from the plugin's assembly location
        var assemblyPath = plugin.GetType().Assembly.Location;
        var assemblyName = Path.GetFileNameWithoutExtension(assemblyPath);
        var assemblyDir = Path.GetDirectoryName(assemblyPath) ?? AppContext.BaseDirectory;
        var manifestPath = Path.Combine(assemblyDir, $"{assemblyName}.manifest.json");

        try
        {
            var manifest = await manifestReader.ReadAsync(manifestPath, cancellationToken)
                .ConfigureAwait(false);

            var descriptor = new PluginDescriptor
            {
                Instance = plugin,
                Manifest = manifest,
                Assembly = plugin.GetType().Assembly,
                IsIsolated = false,
            };

            registry.Register(descriptor);

            logger.LogInformation(
                "Registered plugin '{PluginId}' | Source: {Source} | Target: {Target}",
                plugin.PluginId,
                manifest.SourceFormat ?? "(none)",
                manifest.TargetFormat ?? "(none)");
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            logger.LogError(
                ex,
                "Failed to register plugin '{PluginId}' from manifest '{ManifestPath}'",
                plugin.PluginId,
                manifestPath);
            throw;
        }
    }
}
