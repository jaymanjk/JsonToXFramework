// <copyright file="SchemaStrategy.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Specifies how the output column schema is discovered during conversion.
/// The schema determines which columns appear in the output and in what order.
/// </summary>
public enum SchemaStrategy
{
    /// <summary>
    /// All source files are fully scanned before any output is written.
    /// The resulting schema is the union of all columns across all files
    /// in first-seen order. This is the safest strategy but requires
    /// two passes over the data.
    /// </summary>
    FullScan = 0,

    /// <summary>
    /// Schema is accumulated progressively as rows are streamed.
    /// New columns discovered mid-stream are added to the schema.
    /// Memory efficient but may require buffering rows until schema stabilises.
    /// </summary>
    Progressive = 1,

    /// <summary>
    /// Schema is determined from the first source file only.
    /// Fastest strategy but may miss columns present only in later files.
    /// </summary>
    FirstFile = 2,

    /// <summary>
    /// Schema is provided explicitly by the developer via plugin options.
    /// No discovery is performed. Columns not in the schema are ignored.
    /// </summary>
    Configurable = 3,
}