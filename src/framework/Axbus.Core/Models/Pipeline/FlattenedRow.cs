// <copyright file="FlattenedRow.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

/// <summary>
/// Represents a single flattened row produced by the data transformer stage.
/// Each entry maps a column name (which may use dot-notation for nested fields,
/// for example <c>customer.address.city</c>) to its string value.
/// Missing columns produce no entry; the writer fills gaps using the configured
/// <see cref="Axbus.Core.Models.Configuration.PipelineOptions.NullPlaceholder"/>.
/// </summary>
public sealed class FlattenedRow
{
    /// <summary>
    /// Gets the dictionary of column-name-to-value pairs for this row.
    /// Keys use dot-notation for nested fields.
    /// Values are always strings; numeric and boolean values are converted
    /// to their invariant string representations.
    /// </summary>
    public Dictionary<string, string> Values { get; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>
    /// Gets or sets the one-based row number within the source file.
    /// Used in error reporting and logging.
    /// </summary>
    public int RowNumber { get; set; }

    /// <summary>
    /// Gets or sets the path of the source file from which this row originated.
    /// </summary>
    public string SourceFilePath { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets a value indicating whether this row resulted from
    /// an array explosion. When <c>true</c> the row shares its
    /// <see cref="RowNumber"/> with sibling rows from the same parent record.
    /// </summary>
    public bool IsExploded { get; set; }

    /// <summary>
    /// Gets or sets the zero-based index of this row within its explosion group.
    /// Only meaningful when <see cref="IsExploded"/> is <c>true</c>.
    /// </summary>
    public int ExplosionIndex { get; set; }
}