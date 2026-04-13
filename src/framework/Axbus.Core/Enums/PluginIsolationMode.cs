// <copyright file="PluginIsolationMode.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Specifies how plugin assemblies are loaded into the host process.
/// Isolation prevents dependency version conflicts between plugins
/// and between plugins and the host application.
/// </summary>
public enum PluginIsolationMode
{
    /// <summary>
    /// Each plugin is loaded into its own
    /// <see cref="System.Runtime.Loader.AssemblyLoadContext"/>.
    /// This prevents DLL version conflicts between plugins and between
    /// plugins and the host. This is the default and recommended mode
    /// for production environments.
    /// </summary>
    Isolated = 0,

    /// <summary>
    /// All plugins are loaded into the default
    /// <see cref="System.Runtime.Loader.AssemblyLoadContext"/>.
    /// Simpler but susceptible to DLL version conflicts.
    /// Use only for debugging or in controlled environments
    /// where all plugins share the same dependency versions.
    /// </summary>
    Shared = 1,
}