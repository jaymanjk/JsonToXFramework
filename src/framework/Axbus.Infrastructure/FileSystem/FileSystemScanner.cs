// <copyright file="FileSystemScanner.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.FileSystem;

using Microsoft.Extensions.Logging;

/// <summary>
/// Scans folders on the local file system and returns matching file paths.
/// This scanner is format-agnostic and works with any file type.
/// Used by connectors and the plugin folder scanner to discover files
/// before they are opened as streams.
/// </summary>
public sealed class FileSystemScanner
{
    /// <summary>
    /// Logger instance for structured scanner diagnostic output.
    /// </summary>
    private readonly ILogger<FileSystemScanner> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="FileSystemScanner"/>.
    /// </summary>
    /// <param name="logger">The logger for scanner operations.</param>
    public FileSystemScanner(ILogger<FileSystemScanner> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Scans <paramref name="folderPath"/> for files matching <paramref name="pattern"/>
    /// and returns their absolute paths in alphabetical order.
    /// </summary>
    /// <param name="folderPath">The full path to the folder to scan.</param>
    /// <param name="pattern">
    /// The file name pattern to match, for example <c>*.json</c> or <c>*.*</c>.
    /// Defaults to <c>*.*</c> when null or empty.
    /// </param>
    /// <param name="recursive">
    /// When <c>true</c> sub-folders are also scanned.
    /// Defaults to <c>false</c>.
    /// </param>
    /// <returns>
    /// An alphabetically ordered enumerable of absolute file paths matching the pattern.
    /// Returns an empty enumerable when the folder does not exist.
    /// </returns>
    public IEnumerable<string> Scan(string folderPath, string? pattern = null, bool recursive = false)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(folderPath);

        if (!Directory.Exists(folderPath))
        {
            logger.LogWarning("Scan folder not found: {FolderPath}", folderPath);
            return Enumerable.Empty<string>();
        }

        var effectivePattern = string.IsNullOrWhiteSpace(pattern) ? "*.*" : pattern;
        var searchOption = recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;

        var files = Directory.GetFiles(folderPath, effectivePattern, searchOption)
            .OrderBy(f => f)
            .ToList();

        logger.LogDebug(
            "Scan complete: {Count} file(s) matching '{Pattern}' in '{Folder}' (recursive: {Recursive})",
            files.Count,
            effectivePattern,
            folderPath,
            recursive);

        return files;
    }

    /// <summary>
    /// Determines whether the specified <paramref name="folderPath"/> exists
    /// and contains at least one file matching <paramref name="pattern"/>.
    /// </summary>
    /// <param name="folderPath">The full path to the folder to check.</param>
    /// <param name="pattern">The file name pattern to match. Defaults to <c>*.*</c>.</param>
    /// <returns><c>true</c> if the folder exists and contains matching files; otherwise <c>false</c>.</returns>
    public static bool HasFiles(string folderPath, string? pattern = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(folderPath);

        if (!Directory.Exists(folderPath))
        {
            return false;
        }

        var effectivePattern = string.IsNullOrWhiteSpace(pattern) ? "*.*" : pattern;
        return Directory.EnumerateFiles(folderPath, effectivePattern, SearchOption.TopDirectoryOnly).Any();
    }
}
