// <copyright file="SourceData.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

/// <summary>
/// Immutable record representing the output of pipeline Stage 1 (Read).
/// Contains the raw byte stream from the source connector together with
/// metadata about the source. Passed as input to Stage 2 (Parse).
/// </summary>
/// <param name="RawData">
/// The raw byte stream read from the source connector.
/// The caller is responsible for disposing this stream.
/// </param>
/// <param name="SourcePath">The path or URI of the source resource.</param>
/// <param name="Format">The format identifier of the source data, for example <c>json</c>.</param>
/// <param name="ContentLength">The content length in bytes, or <c>-1</c> if unknown.</param>
public sealed record SourceData(
    Stream RawData,
    string SourcePath,
    string Format,
    long ContentLength = -1);