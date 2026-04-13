// <copyright file="ITargetConnector.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Connectors;

using Axbus.Core.Models.Configuration;

/// <summary>
/// Defines an abstraction over the physical target for output data.
/// Target connectors are format-agnostic; they accept a raw byte stream
/// from the writer plugin and persist it to the target location.
/// The default implementation writes to the local file system.
/// Future implementations may write to Azure Blob Storage, S3, FTP, etc.
/// </summary>
public interface ITargetConnector
{
    /// <summary>
    /// Writes the raw byte stream in <paramref name="data"/> to the target
    /// described by <paramref name="options"/> using the provided
    /// <paramref name="fileName"/> as the output file name.
    /// </summary>
    /// <param name="data">The raw output byte stream to persist.</param>
    /// <param name="fileName">The file name (without path) to use for the output.</param>
    /// <param name="options">The target configuration describing where to write.</param>
    /// <param name="cancellationToken">A token to cancel the write operation.</param>
    /// <returns>The full path or URI of the persisted output.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusConnectorException">
    /// Thrown when the target cannot be written to due to an I/O or permission error.
    /// </exception>
    Task<string> WriteAsync(
        Stream data,
        string fileName,
        TargetOptions options,
        CancellationToken cancellationToken);
}