// <copyright file="LoggingMiddleware.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Middleware;

using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Pipeline middleware that logs the entry and exit of each pipeline stage.
/// Logs the module name, plugin identifier, stage name and whether the stage
/// succeeded or failed. Should be placed first in the middleware chain so
/// that it wraps all other middleware.
/// </summary>
public sealed class LoggingMiddleware : IPipelineMiddleware
{
    /// <summary>
    /// Logger instance for structured diagnostic output.
    /// </summary>
    private readonly ILogger<LoggingMiddleware> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="LoggingMiddleware"/>.
    /// </summary>
    /// <param name="logger">The logger used for structured stage entry and exit messages.</param>
    public LoggingMiddleware(ILogger<LoggingMiddleware> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Logs stage entry, invokes the next middleware, then logs stage exit with duration.
    /// </summary>
    /// <param name="context">Contextual information about the stage being executed.</param>
    /// <param name="next">The next middleware or stage delegate in the chain.</param>
    /// <returns>The result from the next middleware or stage.</returns>
    public async Task<PipelineStageResult> InvokeAsync(
        IPipelineMiddlewareContext context,
        PipelineStageDelegate next)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(next);

        logger.LogDebug(
            "Stage starting: {Stage} | Module: {ModuleName} | Plugin: {PluginId}",
            context.Stage,
            context.ModuleName,
            context.PluginId);

        var result = await next().ConfigureAwait(false);

        if (result.Success)
        {
            logger.LogDebug(
                "Stage completed: {Stage} | Module: {ModuleName} | Duration: {Duration}ms",
                context.Stage,
                context.ModuleName,
                result.Duration.TotalMilliseconds);
        }
        else
        {
            logger.LogWarning(
                "Stage failed: {Stage} | Module: {ModuleName} | Error: {Error}",
                context.Stage,
                context.ModuleName,
                result.Exception?.Message ?? "Unknown error");
        }

        return result;
    }
}