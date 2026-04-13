// <copyright file="ConversionProgress.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Notifications;

using Axbus.Core.Enums;

/// <summary>
/// Carries progress information reported via <see cref="IProgress{T}"/>
/// to UI consumers such as the WinForms progress bar or console output.
/// Published by the conversion runner as each file and row is processed.
/// </summary>
public sealed class ConversionProgress
{
    /// <summary>Gets or sets the name of the conversion module currently executing.</summary>
    public string ModuleName { get; set; } = string.Empty;

    /// <summary>Gets or sets the total number of source files to process in this module.</summary>
    public int TotalFiles { get; set; }

    /// <summary>Gets or sets the number of source files processed so far.</summary>
    public int ProcessedFiles { get; set; }

    /// <summary>
    /// Gets or sets the estimated total number of rows across all source files.
    /// May be <c>-1</c> if the total is not yet known.
    /// </summary>
    public int TotalRows { get; set; }

    /// <summary>Gets or sets the number of rows processed and written so far.</summary>
    public int ProcessedRows { get; set; }

    /// <summary>
    /// Gets or sets the percentage of work completed, from <c>0.0</c> to <c>100.0</c>.
    /// </summary>
    public double PercentComplete { get; set; }

    /// <summary>Gets or sets the name of the source file currently being processed.</summary>
    public string CurrentFile { get; set; } = string.Empty;

    /// <summary>Gets or sets the current lifecycle status of the conversion module.</summary>
    public ConversionStatus Status { get; set; }
}