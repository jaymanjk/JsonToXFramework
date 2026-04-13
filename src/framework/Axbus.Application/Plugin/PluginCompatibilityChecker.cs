// <copyright file="PluginCompatibilityChecker.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;

/// <summary>
/// Validates whether a plugin is compatible with the running Axbus framework version.
/// Compares the plugin's declared minimum framework version against the current
/// framework version using semantic versioning rules. Incompatible plugins are
/// skipped with an error log rather than causing application startup to fail.
/// </summary>
public sealed class PluginCompatibilityChecker
{
    /// <summary>
    /// Logger instance for compatibility check diagnostic messages.
    /// </summary>
    private readonly ILogger<PluginCompatibilityChecker> logger;

    /// <summary>
    /// The current Axbus framework version to check against.
    /// </summary>
    private readonly Version frameworkVersion;

    /// <summary>
    /// Initializes a new instance of <see cref="PluginCompatibilityChecker"/>.
    /// </summary>
    /// <param name="logger">The logger for compatibility check messages.</param>
    /// <param name="frameworkVersion">The current framework version to validate against.</param>
    public PluginCompatibilityChecker(ILogger<PluginCompatibilityChecker> logger, Version frameworkVersion)
    {
        this.logger = logger;
        this.frameworkVersion = frameworkVersion;
    }

    /// <summary>
    /// Checks whether the plugin described by <paramref name="manifest"/>
    /// is compatible with the current framework version.
    /// </summary>
    /// <param name="manifest">The plugin manifest containing the declared framework version requirement.</param>
    /// <returns>
    /// A <see cref="PluginCompatibility"/> indicating whether the plugin is compatible
    /// and the reason if it is not.
    /// </returns>
    public PluginCompatibility Check(PluginManifest manifest)
    {
        ArgumentNullException.ThrowIfNull(manifest);

        // Parse the plugin's required framework version from the manifest
        if (!Version.TryParse(manifest.FrameworkVersion, out var requiredVersion))
        {
            var reason = $"Plugin '{manifest.PluginId}' has an invalid FrameworkVersion value: '{manifest.FrameworkVersion}'.";
            logger.LogError(reason);
            return PluginCompatibility.Incompatible(reason);
        }

        // Plugin requires a framework version newer than what is running
        if (requiredVersion > frameworkVersion)
        {
            var reason = $"Plugin '{manifest.PluginId}' requires framework v{requiredVersion} " +
                         $"but current version is v{frameworkVersion}.";
            logger.LogError(reason);
            return PluginCompatibility.Incompatible(reason);
        }

        logger.LogDebug(
            "Plugin '{PluginId}' passed compatibility check. Required: v{Required} | Current: v{Current}",
            manifest.PluginId,
            requiredVersion,
            frameworkVersion);

        return PluginCompatibility.Compatible;
    }
}