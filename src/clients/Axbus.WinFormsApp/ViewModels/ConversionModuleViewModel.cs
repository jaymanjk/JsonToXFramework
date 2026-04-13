// <copyright file="ConversionModuleViewModel.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.ViewModels;

using Axbus.Core.Enums;
using Axbus.Core.Models.Configuration;

/// <summary>
/// View model that wraps a <see cref="ConversionModule"/> for display
/// in the main form module list. Exposes display-friendly properties
/// for binding to WinForms controls such as DataGridView.
/// </summary>
public sealed class ConversionModuleViewModel
{
    /// <summary>Gets the underlying conversion module configuration.</summary>
    public ConversionModule Module { get; }

    /// <summary>Gets the unique name of the conversion module.</summary>
    public string ConversionName => Module.ConversionName;

    /// <summary>Gets the description of the conversion module.</summary>
    public string Description => Module.Description;

    /// <summary>Gets a value indicating whether this module is enabled.</summary>
    public bool IsEnabled => Module.IsEnabled;

    /// <summary>Gets the source format identifier (e.g. json).</summary>
    public string SourceFormat => Module.SourceFormat;

    /// <summary>Gets the target format identifier (e.g. csv).</summary>
    public string TargetFormat => Module.TargetFormat;

    /// <summary>Gets or sets the current execution status of this module.</summary>
    public ConversionStatus Status { get; set; } = ConversionStatus.NotStarted;

    /// <summary>Gets a display-friendly status string for the module.</summary>
    public string StatusDisplay => Status.ToString();

    /// <summary>
    /// Initializes a new instance of <see cref="ConversionModuleViewModel"/>.
    /// </summary>
    /// <param name="module">The conversion module to wrap.</param>
    public ConversionModuleViewModel(ConversionModule module)
    {
        ArgumentNullException.ThrowIfNull(module);
        Module = module;
    }
}