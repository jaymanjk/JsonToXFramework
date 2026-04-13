// <copyright file="MiddlewareFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Factories;

using Axbus.Application.Middleware;
using Axbus.Core.Abstractions.Factories;
using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Models.Configuration;
using Microsoft.Extensions.Logging;

/// <summary>
/// Resolves and orders the middleware chain applied to each pipeline stage execution.
/// The default chain is: <see cref="LoggingMiddleware"/> (outermost)
/// -> <see cref="TimingMiddleware"/> -> <see cref="ErrorHandlingMiddleware"/> (innermost).
/// This ordering ensures that logging captures the total duration including error handling,
/// and that timing is accurate for the actual stage work.
/// </summary>
public sealed class MiddlewareFactory : IMiddlewareFactory
{
    /// <summary>
    /// Logger factory used to create loggers for each middleware component.
    /// </summary>
    private readonly ILoggerFactory loggerFactory;

    /// <summary>
    /// The pipeline options containing the row error strategy for error handling middleware.
    /// </summary>
    private readonly PipelineOptions pipelineOptions;

    /// <summary>
    /// Initializes a new instance of <see cref="MiddlewareFactory"/>.
    /// </summary>
    /// <param name="loggerFactory">Factory for creating typed loggers per middleware.</param>
    /// <param name="pipelineOptions">Pipeline options for the error handling middleware.</param>
    public MiddlewareFactory(ILoggerFactory loggerFactory, PipelineOptions pipelineOptions)
    {
        this.loggerFactory = loggerFactory;
        this.pipelineOptions = pipelineOptions;
    }

    /// <summary>
    /// Creates the ordered middleware chain for pipeline stage execution.
    /// Components are listed outermost first.
    /// </summary>
    /// <returns>An ordered read-only list of middleware components.</returns>
    public IReadOnlyList<IPipelineMiddleware> Create()
    {
        return new List<IPipelineMiddleware>
        {
            // Outermost: logging wraps everything so it records total time including errors
            new LoggingMiddleware(loggerFactory.CreateLogger<LoggingMiddleware>()),

            // Timing: measures elapsed time for the stage and all inner middleware
            new TimingMiddleware(),

            // Innermost: error handling catches exceptions from the stage itself
            new ErrorHandlingMiddleware(
                loggerFactory.CreateLogger<ErrorHandlingMiddleware>(),
                pipelineOptions),
        };
    }
}