// <copyright file="ISourceReader.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines Stage 1 of the Axbus conversion pipeline.
/// Reads raw data from the source connector and returns it as a byte stream.
/// Implementations are format-agnostic and work with raw bytes only.
/// Implemented by reader plugins, for example <c>Axbus.Plugin.Reader.Json</c>.
/// </summary>
public interface ISourceReader
{
    /// <summary>
    /// Reads raw data from the source described by <paramref name="options"/>
    /// and returns it as a <see cref="SourceData"/> record containing the stream
    /// and metadata. The caller is responsible for disposing the stream.
    /// </summary>
    /// <param name="options">The source configuration describing where to read from.</param>
    /// <param name="cancellationToken">A token to cancel the read operation.</param>
    /// <returns>
    /// A <see cref="SourceData"/> record containing the raw stream and source metadata.
    /// </returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusConnectorException">
    /// Thrown when the source cannot be read due to an I/O or access error.
    /// </exception>
    Task<SourceData> ReadAsync(SourceOptions options, CancellationToken cancellationToken);
}