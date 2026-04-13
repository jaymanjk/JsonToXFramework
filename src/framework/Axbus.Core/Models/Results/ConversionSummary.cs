// <copyright file="ConversionSummary.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Results;

/// <summary>
/// Contains the aggregated results of a complete Axbus conversion run.
/// Returned by <see cref="Axbus.Core.Abstractions.Conversion.IConversionRunner.RunAsync"/>
/// after all conversion modules have been executed.
/// Suitable for display in the WinForms summary form, console output or audit logging.
/// </summary>
public sealed class ConversionSummary
{
    /// <summary>Gets or sets the total number of modules that were configured.</summary>
    public int TotalModules { get; set; }

    /// <summary>Gets or sets the number of modules that completed successfully.</summary>
    public int SuccessfulModules { get; set; }

    /// <summary>Gets or sets the number of modules that failed.</summary>
    public int FailedModules { get; set; }

    /// <summary>Gets or sets the number of modules that were skipped because they were disabled.</summary>
    public int SkippedModules { get; set; }

    /// <summary>Gets or sets the total number of source files processed across all modules.</summary>
    public int TotalFilesProcessed { get; set; }

    /// <summary>Gets or sets the total number of rows written across all modules.</summary>
    public int TotalRowsWritten { get; set; }

    /// <summary>Gets or sets the total number of error rows written across all modules.</summary>
    public int TotalErrorRows { get; set; }

    /// <summary>Gets or sets the total elapsed time for the entire conversion run.</summary>
    public TimeSpan TotalDuration { get; set; }

    /// <summary>
    /// Gets or sets the individual results for each conversion module.
    /// Ordered by <see cref="Axbus.Core.Models.Configuration.ConversionModule.ExecutionOrder"/>.
    /// </summary>
    public List<ModuleResult> Results { get; set; } = new();
}