// <copyright file="ConversionSummaryViewModel.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.ViewModels;

using Axbus.Core.Models.Results;

/// <summary>
/// View model wrapping a <see cref="ConversionSummary"/> for display
/// in the summary form. Exposes display-friendly aggregate statistics
/// and a bindable list of per-module result view models.
/// </summary>
public sealed class ConversionSummaryViewModel
{
    /// <summary>Gets the underlying conversion summary.</summary>
    public ConversionSummary Summary { get; }

    /// <summary>Gets the total number of modules configured.</summary>
    public int TotalModules => Summary.TotalModules;

    /// <summary>Gets the number of modules that completed successfully.</summary>
    public int SuccessfulModules => Summary.SuccessfulModules;

    /// <summary>Gets the number of modules that failed.</summary>
    public int FailedModules => Summary.FailedModules;

    /// <summary>Gets the number of modules that were skipped.</summary>
    public int SkippedModules => Summary.SkippedModules;

    /// <summary>Gets the total number of rows written across all modules.</summary>
    public int TotalRowsWritten => Summary.TotalRowsWritten;

    /// <summary>Gets the total number of error rows across all modules.</summary>
    public int TotalErrorRows => Summary.TotalErrorRows;

    /// <summary>Gets the total duration formatted as seconds with 2 decimal places.</summary>
    public string TotalDuration => $"{Summary.TotalDuration.TotalSeconds:F2}s";

    /// <summary>Gets a display string indicating overall pass or fail.</summary>
    public string OverallStatus => Summary.FailedModules == 0 ? "Completed Successfully" : "Completed with Errors";

    /// <summary>Gets the per-module result view models for the results grid.</summary>
    public IReadOnlyList<ModuleResultViewModel> ModuleResults { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="ConversionSummaryViewModel"/>.
    /// </summary>
    /// <param name="summary">The conversion summary to wrap.</param>
    public ConversionSummaryViewModel(ConversionSummary summary)
    {
        ArgumentNullException.ThrowIfNull(summary);
        Summary = summary;
        ModuleResults = summary.Results
            .Select(r => new ModuleResultViewModel(r))
            .ToList()
            .AsReadOnly();
    }
}