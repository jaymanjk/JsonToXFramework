// <copyright file="PipelineStageResult.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

using Axbus.Core.Enums;

/// <summary>
/// Wraps the result of a single pipeline stage execution.
/// Used by <see cref="Axbus.Core.Abstractions.Middleware.IPipelineMiddleware"/>
/// implementations to carry success/failure state, the stage output object,
/// and timing information through the middleware chain.
/// </summary>
public sealed class PipelineStageResult
{
    /// <summary>
    /// Gets or sets a value indicating whether the stage completed successfully.
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// Gets or sets the output object produced by the stage.
    /// The actual type depends on the stage:
    /// <see cref="PipelineStage.Read"/> produces <see cref="SourceData"/>,
    /// <see cref="PipelineStage.Parse"/> produces <see cref="ParsedData"/>, and so on.
    /// </summary>
    public object? Output { get; set; }

    /// <summary>
    /// Gets or sets the exception that caused the stage to fail, if applicable.
    /// <c>null</c> when <see cref="Success"/> is <c>true</c>.
    /// </summary>
    public Exception? Exception { get; set; }

    /// <summary>
    /// Gets or sets the elapsed time taken to execute this stage.
    /// </summary>
    public TimeSpan Duration { get; set; }

    /// <summary>
    /// Gets or sets the pipeline stage that produced this result.
    /// </summary>
    public PipelineStage Stage { get; set; }
}