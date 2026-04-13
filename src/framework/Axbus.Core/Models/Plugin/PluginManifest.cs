// <copyright file="PluginManifest.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Plugin;

/// <summary>
/// Represents the contents of a plugin manifest file (<c>*.manifest.json</c>).
/// Each plugin assembly must be accompanied by a manifest file that declares
/// its identity, supported formats and framework version compatibility.
/// The manifest is read by <see cref="Axbus.Core.Abstractions.Plugin.IPluginManifestReader"/>
/// before the assembly is loaded.
/// </summary>
public sealed class PluginManifest
{
    /// <summary>Gets or sets the display name of the plugin.</summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the unique reverse-domain identifier of the plugin.
    /// Example: <c>axbus.plugin.reader.json</c>.
    /// </summary>
    public string PluginId { get; set; } = string.Empty;

    /// <summary>Gets or sets the semantic version of the plugin assembly.</summary>
    public string Version { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the minimum Axbus framework version this plugin is compatible with.
    /// </summary>
    public string FrameworkVersion { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the source format this plugin can read.
    /// <c>null</c> for writer-only plugins.
    /// </summary>
    public string? SourceFormat { get; set; }

    /// <summary>
    /// Gets or sets the target format this plugin can write.
    /// <c>null</c> for reader-only plugins.
    /// </summary>
    public string? TargetFormat { get; set; }

    /// <summary>
    /// Gets or sets the pipeline stages this plugin supports.
    /// Example: <c>[ "Read", "Parse", "Transform" ]</c>.
    /// </summary>
    public List<string> SupportedStages { get; set; } = new();

    /// <summary>
    /// Gets or sets a value indicating whether this plugin implements
    /// all core pipeline stages (Reader + Parser + Transformer + Writer).
    /// </summary>
    public bool IsBundled { get; set; }

    /// <summary>Gets or sets the name of the plugin author or organisation.</summary>
    public string Author { get; set; } = string.Empty;

    /// <summary>Gets or sets a human-readable description of the plugin.</summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the names of NuGet packages this plugin depends on.
    /// Used for documentation purposes only; dependency resolution is handled by NuGet.
    /// </summary>
    public List<string> Dependencies { get; set; } = new();
}