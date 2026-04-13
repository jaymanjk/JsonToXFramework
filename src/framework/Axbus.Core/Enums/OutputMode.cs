// <copyright file="OutputMode.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Specifies how output files are created during a conversion run.
/// Controls whether all converted data is written to a single file
/// or whether one output file is produced per input source file.
/// </summary>
public enum OutputMode
{
    /// <summary>
    /// All rows from all source files are written to a single output file.
    /// The schema is the union of all columns discovered across all files.
    /// This is the default mode.
    /// </summary>
    SingleFile = 0,

    /// <summary>
    /// One output file is produced for each input source file.
    /// Each output file uses the schema discovered from its own source file only.
    /// Output files are named after their corresponding source files.
    /// </summary>
    OnePerFile = 1,
}