// <copyright file="IPipelineMiddleware.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Middleware;

using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines a middleware component that wraps pipeline stage execution.
/// Middleware components are chained together in a defined order so that
/// each component can perform work before and after the next component
/// in the chain, mirroring the ASP.NET Core middleware pipeline pattern.
/// Built-in implementations include logging, timing, retry and error handling.
/// </summary>
public interface IPipelineMiddleware
{
    /// <summary>
    /// Executes this middleware component, optionally calling <paramref name="next"/>
    /// to pass control to the next component in the chain.
    /// </summary>
    /// <param name="context">
    /// Contextual information about the pipeline stage being executed,
    /// including the module name, plugin identifier and stage type.
    /// </param>
    /// <param name="next">
    /// A delegate representing the next middleware in the chain or the actual
    /// pipeline stage. Call this to proceed; omit to short-circuit the pipeline.
    /// </param>
    /// <returns>
    /// A <see cref="PipelineStageResult"/> representing the outcome of this
    /// middleware execution and any downstream execution.
    /// </returns>
    Task<PipelineStageResult> InvokeAsync(
        IPipelineMiddlewareContext context,
        PipelineStageDelegate next);
}