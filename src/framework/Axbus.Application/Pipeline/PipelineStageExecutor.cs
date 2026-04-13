// <copyright file="PipelineStageExecutor.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Pipeline;

using Axbus.Application.Middleware;
using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Enums;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Executes a single pipeline stage wrapped in the middleware chain.
/// Creates the <see cref="PipelineMiddlewareContext"/> for the stage,
/// builds the middleware chain via <see cref="MiddlewarePipelineBuilder"/>
/// and invokes the stage action. Used by <see cref="ConversionPipeline"/>
/// to execute each stage uniformly.
/// </summary>
public sealed class PipelineStageExecutor
{
    /// <summary>
    /// Logger instance for structured diagnostic output.
    /// </summary>
    private readonly ILogger<PipelineStageExecutor> logger;

    /// <summary>
    /// The ordered list of middleware components applied to each stage.
    /// </summary>
    private readonly IReadOnlyList<IPipelineMiddleware> middleware;

    /// <summary>
    /// Initializes a new instance of <see cref="PipelineStageExecutor"/>.
    /// </summary>
    /// <param name="logger">The logger for stage execution messages.</param>
    /// <param name="middleware">The ordered middleware components to apply to each stage.</param>
    public PipelineStageExecutor(
        ILogger<PipelineStageExecutor> logger,
        IReadOnlyList<IPipelineMiddleware> middleware)
    {
        this.logger = logger;
        this.middleware = middleware;
    }

    /// <summary>
    /// Executes <paramref name="stageAction"/> for the specified stage
    /// wrapped in the full middleware chain.
    /// </summary>
    /// <typeparam name="TResult">The type of the stage output object.</typeparam>
    /// <param name="moduleName">The name of the conversion module being executed.</param>
    /// <param name="pluginId">The identifier of the plugin executing this stage.</param>
    /// <param name="stage">The pipeline stage being executed.</param>
    /// <param name="stageAction">The actual stage logic to execute at the innermost position.</param>
    /// <param name="cancellationToken">A token to cancel the stage execution.</param>
    /// <returns>The output of type <typeparamref name="TResult"/> produced by the stage.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPipelineException">
    /// Thrown when the stage fails and the error handling middleware determines it is unrecoverable.
    /// </exception>
    public async Task<TResult> ExecuteAsync<TResult>(
        string moduleName,
        string pluginId,
        PipelineStage stage,
        Func<Task<TResult>> stageAction,
        CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(moduleName);
        ArgumentNullException.ThrowIfNull(stageAction);

        // Create context for this stage execution
        var context = new PipelineMiddlewareContext(moduleName, pluginId, stage);

        // Build and execute the middleware chain
        var builder = new MiddlewarePipelineBuilder(middleware);

        var stageResult = await builder.ExecuteAsync(context, async () =>
        {
            try
            {
                var output = await stageAction().ConfigureAwait(false);
                return new PipelineStageResult
                {
                    Success = true,
                    Stage = stage,
                    Output = output,
                };
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                return new PipelineStageResult
                {
                    Success = false,
                    Stage = stage,
                    Exception = ex,
                };
            }
        }).ConfigureAwait(false);

        if (!stageResult.Success)
        {
            throw stageResult.Exception
                ?? new Axbus.Core.Exceptions.AxbusPipelineException(
                    $"Stage {stage} failed for module '{moduleName}'", stage);
        }

        return (TResult)stageResult.Output!;
    }
}