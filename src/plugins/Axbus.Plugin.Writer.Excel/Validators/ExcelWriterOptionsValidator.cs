// <copyright file="ExcelWriterOptionsValidator.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Validators;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Plugin.Writer.Excel.Options;

/// <summary>
/// Validates <see cref="ExcelWriterPluginOptions"/> before the Excel writer
/// plugin is initialised. Checks that the worksheet name is valid per
/// Excel naming rules (max 31 chars, no forbidden characters).
/// </summary>
public sealed class ExcelWriterOptionsValidator : IPluginOptionsValidator
{
    /// <summary>
    /// Characters that are not permitted in Excel worksheet names.
    /// </summary>
    private static readonly char[] ForbiddenSheetNameChars = { ':', '\\', '/', '?', '*', '[', ']' };

    /// <summary>
    /// Maximum length for an Excel worksheet name.
    /// </summary>
    private const int MaxSheetNameLength = 31;

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
        if (options is not ExcelWriterPluginOptions excelOptions)
        {
            yield return $"Expected {nameof(ExcelWriterPluginOptions)} " +
                         $"but received {options?.GetType().Name ?? "null"}.";
            yield break;
        }

        if (string.IsNullOrWhiteSpace(excelOptions.SheetName))
        {
            yield return $"{nameof(ExcelWriterPluginOptions.SheetName)} must not be empty.";
            yield break;
        }

        if (excelOptions.SheetName.Length > MaxSheetNameLength)
        {
            yield return $"{nameof(ExcelWriterPluginOptions.SheetName)} must be " +
                         $"{MaxSheetNameLength} characters or fewer. " +
                         $"Current length: {excelOptions.SheetName.Length}.";
        }

        if (excelOptions.SheetName.IndexOfAny(ForbiddenSheetNameChars) >= 0)
        {
            yield return $"{nameof(ExcelWriterPluginOptions.SheetName)} contains " +
                         $"forbidden characters. The following are not permitted: " +
                         $"{string.Join(" ", ForbiddenSheetNameChars)}";
        }
    }
}