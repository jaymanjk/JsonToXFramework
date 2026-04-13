// <copyright file="CsvWriterOptionsValidator.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Validators;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Plugin.Writer.Csv.Options;

/// <summary>
/// Validates <see cref="CsvWriterPluginOptions"/> before the CSV writer
/// plugin is initialised. Checks that the delimiter is a valid single
/// character and that the encoding name is recognisable.
/// </summary>
public sealed class CsvWriterOptionsValidator : IPluginOptionsValidator
{
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
        if (options is not CsvWriterPluginOptions csvOptions)
        {
            yield return $"Expected {nameof(CsvWriterPluginOptions)} " +
                         $"but received {options?.GetType().Name ?? "null"}.";
            yield break;
        }

        if (csvOptions.Delimiter == '\0')
        {
            yield return $"{nameof(CsvWriterPluginOptions.Delimiter)} must not be a null character.";
        }

        if (string.IsNullOrWhiteSpace(csvOptions.Encoding))
        {
            yield return $"{nameof(CsvWriterPluginOptions.Encoding)} must not be empty.";
            yield break;
        }

        // Validate encoding name by attempting to get the encoding instance
        var encodingError = ValidateEncodingName(csvOptions.Encoding);
        if (encodingError != null)
        {
            yield return encodingError;
        }
    }

    /// <summary>
    /// Validates that the encoding name is recognised by the system.
    /// </summary>
    /// <param name="encodingName">The encoding name to validate.</param>
    /// <returns>An error message if invalid; otherwise <c>null</c>.</returns>
    private static string? ValidateEncodingName(string encodingName)
    {
        try
        {
            System.Text.Encoding.GetEncoding(encodingName);
            return null;
        }
        catch (ArgumentException)
        {
            return $"'{encodingName}' is not a recognised encoding name. " +
                   "Common values: UTF-8, UTF-16, ASCII.";
        }
    }
}
