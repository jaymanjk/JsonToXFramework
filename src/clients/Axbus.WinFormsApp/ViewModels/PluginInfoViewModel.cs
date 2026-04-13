// <copyright file="PluginInfoViewModel.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.ViewModels;

using Axbus.Core.Abstractions.Plugin;

/// <summary>
/// View model that exposes loaded plugin information for display in a
/// plugin info panel or about dialog. Wraps an <see cref="IPlugin"/>
/// instance with display-friendly properties.
/// </summary>
public sealed class PluginInfoViewModel
{
    /// <summary>Gets the plugin's unique identifier.</summary>
    public string PluginId { get; }

    /// <summary>Gets the plugin's display name.</summary>
    public string Name { get; }

    /// <summary>Gets the plugin's version as a display string.</summary>
    public string Version { get; }

    /// <summary>Gets the pipeline capabilities as a comma-separated display string.</summary>
    public string Capabilities { get; }

    /// <summary>Gets the minimum framework version required by this plugin.</summary>
    public string MinFrameworkVersion { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="PluginInfoViewModel"/>
    /// from a loaded <see cref="IPlugin"/> instance.
    /// </summary>
    /// <param name="plugin">The loaded plugin to wrap.</param>
    public PluginInfoViewModel(IPlugin plugin)
    {
        ArgumentNullException.ThrowIfNull(plugin);
        PluginId = plugin.PluginId;
        Name = plugin.Name;
        Version = plugin.Version.ToString();
        Capabilities = plugin.Capabilities.ToString();
        MinFrameworkVersion = plugin.MinFrameworkVersion.ToString();
    }
}