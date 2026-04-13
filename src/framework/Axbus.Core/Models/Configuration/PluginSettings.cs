// <copyright file="PluginSettings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

using Axbus.Core.Enums;

/// <summary>
/// Configures how plugins are discovered, loaded and registered at application startup.
/// Configured under <c>PluginSettings</c> in <c>appsettings.json</c>.
/// </summary>
public sealed class PluginSettings
{
    /// <summary>
    /// Gets or sets the path to the folder containing plugin assemblies.
    /// When <c>null</c> or empty the framework looks for a <c>plugins</c>
    /// folder relative to the application executable.
    /// </summary>
    public string? PluginsFolder { get; set; }

    /// <summary>
    /// Gets or sets a value indicating whether sub-folders of
    /// <see cref="PluginsFolder"/> are also scanned for plugin assemblies.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool ScanSubFolders { get; set; } = true;

    /// <summary>
    /// Gets or sets a value indicating whether each plugin is loaded
    /// into its own <see cref="System.Runtime.Loader.AssemblyLoadContext"/>.
    /// Set to <c>false</c> only for debugging in controlled environments.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool IsolatePlugins { get; set; } = true;

    /// <summary>
    /// Gets or sets the strategy used when two or more registered plugins
    /// can handle the same source and target format combination.
    /// Defaults to <see cref="PluginConflictStrategy.UseLatestVersion"/>.
    /// </summary>
    public PluginConflictStrategy ConflictStrategy { get; set; } = PluginConflictStrategy.UseLatestVersion;

    /// <summary>
    /// Gets or sets the list of plugin assembly names to load.
    /// The framework scans these assemblies for types implementing
    /// <see cref="Axbus.Core.Abstractions.Plugin.IPlugin"/>.
    /// Example: <c>[ "Axbus.Plugin.Reader.Json", "Axbus.Plugin.Writer.Csv" ]</c>.
    /// </summary>
    public List<string> Plugins { get; set; } = new();
}