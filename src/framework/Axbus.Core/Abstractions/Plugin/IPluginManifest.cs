// <copyright file="IPluginManifest.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Defines the contract for a plugin manifest.
/// The manifest provides identity and version information about a plugin
/// and is read from the <c>*.manifest.json</c> file before the plugin
/// assembly is loaded.
/// The concrete implementation is <see cref="Axbus.Core.Models.Plugin.PluginManifest"/>.
/// </summary>
public interface IPluginManifest
{
    /// <summary>Gets the display name of the plugin.</summary>
    string Name { get; }

    /// <summary>Gets the unique reverse-domain identifier of the plugin.</summary>
    string PluginId { get; }

    /// <summary>Gets the semantic version string of the plugin assembly.</summary>
    string Version { get; }

    /// <summary>Gets the minimum Axbus framework version this plugin requires.</summary>
    string FrameworkVersion { get; }
}