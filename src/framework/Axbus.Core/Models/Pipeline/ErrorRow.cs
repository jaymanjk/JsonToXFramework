// <copyright file="ErrorRow.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

/// <summary>
/// Represents a row that failed to process during the conversion pipeline.
/// When <see cref="Axbus.Core.Enums.RowErrorStrategy.WriteToErrorFile"/> is configured,
/// error rows are collected and written to a separate error output file with an
/// additional <c>_AxbusError</c> column appended.
/// </summary>
public sealed class ErrorRow
{
    /// <summary>
    /// Gets or sets the original flattened row that failed to process.
    /// May be <c>null</c> if the failure occurred before flattening was complete.
    /// </summary>
    public FlattenedRow? OriginalRow { get; set; }

    /// <summary>
    /// Gets or sets a human-readable description of the error that occurred.
    /// </summary>
    public string ErrorMessage { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the path of the source file from which the failing row originated.
    /// </summary>
    public string SourceFilePath { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the one-based row number within the source file at which the error occurred.
    /// </summary>
    public int RowNumber { get; set; }

    /// <summary>
    /// Gets or sets the exception that caused the row to fail, if available.
    /// </summary>
    public Exception? Exception { get; set; }
}