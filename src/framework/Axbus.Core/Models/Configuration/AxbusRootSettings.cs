// <copyright file="AxbusRootSettings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

/// <summary>
/// Root configuration model for the Axbus framework.
/// Bind this to the root section of <c>appsettings.json</c> using
/// <c>services.Configure&lt;AxbusRootSettings&gt;(configuration)</c>.
/// </summary>
public sealed class AxbusRootSettings
{
    /// <summary>
    /// Gets or sets the master parallel execution switch.
    /// When <c>false</c> all modules run sequentially regardless of their
    /// individual <see cref="ConversionModule.RunInParallel"/> settings.
    /// This acts as a global safety switch for production environments.
    /// When <c>null</c> each module decides independently.
    /// Defaults to <c>false</c>.
    /// </summary>
    public bool? RunInParallel { get; set; } = false;

    /// <summary>
    /// Gets or sets the parallelism throttle settings applied when
    /// modules run concurrently.
    /// </summary>
    public ParallelSettings ParallelSettings { get; set; } = new();

    /// <summary>
    /// Gets or sets the plugin discovery and loading configuration.
    /// </summary>
    public PluginSettings PluginSettings { get; set; } = new();

    /// <summary>
    /// Gets or sets the list of conversion modules to execute.
    /// Modules are executed in ascending <see cref="ConversionModule.ExecutionOrder"/> order
    /// unless parallel execution is enabled.
    /// </summary>
    public List<ConversionModule> ConversionModules { get; set; } = new();
}