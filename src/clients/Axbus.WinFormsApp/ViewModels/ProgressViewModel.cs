// <copyright file="ProgressViewModel.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.ViewModels;

using Axbus.Core.Enums;
using Axbus.Core.Models.Notifications;

/// <summary>
/// View model that maps <see cref="ConversionProgress"/> updates to
/// WinForms control properties. Designed for binding to a ProgressBar,
/// status label and current file label in the progress form.
/// </summary>
public sealed class ProgressViewModel
{
    /// <summary>Gets or sets the name of the module currently executing.</summary>
    public string ModuleName { get; set; } = string.Empty;

    /// <summary>Gets or sets the percentage complete as an integer 0-100 for ProgressBar.Value.</summary>
    public int PercentComplete { get; set; }

    /// <summary>Gets or sets the current file being processed.</summary>
    public string CurrentFile { get; set; } = string.Empty;

    /// <summary>Gets or sets the current conversion status.</summary>
    public ConversionStatus Status { get; set; }

    /// <summary>Gets or sets the total number of files to process.</summary>
    public int TotalFiles { get; set; }

    /// <summary>Gets or sets the number of files processed so far.</summary>
    public int ProcessedFiles { get; set; }

    /// <summary>Gets a display string combining file progress counts.</summary>
    public string FileProgressDisplay => $"Files: {ProcessedFiles} / {TotalFiles}";

    /// <summary>Gets a display string for the status label.</summary>
    public string StatusDisplay => $"{ModuleName} - {Status}";

    /// <summary>
    /// Updates all properties from a <see cref="ConversionProgress"/> notification.
    /// </summary>
    /// <param name="progress">The progress notification to apply.</param>
    public void UpdateFrom(ConversionProgress progress)
    {
        ArgumentNullException.ThrowIfNull(progress);
        ModuleName = progress.ModuleName;
        PercentComplete = (int)Math.Clamp(progress.PercentComplete, 0, 100);
        CurrentFile = progress.CurrentFile;
        Status = progress.Status;
        TotalFiles = progress.TotalFiles;
        ProcessedFiles = progress.ProcessedFiles;
    }
}