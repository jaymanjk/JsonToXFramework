// <copyright file="PluginDescriptor.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Plugin;

using System.Reflection;
using Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Holds runtime information about a loaded plugin.
/// Created by the plugin loader after an assembly has been successfully
/// loaded and an <see cref="IPlugin"/> instance has been created.
/// Stored in the plugin registry for resolution at pipeline build time.
/// </summary>
public sealed class PluginDescriptor
{
    /// <summary>
    /// Gets or sets the <see cref="IPlugin"/> instance created from the loaded assembly.
    /// </summary>
    public IPlugin Instance { get; set; } = null!;

    /// <summary>
    /// Gets or sets the deserialized manifest for this plugin.
    /// </summary>
    public PluginManifest Manifest { get; set; } = null!;

    /// <summary>
    /// Gets or sets the loaded assembly containing the plugin implementation.
    /// </summary>
    public Assembly Assembly { get; set; } = null!;

    /// <summary>
    /// Gets or sets a value indicating whether this plugin was loaded
    /// into an isolated <see cref="System.Runtime.Loader.AssemblyLoadContext"/>.
    /// </summary>
    public bool IsIsolated { get; set; }
}