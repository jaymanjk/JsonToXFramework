// <copyright file="JsonSourceReader.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Reader;

using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Implements <see cref="ISourceReader"/> for JSON source files.
/// Accepts a raw stream from the source connector and wraps it in a
/// <see cref="SourceData"/> record with JSON format metadata.
/// This reader is format-aware but I/O agnostic - it does not open
/// files directly; streams are provided by the infrastructure connector.
/// </summary>
public sealed class JsonSourceReader : ISourceReader
{
    /// <summary>
    /// Logger instance for structured reader diagnostic output.
    /// </summary>
    private readonly ILogger<JsonSourceReader> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="JsonSourceReader"/>.
    /// </summary>
    /// <param name="logger">The logger for reader operations.</param>
    public JsonSourceReader(ILogger<JsonSourceReader> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Reads the source described by <paramref name="options"/> and returns
    /// a <see cref="SourceData"/> record containing the raw stream and metadata.
    /// For the JSON reader this opens the file at <see cref="SourceOptions.Path"/>
    /// as a buffered async stream.
    /// </summary>
    /// <param name="options">The source configuration describing the file path.</param>
    /// <param name="cancellationToken">A token to cancel the read operation.</param>
    /// <returns>A <see cref="SourceData"/> record with the JSON stream and metadata.</returns>
    /// <exception cref="AxbusConnectorException">
    /// Thrown when the source file cannot be opened.
    /// </exception>
    public Task<SourceData> ReadAsync(SourceOptions options, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(options);
        ArgumentException.ThrowIfNullOrWhiteSpace(options.Path);

        logger.LogDebug("JsonSourceReader opening: {Path}", options.Path);

        try
        {
            var stream = new FileStream(
                options.Path,
                FileMode.Open,
                FileAccess.Read,
                FileShare.Read,
                bufferSize: 81920,
                useAsync: true);

            var contentLength = new FileInfo(options.Path).Length;

            var sourceData = new SourceData(
                RawData: stream,
                SourcePath: options.Path,
                Format: "json",
                ContentLength: contentLength);

            logger.LogDebug(
                "JsonSourceReader opened: {Path} ({Bytes} bytes)",
                options.Path,
                contentLength);

            return Task.FromResult(sourceData);
        }
        catch (FileNotFoundException ex)
        {
            throw new AxbusConnectorException(
                $"JSON source file not found: {options.Path}", options.Path, ex);
        }
        catch (UnauthorizedAccessException ex)
        {
            throw new AxbusConnectorException(
                $"Access denied reading JSON file: {options.Path}", options.Path, ex);
        }
        catch (IOException ex)
        {
            throw new AxbusConnectorException(
                $"I/O error opening JSON file: {options.Path}", options.Path, ex);
        }
    }
}