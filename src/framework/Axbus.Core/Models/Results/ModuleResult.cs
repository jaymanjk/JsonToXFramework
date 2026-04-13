// <copyright file="ModuleResult.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Results;

using Axbus.Core.Enums;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Holds the outcome of executing a single <see cref="Axbus.Core.Models.Configuration.ConversionModule"/>.
/// Included in <see cref="ConversionSummary.Results"/> after the conversion run completes.
/// </summary>
public sealed class ModuleResult
{
    /// <summary>Gets or sets the name of the conversion module.</summary>
    public string ModuleName { get; set; } = string.Empty;

    /// <summary>Gets or sets the final lifecycle status of the module.</summary>
    public ConversionStatus Status { get; set; }

    /// <summary>Gets or sets the number of source files processed by this module.</summary>
    public int FilesProcessed { get; set; }

    /// <summary>Gets or sets the total number of rows successfully written.</summary>
    public int RowsWritten { get; set; }

    /// <summary>Gets or sets the number of rows written to the error output file.</summary>
    public int ErrorRowsWritten { get; set; }

    /// <summary>Gets or sets the full path to the primary output file.</summary>
    public string OutputFilePath { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the full path to the error output file.
    /// <c>null</c> when no error file was produced.
    /// </summary>
    public string? ErrorFilePath { get; set; }

    /// <summary>
    /// Gets or sets the list of output file paths produced by this module.
    /// Contains multiple entries when <see cref="Axbus.Core.Enums.OutputMode.OnePerFile"/> is used
    /// or when multiple output formats are configured.
    /// </summary>
    public List<string> OutputFiles { get; set; } = new();

    /// <summary>
    /// Gets or sets the column schema that was used for this module's output.
    /// </summary>
    public SchemaDefinition? SchemaUsed { get; set; }

    /// <summary>Gets or sets the total elapsed time for this module's execution.</summary>
    public TimeSpan Duration { get; set; }

    /// <summary>Gets or sets the list of error messages collected during execution.</summary>
    public List<string> Errors { get; set; } = new();

    /// <summary>Gets or sets the list of warning messages collected during execution.</summary>
    public List<string> Warnings { get; set; } = new();
}