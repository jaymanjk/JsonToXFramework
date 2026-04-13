// <copyright file="IDataTransformer.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines Stage 3 of the Axbus conversion pipeline.
/// Transforms the parsed element stream produced by <see cref="IFormatParser"/>
/// into a stream of flat <see cref="FlattenedRow"/> records.
/// Handles nested object flattening (dot-notation), array explosion and
/// depth limiting. Implemented by reader plugins.
/// </summary>
public interface IDataTransformer
{
    /// <summary>
    /// Transforms the parsed element stream into a lazy asynchronous stream
    /// of <see cref="FlattenedRow"/> records. Nested objects are flattened
    /// using dot-notation and arrays are exploded into multiple rows up to
    /// <see cref="PipelineOptions.MaxExplosionDepth"/>.
    /// </summary>
    /// <param name="parsedData">The element stream produced by Stage 2 (Parse).</param>
    /// <param name="options">The pipeline options controlling explosion depth and null handling.</param>
    /// <param name="cancellationToken">A token to cancel the transform operation.</param>
    /// <returns>
    /// A <see cref="TransformedData"/> record containing the flattened row stream.
    /// </returns>
    Task<TransformedData> TransformAsync(
        ParsedData parsedData,
        PipelineOptions options,
        CancellationToken cancellationToken);
}