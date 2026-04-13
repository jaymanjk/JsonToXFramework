// <copyright file="ParsedData.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

using System.Text.Json;

/// <summary>
/// Immutable record representing the output of pipeline Stage 2 (Parse).
/// Contains a streaming sequence of parsed elements together with metadata
/// about the source format. Passed as input to Stage 3 (Transform).
/// Elements are produced lazily and should be consumed only once.
/// </summary>
/// <param name="Elements">
/// An asynchronous stream of parsed <see cref="JsonElement"/> values.
/// Each element represents one top-level item from the source data.
/// </param>
/// <param name="SourcePath">The path or URI of the source resource.</param>
/// <param name="Format">The format identifier of the parsed data, for example <c>json</c>.</param>
/// <param name="EstimatedElementCount">
/// An estimated count of elements in the stream, or <c>-1</c> if unknown.
/// Used for progress reporting only and may not be exact.
/// </param>
public sealed record ParsedData(
    IAsyncEnumerable<JsonElement> Elements,
    string SourcePath,
    string Format,
    int EstimatedElementCount = -1);