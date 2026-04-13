// <copyright file="ISourceConnector.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Connectors;

using Axbus.Core.Models.Configuration;

/// <summary>
/// Defines an abstraction over the physical source of input data.
/// Source connectors are format-agnostic; they return raw byte streams
/// that are subsequently parsed by the appropriate format parser plugin.
/// The default implementation reads from the local file system.
/// Future implementations may read from Azure Blob Storage, S3, HTTP endpoints, etc.
/// </summary>
public interface ISourceConnector
{
    /// <summary>
    /// Returns an asynchronous stream of raw byte streams from the source
    /// described by <paramref name="options"/>. Each stream corresponds to
    /// one source item (for example one file on disk).
    /// </summary>
    /// <param name="options">The source configuration describing where to read from.</param>
    /// <param name="cancellationToken">A token to cancel the enumeration.</param>
    /// <returns>
    /// An asynchronous enumerable of raw <see cref="Stream"/> instances.
    /// Each stream must be disposed by the caller after use.
    /// </returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusConnectorException">
    /// Thrown when the source cannot be accessed due to an I/O or permission error.
    /// </exception>
    IAsyncEnumerable<Stream> GetSourceStreamsAsync(
        SourceOptions options,
        CancellationToken cancellationToken);
}
