// <copyright file="RowErrorStrategy.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Specifies how the pipeline handles a row-level processing error.
/// Row errors can occur during transformation, validation or writing.
/// </summary>
public enum RowErrorStrategy
{
    /// <summary>
    /// The entire conversion module is stopped on the first row error.
    /// The module result status is set to <see cref="ConversionStatus.Failed"/>.
    /// </summary>
    StopModule = 0,

    /// <summary>
    /// The failing row is skipped and processing continues with the next row.
    /// Skipped rows are logged as warnings with their row number and error message.
    /// </summary>
    SkipRow = 1,

    /// <summary>
    /// Failing rows are written to a separate error output file alongside the
    /// main output. The error file path is configured in
    /// <see cref="Axbus.Core.Models.Configuration.TargetOptions.ErrorOutputPath"/>.
    /// An additional error column is appended to each error row.
    /// </summary>
    WriteToErrorFile = 2,

    /// <summary>
    /// Field values that fail processing are replaced with the configured
    /// <see cref="Axbus.Core.Models.Configuration.PipelineOptions.NullPlaceholder"/>
    /// and the row is included in the output as normal.
    /// </summary>
    UseDefaultValues = 3,
}