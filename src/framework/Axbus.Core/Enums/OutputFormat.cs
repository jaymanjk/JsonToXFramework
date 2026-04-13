// <copyright file="OutputFormat.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Specifies the output format for conversion results.
/// This is a flags enumeration allowing multiple formats to be combined
/// using the pipe operator, for example <c>OutputFormat.Csv | OutputFormat.Excel</c>.
/// </summary>
[Flags]
public enum OutputFormat
{
    /// <summary>No output format specified.</summary>
    None = 0,

    /// <summary>
    /// Comma-separated values format (.csv).
    /// RFC 4180 compliant output written via <c>Axbus.Plugin.Writer.Csv</c>.
    /// </summary>
    Csv = 1,

    /// <summary>
    /// Microsoft Excel format (.xlsx).
    /// Output written via <c>Axbus.Plugin.Writer.Excel</c> using ClosedXML.
    /// </summary>
    Excel = 2,

    /// <summary>
    /// Plain text format (.txt).
    /// Reserved for future use via a text writer plugin.
    /// </summary>
    Text = 4,
}