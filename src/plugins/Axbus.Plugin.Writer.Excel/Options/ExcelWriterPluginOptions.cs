// <copyright file="ExcelWriterPluginOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Options;

using System.Text.Json;
using System.Text.Json.Serialization;
using Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Strongly-typed options for the <c>Axbus.Plugin.Writer.Excel</c> plugin.
/// Deserialised from the <c>PluginOptions</c> section of a conversion module.
/// Unknown JSON keys are captured in <see cref="AdditionalOptions"/>.
/// </summary>
public sealed class ExcelWriterPluginOptions : IPluginOptions
{
    /// <summary>
    /// Gets or sets the name of the worksheet created in the output workbook.
    /// Defaults to <c>Sheet1</c>. Excel worksheet names must be 31 characters
    /// or fewer and must not contain the characters <c>: \ / ? * [ ]</c>.
    /// </summary>
    public string SheetName { get; set; } = "Sheet1";

    /// <summary>
    /// Gets or sets a value indicating whether column widths are automatically
    /// adjusted to fit the content of each column.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool AutoFit { get; set; } = true;

    /// <summary>
    /// Gets or sets a value indicating whether the header row is formatted
    /// with bold text to distinguish it from data rows.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool BoldHeaders { get; set; } = true;

    /// <summary>
    /// Gets or sets a value indicating whether the header row is frozen so
    /// that it remains visible when scrolling through data rows.
    /// Defaults to <c>true</c>.
    /// </summary>
    public bool FreezeHeader { get; set; } = true;

    /// <summary>
    /// Gets or sets additional options not declared as explicit properties.
    /// Populated automatically for any unrecognised keys in <c>PluginOptions</c>.
    /// </summary>
    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalOptions { get; set; }
}