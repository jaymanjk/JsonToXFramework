// <copyright file="TimingMiddleware.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Middleware;

using System.Diagnostics;
using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Pipeline middleware that measures the elapsed time of each pipeline stage.
/// Sets <see cref="PipelineStageResult.Duration"/> on the result so that
/// downstream middleware and the conversion runner have accurate timing data.
/// Should be placed after <see cref="LoggingMiddleware"/> in the middleware chain.
/// </summary>
public sealed class TimingMiddleware : IPipelineMiddleware
{
    /// <summary>
    /// Starts a stopwatch, invokes the next middleware, then records the elapsed time
    /// in the returned <see cref="PipelineStageResult.Duration"/>.
    /// </summary>
    /// <param name="context">Contextual information about the stage being executed.</param>
    /// <param name="next">The next middleware or stage delegate in the chain.</param>
    /// <returns>The result from the next middleware with <see cref="PipelineStageResult.Duration"/> set.</returns>
    public async Task<PipelineStageResult> InvokeAsync(
        IPipelineMiddlewareContext context,
        PipelineStageDelegate next)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(next);

        // Start timing before invoking the next stage in the chain
        var stopwatch = Stopwatch.StartNew();

        var result = await next().ConfigureAwait(false);

        stopwatch.Stop();

        // Record duration on the result for upstream middleware and runners
        result.Duration = stopwatch.Elapsed;

        return result;
    }
}