// <copyright file="JsonReaderOptionsValidator.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Validators;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Plugin.Reader.Json.Options;

/// <summary>
/// Validates <see cref="JsonReaderPluginOptions"/> before the
/// JSON reader plugin is initialised. Checks that
/// <see cref="JsonReaderPluginOptions.MaxExplosionDepth"/> is within
/// an acceptable range and that any provided
/// <see cref="JsonReaderPluginOptions.RootArrayKey"/> is not whitespace-only.
/// </summary>
public sealed class JsonReaderOptionsValidator : IPluginOptionsValidator
{
    /// <summary>
    /// The minimum permitted value for <see cref="JsonReaderPluginOptions.MaxExplosionDepth"/>.
    /// </summary>
    private const int MinExplosionDepth = 1;

    /// <summary>
    /// The maximum permitted value for <see cref="JsonReaderPluginOptions.MaxExplosionDepth"/>.
    /// </summary>
    private const int MaxExplosionDepth = 20;

    /// <summary>
    /// Validates the specified <paramref name="options"/> instance.
    /// </summary>
    /// <param name="options">The options instance to validate.</param>
    /// <returns>
    /// An empty enumerable when options are valid, or one or more
    /// error messages when options are invalid.
    /// </returns>
    public IEnumerable<string> Validate(IPluginOptions options)
    {
        if (options is not JsonReaderPluginOptions jsonOptions)
        {
            yield return $"Expected options of type {nameof(JsonReaderPluginOptions)} " +
                         $"but received {options?.GetType().Name ?? "null"}.";
            yield break;
        }

        if (jsonOptions.MaxExplosionDepth < MinExplosionDepth ||
            jsonOptions.MaxExplosionDepth > MaxExplosionDepth)
        {
            yield return $"{nameof(JsonReaderPluginOptions.MaxExplosionDepth)} must be " +
                         $"between {MinExplosionDepth} and {MaxExplosionDepth}. " +
                         $"Current value: {jsonOptions.MaxExplosionDepth}.";
        }

        if (jsonOptions.RootArrayKey != null &&
            string.IsNullOrWhiteSpace(jsonOptions.RootArrayKey))
        {
            yield return $"{nameof(JsonReaderPluginOptions.RootArrayKey)} must not be " +
                         "whitespace-only. Set to null for auto-detection.";
        }
    }
}