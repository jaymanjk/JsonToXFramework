// <copyright file="IPipelineMiddlewareContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Middleware;

using Axbus.Core.Enums;

/// <summary>
/// Provides contextual information to each <see cref="IPipelineMiddleware"/>
/// about the pipeline stage being executed. Allows middleware to produce
/// meaningful log messages and metrics that include the module name,
/// plugin identifier and stage name.
/// </summary>
public interface IPipelineMiddlewareContext
{
    /// <summary>Gets the name of the conversion module being executed.</summary>
    string ModuleName { get; }

    /// <summary>Gets the identifier of the plugin executing this stage.</summary>
    string PluginId { get; }

    /// <summary>Gets the pipeline stage being executed.</summary>
    PipelineStage Stage { get; }

    /// <summary>
    /// Gets additional properties associated with this stage execution.
    /// Can be used by middleware to pass arbitrary contextual data.
    /// </summary>
    IReadOnlyDictionary<string, object> Properties { get; }
}