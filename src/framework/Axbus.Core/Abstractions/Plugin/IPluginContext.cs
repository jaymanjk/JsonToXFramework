// <copyright file="IPluginContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;

/// <summary>
/// Provides a plugin with access to its runtime environment during initialisation.
/// An instance of this interface is passed to
/// <see cref="IPlugin.InitializeAsync"/> so that the plugin can access its
/// configuration options, a scoped logger and information about the running
/// framework version. Plugins must not cache the context beyond initialisation.
/// </summary>
public interface IPluginContext
{
    /// <summary>Gets the unique identifier of the plugin being initialised.</summary>
    string PluginId { get; }

    /// <summary>Gets the full path to the folder containing the plugin assembly.</summary>
    string PluginFolder { get; }

    /// <summary>Gets the strongly-typed options for this plugin.</summary>
    IPluginOptions Options { get; }

    /// <summary>Gets a scoped logger for the plugin to use during initialisation.</summary>
    ILogger Logger { get; }

    /// <summary>Gets information about the running Axbus framework version.</summary>
    FrameworkInfo Framework { get; }
}