// <copyright file="LocalFileTargetConnector.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Connectors;

using Axbus.Core.Abstractions.Connectors;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Microsoft.Extensions.Logging;

/// <summary>
/// Writes raw byte streams to the local file system.
/// This connector is format-agnostic and writes any stream to disk.
/// It is the default <see cref="ITargetConnector"/> implementation registered
/// for the <c>FileSystem</c> connector type.
/// Creates the target directory if it does not already exist.
/// </summary>
public sealed class LocalFileTargetConnector : ITargetConnector
{
    /// <summary>
    /// Logger instance for structured connector diagnostic output.
    /// </summary>
    private readonly ILogger<LocalFileTargetConnector> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="LocalFileTargetConnector"/>.
    /// </summary>
    /// <param name="logger">The logger for connector operations.</param>
    public LocalFileTargetConnector(ILogger<LocalFileTargetConnector> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Writes the raw byte stream <paramref name="data"/> to the local file system
    /// folder described by <paramref name="options"/> using <paramref name="fileName"/>
    /// as the output file name. Creates the target folder if it does not exist.
    /// </summary>
    /// <param name="data">The raw output byte stream to write to disk.</param>
    /// <param name="fileName">The output file name (without path).</param>
    /// <param name="options">The target configuration describing the output folder path.</param>
    /// <param name="cancellationToken">A token to cancel the write operation.</param>
    /// <returns>The full path of the written output file.</returns>
    /// <exception cref="AxbusConnectorException">
    /// Thrown when the output file cannot be written due to an I/O or access error.
    /// </exception>
    public async Task<string> WriteAsync(
        Stream data,
        string fileName,
        TargetOptions options,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(data);
        ArgumentException.ThrowIfNullOrWhiteSpace(fileName);
        ArgumentNullException.ThrowIfNull(options);
        ArgumentException.ThrowIfNullOrWhiteSpace(options.Path);

        // Ensure the target directory exists
        try
        {
            if (!Directory.Exists(options.Path))
            {
                Directory.CreateDirectory(options.Path);
                logger.LogDebug("Created target directory: {Path}", options.Path);
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            throw new AxbusConnectorException(
                $"Failed to create target directory: {options.Path}", options.Path, ex);
        }

        // Build the full output file path
        var outputPath = Path.Combine(options.Path, fileName);

        logger.LogDebug("Writing output file: {OutputPath}", outputPath);

        try
        {
            // Create file stream with async I/O enabled
            var fileStream = new FileStream(
                outputPath,
                FileMode.Create,
                FileAccess.Write,
                FileShare.None,
                bufferSize: 81920,
                useAsync: true);

            await using (fileStream.ConfigureAwait(false))
            {
                await data.CopyToAsync(fileStream, cancellationToken).ConfigureAwait(false);
            }
        }
        catch (UnauthorizedAccessException ex)
        {
            throw new AxbusConnectorException(
                $"Access denied writing to: {outputPath}", outputPath, ex);
        }
        catch (IOException ex)
        {
            throw new AxbusConnectorException(
                $"I/O error writing to: {outputPath}", outputPath, ex);
        }

        logger.LogInformation("Output file written: {OutputPath}", outputPath);

        return outputPath;
    }
}
