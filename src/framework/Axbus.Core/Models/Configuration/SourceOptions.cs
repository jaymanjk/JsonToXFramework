// <copyright file="SourceOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

/// <summary>
/// Configures the source from which input data is read for a conversion module.
/// This is a pure infrastructure concern and is independent of the source file format.
/// Configured under <c>Source</c> within a <see cref="ConversionModule"/> entry
/// in <c>appsettings.json</c>.
/// </summary>
public sealed class SourceOptions
{
    /// <summary>
    /// Gets or sets the connector type used to access the source.
    /// Built-in values: <c>FileSystem</c>.
    /// Future values: <c>AzureBlob</c>, <c>S3</c>, <c>Http</c>, <c>FTP</c>.
    /// </summary>
    public string Type { get; set; } = "FileSystem";

    /// <summary>
    /// Gets or sets the path to the source data.
    /// For <c>FileSystem</c> type this is the folder path containing source files.
    /// </summary>
    public string Path { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the file pattern used to filter source files.
    /// Supports wildcards, for example <c>*.json</c> or <c>orders_*.json</c>.
    /// Defaults to <c>*.*</c> (all files).
    /// </summary>
    public string FilePattern { get; set; } = "*.*";

    /// <summary>
    /// Gets or sets the read mode controlling how files are selected.
    /// Supported values: <c>AllFiles</c>, <c>SingleFile</c>.
    /// Defaults to <c>AllFiles</c>.
    /// </summary>
    public string ReadMode { get; set; } = "AllFiles";
}