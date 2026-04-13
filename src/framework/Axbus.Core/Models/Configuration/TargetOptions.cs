// <copyright file="TargetOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

using Axbus.Core.Enums;

/// <summary>
/// Configures the target to which converted output is written for a conversion module.
/// This is a pure infrastructure concern and is independent of the output file format.
/// Configured under <c>Target</c> within a <see cref="ConversionModule"/> entry
/// in <c>appsettings.json</c>.
/// </summary>
public sealed class TargetOptions
{
    /// <summary>
    /// Gets or sets the connector type used to access the target.
    /// Built-in values: <c>FileSystem</c>.
    /// Future values: <c>AzureBlob</c>, <c>S3</c>, <c>Http</c>, <c>FTP</c>.
    /// </summary>
    public string Type { get; set; } = "FileSystem";

    /// <summary>
    /// Gets or sets the path to which output files are written.
    /// For <c>FileSystem</c> type this is the target folder path.
    /// </summary>
    public string Path { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets how output files are created.
    /// <see cref="OutputMode.SingleFile"/> merges all rows into one file.
    /// <see cref="OutputMode.OnePerFile"/> creates one output file per source file.
    /// </summary>
    public OutputMode OutputMode { get; set; } = OutputMode.SingleFile;

    /// <summary>
    /// Gets or sets the output format or combination of formats.
    /// Use the pipe operator to specify multiple formats,
    /// for example <c>OutputFormat.Csv | OutputFormat.Excel</c>.
    /// </summary>
    public OutputFormat OutputFormat { get; set; } = OutputFormat.Csv;

    /// <summary>
    /// Gets or sets the path to which error rows are written when
    /// <see cref="Axbus.Core.Models.Configuration.PipelineOptions.RowErrorStrategy"/>
    /// is set to <see cref="RowErrorStrategy.WriteToErrorFile"/>.
    /// Defaults to the same folder as <see cref="Path"/> when null or empty.
    /// </summary>
    public string? ErrorOutputPath { get; set; }

    /// <summary>
    /// Gets or sets the suffix appended to the output file name to produce
    /// the error file name. For example a suffix of <c>.errors</c> produces
    /// <c>result.errors.csv</c> alongside <c>result.csv</c>.
    /// Defaults to <c>.errors</c>.
    /// </summary>
    public string ErrorFileSuffix { get; set; } = ".errors";
}