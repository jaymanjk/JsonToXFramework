// <copyright file="PipelineMiddlewareContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Middleware;

using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Enums;

/// <summary>
/// Concrete implementation of <see cref="IPipelineMiddlewareContext"/>.
/// Carries contextual information about the pipeline stage being executed
/// through the middleware chain. Created by the pipeline stage executor
/// before invoking the middleware chain.
/// </summary>
public sealed class PipelineMiddlewareContext : IPipelineMiddlewareContext
{
    /// <summary>
    /// Gets the name of the conversion module being executed.
    /// </summary>
    public string ModuleName { get; }

    /// <summary>
    /// Gets the identifier of the plugin executing this stage.
    /// </summary>
    public string PluginId { get; }

    /// <summary>
    /// Gets the pipeline stage being executed.
    /// </summary>
    public PipelineStage Stage { get; }

    /// <summary>
    /// Gets additional properties associated with this stage execution.
    /// </summary>
    public IReadOnlyDictionary<string, object> Properties { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="PipelineMiddlewareContext"/>.
    /// </summary>
    /// <param name="moduleName">The name of the conversion module being executed.</param>
    /// <param name="pluginId">The identifier of the plugin executing this stage.</param>
    /// <param name="stage">The pipeline stage being executed.</param>
    /// <param name="properties">Additional contextual properties, or null for an empty dictionary.</param>
    public PipelineMiddlewareContext(
        string moduleName,
        string pluginId,
        PipelineStage stage,
        Dictionary<string, object>? properties = null)
    {
        ModuleName = moduleName;
        PluginId = pluginId;
        Stage = stage;
        Properties = properties ?? new Dictionary<string, object>();
    }
}