// <copyright file="AxbusPipelineException.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Exceptions;

using Axbus.Core.Enums;

/// <summary>
/// Represents an error that occurs within the Axbus conversion pipeline.
/// This exception is thrown when a pipeline stage fails in a way that
/// cannot be handled by the configured
/// <see cref="RowErrorStrategy"/>.
/// </summary>
public sealed class AxbusPipelineException : Exception
{
    /// <summary>
    /// Gets the pipeline stage at which the failure occurred.
    /// </summary>
    public PipelineStage Stage { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusPipelineException"/>
    /// with a specified error message.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    public AxbusPipelineException(string message)
        : base(message)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusPipelineException"/>
    /// with a specified error message and a reference to the inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="innerException">The exception that caused this exception.</param>
    public AxbusPipelineException(string message, Exception innerException)
        : base(message, innerException)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusPipelineException"/>
    /// with a specified error message, the pipeline stage, and an optional inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="stage">The pipeline stage at which the failure occurred.</param>
    /// <param name="innerException">The exception that caused this exception, or null.</param>
    public AxbusPipelineException(string message, PipelineStage stage, Exception? innerException = null)
        : base(message, innerException)
    {
        Stage = stage;
    }
}