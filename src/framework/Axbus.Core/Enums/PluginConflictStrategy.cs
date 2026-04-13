// <copyright file="PluginConflictStrategy.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Specifies how the plugin registry resolves conflicts when two or more
/// plugins are registered that can handle the same source and target format.
/// </summary>
public enum PluginConflictStrategy
{
    /// <summary>
    /// The plugin with the highest semantic version number is used.
    /// This is the default and recommended strategy for production environments.
    /// </summary>
    UseLatestVersion = 0,

    /// <summary>
    /// The first plugin registered for a given format combination is used.
    /// Subsequent conflicting registrations are ignored with a warning logged.
    /// </summary>
    UseFirstRegistered = 1,

    /// <summary>
    /// An <see cref="Axbus.Core.Exceptions.AxbusPluginException"/> is thrown
    /// immediately when a conflicting plugin is registered.
    /// Use this strategy to fail fast and force explicit resolution via
    /// <see cref="Axbus.Core.Models.Configuration.ConversionModule.PluginOverride"/>.
    /// </summary>
    ThrowException = 2,

    /// <summary>
    /// Only the plugin explicitly named in
    /// <see cref="Axbus.Core.Models.Configuration.ConversionModule.PluginOverride"/>
    /// is used. All automatic resolution is disabled.
    /// </summary>
    UseExplicitOverride = 3,
}