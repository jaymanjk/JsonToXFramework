// <copyright file="ModuleResultViewModel.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.ViewModels;

using Axbus.Core.Enums;
using Axbus.Core.Models.Results;

/// <summary>
/// View model that wraps a <see cref="ModuleResult"/> for display
/// in the summary form results grid. Exposes display-friendly
/// properties for DataGridView column binding.
/// </summary>
public sealed class ModuleResultViewModel
{
    /// <summary>Gets the underlying module result.</summary>
    public ModuleResult Result { get; }

    /// <summary>Gets the name of the conversion module.</summary>
    public string ModuleName => Result.ModuleName;

    /// <summary>Gets the final status of the module as a display string.</summary>
    public string Status => Result.Status.ToString();

    /// <summary>Gets the number of rows successfully written.</summary>
    public int RowsWritten => Result.RowsWritten;

    /// <summary>Gets the number of rows written to the error file.</summary>
    public int ErrorRows => Result.ErrorRowsWritten;

    /// <summary>Gets the total duration formatted as seconds with 2 decimal places.</summary>
    public string Duration => $"{Result.Duration.TotalSeconds:F2}s";

    /// <summary>Gets the primary output file path.</summary>
    public string OutputPath => Result.OutputFilePath;

    /// <summary>Gets whether the module completed successfully.</summary>
    public bool IsSuccess => Result.Status == ConversionStatus.Completed;

    /// <summary>
    /// Initializes a new instance of <see cref="ModuleResultViewModel"/>.
    /// </summary>
    /// <param name="result">The module result to wrap.</param>
    public ModuleResultViewModel(ModuleResult result)
    {
        ArgumentNullException.ThrowIfNull(result);
        Result = result;
    }
}