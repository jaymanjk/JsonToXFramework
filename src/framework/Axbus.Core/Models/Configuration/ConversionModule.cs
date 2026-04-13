// <copyright file="ConversionModule.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

using System.Text.Json;

/// <summary>
/// Defines a single named conversion job within the Axbus framework.
/// Each module specifies its own source, target, pipeline behaviour and plugin options.
/// Modules are listed under <c>ConversionModules</c> in <c>appsettings.json</c>.
/// </summary>
public sealed class ConversionModule
{
    /// <summary>
    /// Gets or sets the unique name identifying this conversion module.
    /// Used in log output and progress notifications.
    /// Example: <c>ACT001-SalesOrder</c>.
    /// </summary>
    public string ConversionName { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets a human-readable description of the conversion module.
    /// Displayed in the WinForms UI and included in log output.
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets a value indicating whether this module is active.
    /// Disabled modules are skipped with a <see cref="ConversionStatus.Skipped"/> status.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool IsEnabled { get; set; } = true;

    /// <summary>
    /// Gets or sets the order in which this module executes relative to
    /// other modules in the same run. Lower numbers execute first.
    /// Defaults to <c>0</c>.
    /// </summary>
    public int ExecutionOrder { get; set; } = 0;

    /// <summary>
    /// Gets or sets a value indicating whether a failure in this module
    /// should allow remaining modules to continue executing.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool ContinueOnError { get; set; } = true;

    /// <summary>
    /// Gets or sets a value indicating whether this module may run concurrently
    /// with other modules that also have <see cref="RunInParallel"/> set to <c>true</c>.
    /// This flag is overridden by the root-level <c>RunInParallel</c> setting
    /// in <see cref="AxbusRootSettings"/>.
    /// Defaults to <c>false</c>.
    /// </summary>
    public bool RunInParallel { get; set; } = false;

    /// <summary>
    /// Gets or sets the format identifier of the source data.
    /// Example values: <c>json</c>, <c>xml</c>, <c>csv</c>.
    /// Used to resolve the appropriate reader plugin.
    /// </summary>
    public string SourceFormat { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the format identifier of the conversion target.
    /// Example values: <c>csv</c>, <c>excel</c>, <c>text</c>.
    /// Used to resolve the appropriate writer plugin.
    /// </summary>
    public string TargetFormat { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the explicit plugin identifier to use for this module.
    /// When <c>null</c> the framework automatically resolves the best plugin
    /// based on <see cref="SourceFormat"/> and <see cref="TargetFormat"/>.
    /// </summary>
    public string? PluginOverride { get; set; }

    /// <summary>
    /// Gets or sets the source configuration for this module.
    /// </summary>
    public SourceOptions Source { get; set; } = new();

    /// <summary>
    /// Gets or sets the target configuration for this module.
    /// </summary>
    public TargetOptions Target { get; set; } = new();

    /// <summary>
    /// Gets or sets the pipeline behaviour configuration for this module.
    /// </summary>
    public PipelineOptions Pipeline { get; set; } = new();

    /// <summary>
    /// Gets or sets plugin-specific options as a raw JSON element dictionary.
    /// The framework deserialises these into the plugin's strongly-typed options
    /// class at runtime using <see cref="Axbus.Core.Abstractions.Factories.IPluginOptionsFactory"/>.
    /// </summary>
    public Dictionary<string, JsonElement> PluginOptions { get; set; } = new();
}