// <copyright file="PluginManifestReader.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using System.Text.Json;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;

/// <summary>
/// Reads and deserialises a plugin manifest file (<c>*.manifest.json</c>)
/// into a <see cref="PluginManifest"/> model. The manifest is read before
/// the plugin assembly is loaded so that version compatibility can be checked
/// without incurring the cost of loading the full assembly.
/// </summary>
public sealed class PluginManifestReader : IPluginManifestReader
{
    /// <summary>
    /// Logger instance for manifest reading diagnostic messages.
    /// </summary>
    private readonly ILogger<PluginManifestReader> logger;

    /// <summary>
    /// JSON serializer options configured for case-insensitive property matching.
    /// </summary>
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    /// <summary>
    /// Initializes a new instance of <see cref="PluginManifestReader"/>.
    /// </summary>
    /// <param name="logger">The logger for manifest reading messages.</param>
    public PluginManifestReader(ILogger<PluginManifestReader> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Reads and deserialises the manifest file at <paramref name="manifestPath"/>.
    /// </summary>
    /// <param name="manifestPath">The full path to the <c>*.manifest.json</c> file.</param>
    /// <param name="cancellationToken">A token to cancel the read operation.</param>
    /// <returns>A <see cref="PluginManifest"/> populated from the manifest file.</returns>
    /// <exception cref="AxbusPluginException">
    /// Thrown when the manifest file cannot be read or contains invalid JSON.
    /// </exception>
    public async Task<PluginManifest> ReadAsync(string manifestPath, CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(manifestPath);

        if (!File.Exists(manifestPath))
        {
            throw new AxbusPluginException(
                $"Manifest file not found: {manifestPath}",
                Path.GetFileNameWithoutExtension(manifestPath));
        }

        logger.LogDebug("Reading plugin manifest: {ManifestPath}", manifestPath);

        try
        {
            await using var stream = File.OpenRead(manifestPath);
            var manifest = await JsonSerializer.DeserializeAsync<PluginManifest>(
                stream,
                SerializerOptions,
                cancellationToken).ConfigureAwait(false);

            if (manifest == null)
            {
                throw new AxbusPluginException(
                    $"Manifest file is empty or could not be deserialised: {manifestPath}",
                    Path.GetFileNameWithoutExtension(manifestPath));
            }

            logger.LogDebug(
                "Manifest read successfully: {PluginId} v{Version}",
                manifest.PluginId,
                manifest.Version);

            return manifest;
        }
        catch (JsonException ex)
        {
            throw new AxbusPluginException(
                $"Manifest file contains invalid JSON: {manifestPath}",
                Path.GetFileNameWithoutExtension(manifestPath),
                ex);
        }
        catch (AxbusPluginException)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw new AxbusPluginException(
                $"Failed to read manifest file: {manifestPath}",
                Path.GetFileNameWithoutExtension(manifestPath),
                ex);
        }
    }
}