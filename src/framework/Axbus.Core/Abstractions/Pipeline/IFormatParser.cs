// <copyright file="IFormatParser.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines Stage 2 of the Axbus conversion pipeline.
/// Parses the raw byte stream produced by <see cref="ISourceReader"/> into
/// a streaming sequence of parsed elements. Implementations are format-specific
/// and are provided by reader plugins, for example <c>Axbus.Plugin.Reader.Json</c>.
/// </summary>
public interface IFormatParser
{
    /// <summary>
    /// Parses the raw stream contained in <paramref name="sourceData"/>
    /// and returns a <see cref="ParsedData"/> record containing a lazy
    /// asynchronous stream of parsed elements.
    /// Elements are produced on demand and should be consumed only once.
    /// </summary>
    /// <param name="sourceData">The raw stream produced by Stage 1 (Read).</param>
    /// <param name="cancellationToken">A token to cancel the parse operation.</param>
    /// <returns>
    /// A <see cref="ParsedData"/> record containing the element stream and metadata.
    /// </returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPipelineException">
    /// Thrown when the raw stream cannot be parsed as the expected format.
    /// </exception>
    Task<ParsedData> ParseAsync(SourceData sourceData, CancellationToken cancellationToken);
}