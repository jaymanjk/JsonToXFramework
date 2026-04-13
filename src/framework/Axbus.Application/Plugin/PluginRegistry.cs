// <copyright file="PluginRegistry.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

/// <summary>
/// Maintains the registry of loaded plugins and resolves the appropriate plugin
/// for a given source and target format combination. Applies the configured
/// <see cref="PluginConflictStrategy"/> when multiple plugins support the same
/// format pair.
/// </summary>
public sealed class PluginRegistry : IPluginRegistry
{
    /// <summary>
    /// Logger instance for registry diagnostic messages.
    /// </summary>
    private readonly ILogger<PluginRegistry> logger;

    /// <summary>
    /// The configured conflict resolution strategy.
    /// </summary>
    private readonly PluginConflictStrategy conflictStrategy;

    /// <summary>
    /// All registered plugin descriptors indexed by plugin ID.
    /// </summary>
    private readonly Dictionary<string, PluginDescriptor> descriptors = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>
    /// Format pair to plugin ID mapping for fast resolution.
    /// Key format: "sourceFormat:targetFormat".
    /// </summary>
    private readonly Dictionary<string, string> formatMap = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>
    /// Initializes a new instance of <see cref="PluginRegistry"/>.
    /// </summary>
    /// <param name="logger">The logger for registry operations.</param>
    /// <param name="options">Root settings containing the conflict strategy configuration.</param>
    public PluginRegistry(ILogger<PluginRegistry> logger, IOptions<AxbusRootSettings> options)
    {
        this.logger = logger;
        this.conflictStrategy = options.Value.PluginSettings.ConflictStrategy;
    }

    /// <summary>
    /// Registers a loaded plugin in the registry with conflict resolution.
    /// </summary>
    /// <param name="descriptor">The descriptor of the plugin to register.</param>
    /// <exception cref="AxbusPluginException">
    /// Thrown when <see cref="PluginConflictStrategy.ThrowException"/> is configured
    /// and a conflict exists.
    /// </exception>
    public void Register(PluginDescriptor descriptor)
    {
        ArgumentNullException.ThrowIfNull(descriptor);

        var pluginId = descriptor.Instance.PluginId;

        // Build the format map key for this plugin
        var sourceFormat = descriptor.Manifest.SourceFormat ?? string.Empty;
        var targetFormat = descriptor.Manifest.TargetFormat ?? string.Empty;
        var formatKey = $"{sourceFormat}:{targetFormat}";

        // Handle conflict if a plugin for this format pair is already registered
        if (formatMap.TryGetValue(formatKey, out var existingId) && !string.IsNullOrEmpty(formatKey.Trim(':')))
        {
            var existingDescriptor = descriptors[existingId];

            switch (conflictStrategy)
            {
                case PluginConflictStrategy.UseLatestVersion:
                    var existingVersion = existingDescriptor.Instance.Version;
                    var newVersion = descriptor.Instance.Version;
                    if (newVersion <= existingVersion)
                    {
                        logger.LogWarning(
                            "Plugin conflict: '{NewId}' v{NewVer} skipped in favour of '{ExistingId}' v{ExistingVer}",
                            pluginId, newVersion, existingId, existingVersion);
                        return;
                    }
                    logger.LogInformation(
                        "Plugin conflict resolved: '{NewId}' v{NewVer} replaces '{ExistingId}' v{ExistingVer}",
                        pluginId, newVersion, existingId, existingVersion);
                    break;

                case PluginConflictStrategy.UseFirstRegistered:
                    logger.LogWarning(
                        "Plugin conflict: '{NewId}' skipped - '{ExistingId}' was registered first",
                        pluginId, existingId);
                    return;

                case PluginConflictStrategy.ThrowException:
                    throw new AxbusPluginException(
                        $"Plugin conflict: both '{pluginId}' and '{existingId}' handle format '{formatKey}'. " +
                        "Use PluginOverride in the conversion module to resolve.",
                        pluginId);

                case PluginConflictStrategy.UseExplicitOverride:
                    logger.LogWarning(
                        "Plugin conflict: '{NewId}' and '{ExistingId}' both handle '{FormatKey}'. " +
                        "Use PluginOverride to select explicitly.",
                        pluginId, existingId, formatKey);
                    break;
            }
        }

        descriptors[pluginId] = descriptor;

        if (!string.IsNullOrWhiteSpace(formatKey.Trim(':')))
        {
            formatMap[formatKey] = pluginId;
        }

        logger.LogInformation(
            "Plugin registered: {PluginId} | Source: {Source} | Target: {Target}",
            pluginId,
            sourceFormat,
            targetFormat);
    }

    /// <summary>
    /// Resolves the best plugin for the specified source and target format combination.
    /// </summary>
    /// <param name="sourceFormat">The source format identifier.</param>
    /// <param name="targetFormat">The target format identifier.</param>
    /// <returns>The resolved <see cref="IPlugin"/> instance.</returns>
    /// <exception cref="AxbusPluginException">Thrown when no plugin handles the format pair.</exception>
    public IPlugin Resolve(string sourceFormat, string targetFormat)
    {
        var formatKey = $"{sourceFormat}:{targetFormat}";

        if (!formatMap.TryGetValue(formatKey, out var pluginId))
        {
            throw new AxbusPluginException(
                $"No plugin registered for format pair '{formatKey}'. " +
                "Check PluginSettings.Plugins in appsettings.json.");
        }

        return descriptors[pluginId].Instance;
    }

    /// <summary>
    /// Resolves a plugin by its explicit plugin identifier.
    /// </summary>
    /// <param name="pluginId">The unique identifier of the plugin to resolve.</param>
    /// <returns>The matching <see cref="IPlugin"/> instance.</returns>
    /// <exception cref="AxbusPluginException">Thrown when no plugin with the ID is registered.</exception>
    public IPlugin ResolveById(string pluginId)
    {
        if (!descriptors.TryGetValue(pluginId, out var descriptor))
        {
            throw new AxbusPluginException(
                $"No plugin registered with ID '{pluginId}'.",
                pluginId);
        }

        return descriptor.Instance;
    }

    /// <summary>
    /// Gets all currently registered plugin descriptors.
    /// </summary>
    /// <returns>A read-only collection of all registered descriptors.</returns>
    public IReadOnlyCollection<PluginDescriptor> GetAll() => descriptors.Values;
}