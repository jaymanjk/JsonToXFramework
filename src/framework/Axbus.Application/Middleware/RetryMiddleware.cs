// <copyright file="RetryMiddleware.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Middleware;

using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Pipeline middleware that retries a failed pipeline stage up to a configured
/// maximum number of attempts with an exponential backoff delay between attempts.
/// Does not retry when the failure is an <see cref="OperationCanceledException"/>.
/// </summary>
public sealed class RetryMiddleware : IPipelineMiddleware
{
    /// <summary>
    /// Logger instance for retry attempt diagnostic messages.
    /// </summary>
    private readonly ILogger<RetryMiddleware> logger;

    /// <summary>
    /// The maximum number of retry attempts after the initial failure.
    /// </summary>
    private readonly int maxRetries;

    /// <summary>
    /// The base delay between retry attempts. Doubled on each subsequent attempt.
    /// </summary>
    private readonly TimeSpan baseDelay;

    /// <summary>
    /// Initializes a new instance of <see cref="RetryMiddleware"/>.
    /// </summary>
    /// <param name="logger">The logger used for retry attempt messages.</param>
    /// <param name="maxRetries">Maximum number of retry attempts after the first failure. Defaults to 3.</param>
    /// <param name="baseDelayMs">Base delay in milliseconds between retries. Defaults to 500ms.</param>
    public RetryMiddleware(ILogger<RetryMiddleware> logger, int maxRetries = 3, int baseDelayMs = 500)
    {
        this.logger = logger;
        this.maxRetries = maxRetries;
        this.baseDelay = TimeSpan.FromMilliseconds(baseDelayMs);
    }

    /// <summary>
    /// Invokes the next middleware and retries up to <see cref="maxRetries"/> times
    /// on failure, using exponential backoff between attempts.
    /// </summary>
    /// <param name="context">Contextual information about the stage being executed.</param>
    /// <param name="next">The next middleware or stage delegate in the chain.</param>
    /// <returns>The result from the first successful invocation, or the final failure result.</returns>
    public async Task<PipelineStageResult> InvokeAsync(
        IPipelineMiddlewareContext context,
        PipelineStageDelegate next)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(next);

        var attempt = 0;

        while (true)
        {
            var result = await next().ConfigureAwait(false);

            // Return immediately on success or cancellation
            if (result.Success || result.Exception is OperationCanceledException)
            {
                return result;
            }

            attempt++;

            if (attempt > maxRetries)
            {
                // All retries exhausted - return the final failure result
                logger.LogError(
                    "Stage {Stage} failed after {Attempts} attempt(s) for module {ModuleName}",
                    context.Stage,
                    attempt,
                    context.ModuleName);
                return result;
            }

            // Calculate exponential backoff delay: baseDelay * 2^(attempt-1)
            var delay = TimeSpan.FromMilliseconds(baseDelay.TotalMilliseconds * Math.Pow(2, attempt - 1));

            logger.LogWarning(
                "Stage {Stage} failed for module {ModuleName}. Retrying attempt {Attempt}/{MaxRetries} in {DelayMs}ms",
                context.Stage,
                context.ModuleName,
                attempt,
                maxRetries,
                delay.TotalMilliseconds);

            await Task.Delay(delay).ConfigureAwait(false);
        }
    }
}