// <copyright file="PluginFileSet.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Plugin;

/// <summary>
/// Represents a pair of files discovered by the plugin folder scanner:
/// the plugin assembly DLL and its accompanying manifest JSON file.
/// Used by <see cref="Axbus.Core.Abstractions.Plugin.IPluginLoader"/>
/// to load and validate plugins before registering them.
/// </summary>
public sealed class PluginFileSet
{
    /// <summary>
    /// Gets or sets the full path to the plugin assembly file (.dll).
    /// </summary>
    public string AssemblyPath { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the full path to the plugin manifest file (.manifest.json).
    /// </summary>
    public string ManifestPath { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the path to the folder containing both the assembly
    /// and the manifest file.
    /// </summary>
    public string PluginFolder { get; set; } = string.Empty;
}