// <copyright file="ErrorViewModel.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.ViewModels;

/// <summary>
/// View model representing a single error entry for display in an error
/// list or log panel within the WinForms application. Used to surface
/// module and row-level errors collected during conversion execution.
/// </summary>
public sealed class ErrorViewModel
{
    /// <summary>Gets the timestamp at which the error occurred.</summary>
    public DateTime Timestamp { get; }

    /// <summary>Gets the name of the conversion module where the error occurred.</summary>
    public string ModuleName { get; }

    /// <summary>Gets the human-readable error message.</summary>
    public string Message { get; }

    /// <summary>Gets the optional file name associated with the error.</summary>
    public string? FileName { get; }

    /// <summary>Gets the exception type name if an exception caused this error, or empty string.</summary>
    public string ExceptionType { get; }

    /// <summary>Gets a display-friendly timestamp string.</summary>
    public string TimestampDisplay => Timestamp.ToString("HH:mm:ss.fff");

    /// <summary>
    /// Initializes a new instance of <see cref="ErrorViewModel"/>.
    /// </summary>
    /// <param name="moduleName">The module where the error occurred.</param>
    /// <param name="message">The error message.</param>
    /// <param name="fileName">Optional file name associated with the error.</param>
    /// <param name="exception">Optional exception that caused the error.</param>
    public ErrorViewModel(
        string moduleName,
        string message,
        string? fileName = null,
        Exception? exception = null)
    {
        Timestamp = DateTime.Now;
        ModuleName = moduleName;
        Message = message;
        FileName = fileName;
        ExceptionType = exception?.GetType().Name ?? string.Empty;
    }
}