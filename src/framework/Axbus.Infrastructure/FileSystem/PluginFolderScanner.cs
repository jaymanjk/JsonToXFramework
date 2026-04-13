// <copyright file="PluginFolderScanner.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.FileSystem;

using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;

/// <summary>
/// Scans the configured plugin folder for plugin DLL and manifest file pairs.
/// Returns <see cref="PluginFileSet"/> instances that the Application layer
/// can then load and validate. This scanner does NOT load assemblies or
/// read manifests - those responsibilities belong to the Application layer.
/// </summary>
public sealed class PluginFolderScanner
{
    /// <summary>
    /// Logger instance for scanner diagnostic output.
    /// </summary>
    private readonly ILogger<PluginFolderScanner> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="PluginFolderScanner"/>.
    /// </summary>
    /// <param name="logger">The logger for scanner operations.</param>
    public PluginFolderScanner(ILogger<PluginFolderScanner> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Scans <paramref name="pluginsFolderPath"/> and returns a
    /// <see cref="PluginFileSet"/> for each DLL file that has an accompanying
    /// <c>*.manifest.json</c> file in the same folder.
    /// DLL files without a manifest are logged as warnings and skipped.
    /// </summary>
    /// <param name="pluginsFolderPath">The full path to the plugins folder to scan.</param>
    /// <param name="scanSubFolders">
    /// When <c>true</c> sub-folders are also scanned.
    /// Each sub-folder is treated as a separate plugin folder.
    /// </param>
    /// <returns>
    /// An enumerable of <see cref="PluginFileSet"/> instances for valid plugin pairs.
    /// Returns an empty enumerable when the folder does not exist.
    /// </returns>
    public IEnumerable<PluginFileSet> Scan(string pluginsFolderPath, bool scanSubFolders = true)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(pluginsFolderPath);

        if (!Directory.Exists(pluginsFolderPath))
        {
            logger.LogWarning("Plugin folder not found: {PluginsFolderPath}", pluginsFolderPath);
            return Enumerable.Empty<PluginFileSet>();
        }

        var results = new List<PluginFileSet>();

        // Scan the root plugins folder
        results.AddRange(ScanFolder(pluginsFolderPath));

        // Optionally scan sub-folders (each sub-folder = one plugin)
        if (scanSubFolders)
        {
            foreach (var subFolder in Directory.GetDirectories(pluginsFolderPath))
            {
                results.AddRange(ScanFolder(subFolder));
            }
        }

        logger.LogInformation(
            "Plugin scan complete: {Count} plugin(s) found in '{Folder}'",
            results.Count,
            pluginsFolderPath);

        return results;
    }

    /// <summary>
    /// Scans a single folder for DLL + manifest pairs.
    /// </summary>
    /// <param name="folderPath">The folder path to scan.</param>
    /// <returns>Plugin file sets found in this folder.</returns>
    private IEnumerable<PluginFileSet> ScanFolder(string folderPath)
    {
        var dllFiles = Directory.GetFiles(folderPath, "*.dll", SearchOption.TopDirectoryOnly);

        foreach (var dllPath in dllFiles)
        {
            // Look for matching manifest: AssemblyName.manifest.json
            var assemblyName = Path.GetFileNameWithoutExtension(dllPath);
            var manifestPath = Path.Combine(folderPath, $"{assemblyName}.manifest.json");

            if (!File.Exists(manifestPath))
            {
                logger.LogWarning(
                    "Plugin DLL '{DllPath}' has no accompanying manifest file '{ManifestPath}'. Skipping.",
                    dllPath,
                    manifestPath);
                continue;
            }

            logger.LogDebug(
                "Plugin file pair found: {AssemblyName} in '{Folder}'",
                assemblyName,
                folderPath);

            yield return new PluginFileSet
            {
                AssemblyPath = dllPath,
                ManifestPath = manifestPath,
                PluginFolder = folderPath,
            };
        }
    }
}