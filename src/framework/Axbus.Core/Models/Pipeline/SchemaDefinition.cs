// <copyright file="SchemaDefinition.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines the ordered set of column names that make up the output schema
/// for a conversion module. The schema is discovered by the writer plugin
/// (which implements <see cref="Axbus.Core.Abstractions.Pipeline.ISchemaAwareWriter"/>)
/// and determines which columns appear in the output and in what order.
/// </summary>
public sealed class SchemaDefinition
{
    /// <summary>
    /// Gets the ordered, read-only list of column names.
    /// Column names use dot-notation for nested fields,
    /// for example <c>customer.address.city</c>.
    /// Order is determined by the configured
    /// <see cref="Axbus.Core.Enums.SchemaStrategy"/> (default: first-seen).
    /// </summary>
    public IReadOnlyList<string> Columns { get; }

    /// <summary>
    /// Gets the format identifier of the output for which this schema was built.
    /// </summary>
    public string Format { get; }

    /// <summary>
    /// Gets the number of source files that contributed to this schema.
    /// </summary>
    public int SourceFileCount { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="SchemaDefinition"/>.
    /// </summary>
    /// <param name="columns">The ordered list of column names.</param>
    /// <param name="format">The output format identifier.</param>
    /// <param name="sourceFileCount">The number of source files that contributed columns.</param>
    public SchemaDefinition(IReadOnlyList<string> columns, string format, int sourceFileCount = 0)
    {
        Columns = columns;
        Format = format;
        SourceFileCount = sourceFileCount;
    }
}