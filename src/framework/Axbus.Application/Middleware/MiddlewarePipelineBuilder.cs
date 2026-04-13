// <copyright file="MiddlewarePipelineBuilder.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Middleware;

using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Builds and executes the ordered middleware chain for a single pipeline stage.
/// Middleware components are applied in list order so that the first component
/// is the outermost wrapper. The innermost invocation calls the actual stage delegate.
/// This mirrors the ASP.NET Core middleware pipeline design.
/// </summary>
public sealed class MiddlewarePipelineBuilder
{
    /// <summary>
    /// The ordered list of middleware components to apply.
    /// </summary>
    private readonly IReadOnlyList<IPipelineMiddleware> middleware;

    /// <summary>
    /// Initializes a new instance of <see cref="MiddlewarePipelineBuilder"/>
    /// with the specified ordered middleware components.
    /// </summary>
    /// <param name="middleware">The ordered list of middleware components to apply.</param>
    public MiddlewarePipelineBuilder(IReadOnlyList<IPipelineMiddleware> middleware)
    {
        ArgumentNullException.ThrowIfNull(middleware);
        this.middleware = middleware;
    }

    /// <summary>
    /// Executes the middleware chain with the specified context and innermost stage action.
    /// Each middleware component wraps the next, with <paramref name="stageAction"/>
    /// at the innermost position.
    /// </summary>
    /// <param name="context">The middleware context for the current stage execution.</param>
    /// <param name="stageAction">The actual pipeline stage logic to invoke at the innermost position.</param>
    /// <returns>A <see cref="PipelineStageResult"/> from the innermost stage or an intercepting middleware.</returns>
    public async Task<PipelineStageResult> ExecuteAsync(
        IPipelineMiddlewareContext context,
        Func<Task<PipelineStageResult>> stageAction)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(stageAction);

        // Build the chain from the inside out
        // so that middleware[0] is the outermost wrapper
        PipelineStageDelegate chain = () => stageAction();

        for (var i = middleware.Count - 1; i >= 0; i--)
        {
            // Capture current values for the closure
            var current = middleware[i];
            var next = chain;
            chain = () => current.InvokeAsync(context, next);
        }

        return await chain().ConfigureAwait(false);
    }
}