// <copyright file="IPluginManifestReader.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

using Axbus.Core.Models.Plugin;

/// <summary>
/// Deserialises a plugin manifest file (<c>*.manifest.json</c>) into a
/// <see cref="PluginManifest"/> model. The manifest is read before the
/// plugin assembly is loaded so that version compatibility can be checked
/// without incurring the cost of loading the full assembly.
/// </summary>
public interface IPluginManifestReader
{
    /// <summary>
    /// Reads and deserialises the manifest file at <paramref name="manifestPath"/>.
    /// </summary>
    /// <param name="manifestPath">The full path to the <c>*.manifest.json</c> file.</param>
    /// <param name="cancellationToken">A token to cancel the read operation.</param>
    /// <returns>A <see cref="PluginManifest"/> populated from the manifest file.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPluginException">
    /// Thrown when the manifest file cannot be read or is malformed.
    /// </exception>
    Task<PluginManifest> ReadAsync(string manifestPath, CancellationToken cancellationToken);
}