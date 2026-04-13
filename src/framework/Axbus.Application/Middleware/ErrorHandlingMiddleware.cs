// <copyright file="ErrorHandlingMiddleware.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Middleware;

using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Pipeline middleware that catches unhandled exceptions from stage execution
/// and applies the configured <see cref="RowErrorStrategy"/>.
/// Wraps exceptions in <see cref="AxbusPipelineException"/> with stage context
/// and logs them appropriately before returning a failed <see cref="PipelineStageResult"/>.
/// </summary>
public sealed class ErrorHandlingMiddleware : IPipelineMiddleware
{
    /// <summary>
    /// Logger instance for structured error diagnostic output.
    /// </summary>
    private readonly ILogger<ErrorHandlingMiddleware> logger;

    /// <summary>
    /// The pipeline options containing the configured row error strategy.
    /// </summary>
    private readonly PipelineOptions pipelineOptions;

    /// <summary>
    /// Initializes a new instance of <see cref="ErrorHandlingMiddleware"/>.
    /// </summary>
    /// <param name="logger">The logger used for error messages.</param>
    /// <param name="pipelineOptions">The pipeline options containing the row error strategy.</param>
    public ErrorHandlingMiddleware(ILogger<ErrorHandlingMiddleware> logger, PipelineOptions pipelineOptions)
    {
        this.logger = logger;
        this.pipelineOptions = pipelineOptions;
    }

    /// <summary>
    /// Invokes the next middleware and catches any exceptions, converting them
    /// into a failed <see cref="PipelineStageResult"/> with appropriate logging.
    /// </summary>
    /// <param name="context">Contextual information about the stage being executed.</param>
    /// <param name="next">The next middleware or stage delegate in the chain.</param>
    /// <returns>
    /// The result from the next middleware on success, or a failed result on exception.
    /// </returns>
    public async Task<PipelineStageResult> InvokeAsync(
        IPipelineMiddlewareContext context,
        PipelineStageDelegate next)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(next);

        try
        {
            return await next().ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            // Always re-throw cancellation - do not treat as pipeline error
            throw;
        }
        catch (AxbusPipelineException ex)
        {
            // Domain exception - log and return failed result
            logger.LogError(
                ex,
                "Pipeline error in stage {Stage} for module {ModuleName}",
                context.Stage,
                context.ModuleName);

            return new PipelineStageResult
            {
                Success = false,
                Stage = context.Stage,
                Exception = ex,
            };
        }
        catch (Exception ex)
        {
            // Unexpected exception - wrap in domain exception and return failed result
            logger.LogError(
                ex,
                "Unexpected error in stage {Stage} for module {ModuleName}",
                context.Stage,
                context.ModuleName);

            var wrapped = new AxbusPipelineException(
                $"Unexpected failure in stage {context.Stage} for module '{context.ModuleName}'",
                context.Stage,
                ex);

            return new PipelineStageResult
            {
                Success = false,
                Stage = context.Stage,
                Exception = wrapped,
            };
        }
    }
}