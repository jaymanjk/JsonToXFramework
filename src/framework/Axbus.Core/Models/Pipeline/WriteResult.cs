// <copyright file="WriteResult.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

using Axbus.Core.Enums;

/// <summary>
/// Immutable record representing the output of pipeline Stage 4 (Write).
/// Contains statistics about the write operation including row counts,
/// output paths and duration. Returned to the conversion runner after
/// the writer completes.
/// </summary>
/// <param name="RowsWritten">The number of rows successfully written to the output.</param>
/// <param name="ErrorRowsWritten">The number of rows written to the error output file.</param>
/// <param name="OutputPath">The full path to the primary output file that was written.</param>
/// <param name="ErrorFilePath">The full path to the error output file, or <c>null</c> if no error file was written.</param>
/// <param name="Format">The output format that was written.</param>
/// <param name="Duration">The elapsed time taken to complete the write operation.</param>
public sealed record WriteResult(
    int RowsWritten,
    int ErrorRowsWritten,
    string OutputPath,
    string? ErrorFilePath,
    OutputFormat Format,
    TimeSpan Duration);