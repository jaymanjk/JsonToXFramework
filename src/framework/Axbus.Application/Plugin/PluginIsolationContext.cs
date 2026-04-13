// <copyright file="PluginIsolationContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using System.Reflection;
using System.Runtime.Loader;

/// <summary>
/// An <see cref="AssemblyLoadContext"/> that provides isolation for a single plugin assembly.
/// Each plugin loaded with <see cref="Axbus.Core.Enums.PluginIsolationMode.Isolated"/>
/// gets its own instance of this context, preventing DLL version conflicts between
/// plugins and between plugins and the host application.
/// Implements collectible unloading so that plugins can be removed without restarting.
/// </summary>
public sealed class PluginIsolationContext : AssemblyLoadContext
{
    /// <summary>
    /// The resolver used to locate dependency assemblies from the plugin folder.
    /// </summary>
    private readonly AssemblyDependencyResolver resolver;

    /// <summary>
    /// Initializes a new instance of <see cref="PluginIsolationContext"/>.
    /// </summary>
    /// <param name="pluginAssemblyPath">The full path to the plugin assembly DLL.</param>
    public PluginIsolationContext(string pluginAssemblyPath)
        : base(name: Path.GetFileNameWithoutExtension(pluginAssemblyPath), isCollectible: true)
    {
        resolver = new AssemblyDependencyResolver(pluginAssemblyPath);
    }

    /// <summary>
    /// Resolves an assembly by name, first checking the plugin folder via the
    /// dependency resolver, then falling back to the default load context.
    /// </summary>
    /// <param name="assemblyName">The name of the assembly to resolve.</param>
    /// <returns>The resolved <see cref="Assembly"/>, or <c>null</c> if not found in the plugin folder.</returns>
    protected override Assembly? Load(AssemblyName assemblyName)
    {
        // Try to resolve from the plugin's own folder first
        var assemblyPath = resolver.ResolveAssemblyToPath(assemblyName);

        if (assemblyPath != null)
        {
            // Load from plugin folder into this isolated context
            return LoadFromAssemblyPath(assemblyPath);
        }

        // Fall back to default context for framework and shared assemblies
        return null;
    }
}