// <copyright file="PipelineOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

using Axbus.Core.Enums;

/// <summary>
/// Controls the behaviour of the conversion pipeline for a specific module.
/// These settings govern schema discovery, error handling and data transformation
/// behaviour. Configured under <c>Pipeline</c> within a <see cref="ConversionModule"/>
/// entry in <c>appsettings.json</c>.
/// </summary>
public sealed class PipelineOptions
{
    /// <summary>
    /// Gets or sets the strategy used to discover the output column schema.
    /// Defaults to <see cref="SchemaStrategy.FullScan"/> which scans all source
    /// files before writing any output.
    /// </summary>
    public SchemaStrategy SchemaStrategy { get; set; } = SchemaStrategy.FullScan;

    /// <summary>
    /// Gets or sets the strategy used when a row-level processing error occurs.
    /// Defaults to <see cref="RowErrorStrategy.WriteToErrorFile"/>.
    /// </summary>
    public RowErrorStrategy RowErrorStrategy { get; set; } = RowErrorStrategy.WriteToErrorFile;

    /// <summary>
    /// Gets or sets the maximum depth to which nested arrays are exploded
    /// into multiple rows. Arrays nested beyond this depth are serialised
    /// as a JSON string in a single column instead.
    /// Defaults to <c>3</c>.
    /// </summary>
    public int MaxExplosionDepth { get; set; } = 3;

    /// <summary>
    /// Gets or sets the value written to output columns when the source
    /// row does not contain a value for that column.
    /// Defaults to an empty string.
    /// </summary>
    public string NullPlaceholder { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the key used to locate the root array within the source data.
    /// When <c>null</c> the framework auto-detects the root array.
    /// When set to <c>root</c> the entire root object is treated as a single record.
    /// When set to any other value the framework drills into that key to find the array.
    /// </summary>
    public string? RootArrayKey { get; set; }
}