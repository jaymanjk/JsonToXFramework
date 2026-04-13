// <copyright file="JsonReaderPluginOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Options;

using System.Text.Json;
using System.Text.Json.Serialization;
using Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Strongly-typed options for the <c>Axbus.Plugin.Reader.Json</c> plugin.
/// These options are deserialised from the <c>PluginOptions</c> section of
/// a <see cref="Axbus.Core.Models.Configuration.ConversionModule"/> at runtime.
/// Unknown JSON keys are captured in <see cref="AdditionalOptions"/> via
/// <see cref="JsonExtensionDataAttribute"/>.
/// </summary>
public sealed class JsonReaderPluginOptions : IPluginOptions
{
    /// <summary>
    /// Gets or sets the key used to locate the root array within the JSON document.
    /// <list type="bullet">
    /// <item><c>null</c> (default) - auto-detect the first array in the document.</item>
    /// <item><c>"root"</c> - treat the entire root object as a single record.</item>
    /// <item>Any other value - drill into that key to locate the array.</item>
    /// </list>
    /// </summary>
    public string? RootArrayKey { get; set; }

    /// <summary>
    /// Gets or sets the maximum depth to which nested arrays are exploded
    /// into multiple rows. Arrays nested beyond this depth are serialised
    /// as a JSON string in a single column.
    /// Defaults to <c>3</c>.
    /// </summary>
    public int MaxExplosionDepth { get; set; } = 3;

    /// <summary>
    /// Gets or sets the string written to output columns when the source
    /// element does not contain a value for that field.
    /// Defaults to an empty string.
    /// </summary>
    public string NullPlaceholder { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets additional options that are not declared as explicit properties.
    /// Populated automatically by the JSON deserialiser for any unrecognised keys
    /// in the <c>PluginOptions</c> configuration section.
    /// </summary>
    [JsonExtensionData]
    public Dictionary<string, JsonElement>? AdditionalOptions { get; set; }
}