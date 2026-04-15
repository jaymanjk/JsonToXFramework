// <copyright file="LocalFileSourceConnector.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Connectors;

using Axbus.Core.Abstractions.Connectors;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Microsoft.Extensions.Logging;

/// <summary>
/// Reads raw byte streams from the local file system.
/// This connector is format-agnostic and returns streams regardless of file type.
/// It is the default <see cref="ISourceConnector"/> implementation registered
/// for the <c>FileSystem</c> connector type.
/// Supports single-file and all-files read modes controlled by
/// <see cref="SourceOptions.ReadMode"/>.
/// </summary>
public sealed class LocalFileSourceConnector : ISourceConnector
{
    /// <summary>
    /// Logger instance for structured connector diagnostic output.
    /// </summary>
    private readonly ILogger<LocalFileSourceConnector> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="LocalFileSourceConnector"/>.
    /// </summary>
    /// <param name="logger">The logger for connector operations.</param>
    public LocalFileSourceConnector(ILogger<LocalFileSourceConnector> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Returns an asynchronous stream of raw byte streams from the local file system
    /// path described by <paramref name="options"/>.
    /// When <see cref="SourceOptions.ReadMode"/> is <c>AllFiles</c> all files matching
    /// <see cref="SourceOptions.FilePattern"/> in <see cref="SourceOptions.Path"/> are returned.
    /// When <see cref="SourceOptions.ReadMode"/> is <c>SingleFile</c> only the file at
    /// <see cref="SourceOptions.Path"/> is returned.
    /// </summary>
    /// <param name="options">The source configuration describing the local path and file pattern.</param>
    /// <param name="cancellationToken">A token to cancel the enumeration.</param>
    /// <returns>An asynchronous enumerable of raw file streams. Each stream must be disposed by the caller.</returns>
    /// <exception cref="AxbusConnectorException">
    /// Thrown when the path does not exist or cannot be accessed.
    /// </exception>
    public async IAsyncEnumerable<Stream> GetSourceStreamsAsync(
        SourceOptions options,
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(options);
        ArgumentException.ThrowIfNullOrWhiteSpace(options.Path);

        // Determine file paths to stream based on read mode
        var filePaths = GetFilePaths(options);

        foreach (var filePath in filePaths)
        {
            cancellationToken.ThrowIfCancellationRequested();

            logger.LogDebug("Opening source file: {FilePath}", filePath);

            Stream stream;

            try
            {
                // Open file as a read-only async stream
                stream = new FileStream(
                    filePath,
                    FileMode.Open,
                    FileAccess.Read,
                    FileShare.Read,
                    bufferSize: 81920,
                    useAsync: true);
            }
            catch (FileNotFoundException ex)
            {
                throw new AxbusConnectorException(
                    $"Source file not found: {filePath}", filePath, ex);
            }
            catch (UnauthorizedAccessException ex)
            {
                throw new AxbusConnectorException(
                    $"Access denied reading file: {filePath}", filePath, ex);
            }
            catch (IOException ex)
            {
                throw new AxbusConnectorException(
                    $"I/O error reading file: {filePath}", filePath, ex);
            }

            // Yield the stream - caller is responsible for disposal
            yield return stream;

            // Brief yield to keep the async enumerable cooperative
            await Task.Yield();
        }
    }

    /// <summary>
    /// Returns an asynchronous enumerable of file paths from the source described
    /// by <paramref name="options"/> without opening the files.
    /// </summary>
    /// <param name="options">The source configuration describing the local path and file pattern.</param>
    /// <param name="cancellationToken">A token to cancel the enumeration.</param>
    /// <returns>An asynchronous enumerable of absolute file paths.</returns>
    /// <exception cref="AxbusConnectorException">
    /// Thrown when the path does not exist or cannot be accessed.
    /// </exception>
    public async IAsyncEnumerable<string> GetSourcePathsAsync(
        SourceOptions options,
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(options);
        ArgumentException.ThrowIfNullOrWhiteSpace(options.Path);

        // Reuse the same path resolution logic as GetSourceStreamsAsync
        var filePaths = GetFilePaths(options);

        foreach (var filePath in filePaths)
        {
            cancellationToken.ThrowIfCancellationRequested();
            yield return filePath;
            await Task.Yield();
        }
    }

    /// <summary>
    /// Determines the list of file paths to process based on the source options.
    /// </summary>
    /// <param name="options">The source options containing path and file pattern.</param>
    /// <returns>An enumerable of absolute file paths to process.</returns>
    /// <exception cref="AxbusConnectorException">
    /// Thrown when the specified path does not exist.
    /// </exception>
    private IEnumerable<string> GetFilePaths(SourceOptions options)
    {
        // SingleFile mode: treat Path as a direct file path
        if (string.Equals(options.ReadMode, "SingleFile", StringComparison.OrdinalIgnoreCase))
        {
            if (!File.Exists(options.Path))
            {
                throw new AxbusConnectorException(
                    $"Source file not found: {options.Path}", options.Path);
            }

            logger.LogDebug("SingleFile mode: {FilePath}", options.Path);
            return new[] { options.Path };
        }

        // AllFiles mode: enumerate all matching files in the folder
        if (!Directory.Exists(options.Path))
        {
            throw new AxbusConnectorException(
                $"Source folder not found: {options.Path}", options.Path);
        }

        var pattern = string.IsNullOrWhiteSpace(options.FilePattern) ? "*.*" : options.FilePattern;
        var files = Directory.GetFiles(options.Path, pattern, SearchOption.TopDirectoryOnly);

        logger.LogDebug(
            "AllFiles mode: Found {Count} files matching '{Pattern}' in '{Path}'",
            files.Length,
            pattern,
            options.Path);

        return files.OrderBy(f => f);
    }
}
