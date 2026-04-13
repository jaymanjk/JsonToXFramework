// <copyright file="TransformedData.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

/// <summary>
/// Immutable record representing the output of pipeline Stage 3 (Transform).
/// Contains a streaming sequence of flattened rows ready for optional
/// validation and filtering before being passed to Stage 4 (Write).
/// Rows are produced lazily and should be consumed only once.
/// </summary>
/// <param name="Rows">
/// An asynchronous stream of <see cref="FlattenedRow"/> values.
/// Each row represents one record ready for output.
/// </param>
/// <param name="SourcePath">The path or URI of the source resource.</param>
/// <param name="EstimatedRowCount">
/// An estimated count of rows in the stream, or <c>-1</c> if unknown.
/// Used for progress reporting only and may not be exact.
/// </param>
public sealed record TransformedData(
    IAsyncEnumerable<FlattenedRow> Rows,
    string SourcePath,
    int EstimatedRowCount = -1);