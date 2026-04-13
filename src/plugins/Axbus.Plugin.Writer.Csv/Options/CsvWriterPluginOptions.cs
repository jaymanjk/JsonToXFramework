// <copyright file="CsvWriterPluginOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Options;

using System.Text.Json;
using System.Text.Json.Serialization;
using Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Strongly-typed options for the <c>Axbus.Plugin.Writer.Csv</c> plugin.
/// Deserialised from the <c>PluginOptions</c> section of a conversion module
/// at runtime. Unknown JSON keys are captured in <see cref="AdditionalOptions"/>.
/// </summary>
public sealed class CsvWriterPluginOptions : IPluginOptions
{
    /// <summary>
    /// Gets or sets the column delimiter character used to separate field values.
    /// Defaults to <c>,</c> (comma) for standard RFC 4180 CSV format.
    /// Use <c>;</c> for European locale compatibility or <c>\t</c> for TSV format.
    /// </summary>
    public char Delimiter { get; set; } = ',';

    /// <summary>
    /// Gets or sets the text encoding name for the output file.
    /// Defaults to <c>UTF-8</c>. Common alternatives: <c>UTF-16</c>, <c>ASCII</c>.
    /// </summary>
    public string Encoding { get; set; } = "UTF-8";

    /// <summary>
    /// Gets or sets a value indicating whether a header row containing
    /// column names is written as the first row of the output file.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool IncludeHeader { get; set; } = true;

    /// <summary>
    /// Gets or sets additional options not declared as explicit properties.
    /// Populated automatically for any unrecognised keys in <c>PluginOptions</c>.
    /// </summary>
    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalOptions { get; set; }
}