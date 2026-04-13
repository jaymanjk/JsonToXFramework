// <copyright file="ConversionStatus.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Represents the lifecycle status of a conversion module execution.
/// Used in <see cref="Axbus.Core.Models.Notifications.ConversionProgress"/>
/// and <see cref="Axbus.Core.Models.Results.ModuleResult"/> to communicate
/// the current state of a conversion operation.
/// </summary>
public enum ConversionStatus
{
    /// <summary>The conversion module has not yet started.</summary>
    NotStarted = 0,

    /// <summary>
    /// The conversion is in the schema discovery phase.
    /// Source files are being scanned to build the column schema.
    /// </summary>
    Discovering = 1,

    /// <summary>
    /// The conversion pipeline is actively processing rows and writing output.
    /// </summary>
    Converting = 2,

    /// <summary>The conversion module completed successfully.</summary>
    Completed = 3,

    /// <summary>
    /// The conversion module failed with one or more unrecoverable errors.
    /// Check <see cref="Axbus.Core.Models.Results.ModuleResult.Errors"/> for details.
    /// </summary>
    Failed = 4,

    /// <summary>
    /// The conversion module was skipped because
    /// <see cref="Axbus.Core.Models.Configuration.ConversionModule.IsEnabled"/> is false.
    /// </summary>
    Skipped = 5,
}