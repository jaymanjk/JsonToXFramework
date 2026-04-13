// <copyright file="IPluginRegistry.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

using Axbus.Core.Models.Plugin;

/// <summary>
/// Maintains the registry of loaded plugins and resolves the appropriate
/// plugin for a given source and target format combination.
/// Conflict resolution between multiple plugins supporting the same format
/// pair is governed by the configured
/// <see cref="Axbus.Core.Enums.PluginConflictStrategy"/>.
/// </summary>
public interface IPluginRegistry
{
    /// <summary>
    /// Registers a loaded plugin described by <paramref name="descriptor"/>
    /// in the registry. Applies conflict resolution if a plugin for the
    /// same format combination is already registered.
    /// </summary>
    /// <param name="descriptor">The descriptor of the plugin to register.</param>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPluginException">
    /// Thrown when <see cref="Axbus.Core.Enums.PluginConflictStrategy.ThrowException"/>
    /// is configured and a conflicting plugin is already registered.
    /// </exception>
    void Register(PluginDescriptor descriptor);

    /// <summary>
    /// Resolves the best available <see cref="IPlugin"/> for the specified
    /// source and target format combination.
    /// </summary>
    /// <param name="sourceFormat">The source format identifier, for example <c>json</c>.</param>
    /// <param name="targetFormat">The target format identifier, for example <c>csv</c>.</param>
    /// <returns>The resolved <see cref="IPlugin"/> instance.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPluginException">
    /// Thrown when no plugin is registered for the specified format combination.
    /// </exception>
    IPlugin Resolve(string sourceFormat, string targetFormat);

    /// <summary>
    /// Resolves a plugin by its explicit plugin identifier.
    /// Used when <see cref="Axbus.Core.Models.Configuration.ConversionModule.PluginOverride"/>
    /// is specified.
    /// </summary>
    /// <param name="pluginId">The unique identifier of the plugin to resolve.</param>
    /// <returns>The <see cref="IPlugin"/> with the specified identifier.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPluginException">
    /// Thrown when no plugin with the specified identifier is registered.
    /// </exception>
    IPlugin ResolveById(string pluginId);

    /// <summary>
    /// Gets all currently registered plugin descriptors.
    /// </summary>
    IReadOnlyCollection<PluginDescriptor> GetAll();
}