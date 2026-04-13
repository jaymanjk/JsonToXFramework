// <copyright file="IPluginLoader.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

using Axbus.Core.Models.Plugin;

/// <summary>
/// Loads a plugin assembly from disk into an
/// <see cref="System.Runtime.Loader.AssemblyLoadContext"/> and creates
/// an <see cref="IPlugin"/> instance from the assembly.
/// Works with the manifest read by <see cref="IPluginManifestReader"/>
/// to produce a <see cref="PluginDescriptor"/> for registration.
/// </summary>
public interface IPluginLoader
{
    /// <summary>
    /// Loads the plugin assembly identified by <paramref name="fileSet"/>
    /// and returns a <see cref="PluginDescriptor"/> containing the
    /// <see cref="IPlugin"/> instance, manifest and assembly reference.
    /// </summary>
    /// <param name="fileSet">The DLL and manifest file paths for the plugin to load.</param>
    /// <param name="cancellationToken">A token to cancel the load operation.</param>
    /// <returns>
    /// A <see cref="PluginDescriptor"/> containing the loaded plugin information.
    /// </returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPluginException">
    /// Thrown when the assembly cannot be loaded or does not contain a valid <see cref="IPlugin"/> implementation.
    /// </exception>
    Task<PluginDescriptor> LoadAsync(PluginFileSet fileSet, CancellationToken cancellationToken);
}