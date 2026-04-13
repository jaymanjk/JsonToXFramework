// <copyright file="ValidationResult.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Pipeline;

/// <summary>
/// Represents the result of validating a single <see cref="FlattenedRow"/>
/// in the optional validation pipeline stage.
/// Returned by implementations of
/// <see cref="Axbus.Core.Abstractions.Pipeline.IDataValidator"/>.
/// </summary>
public sealed class ValidationResult
{
    /// <summary>
    /// Gets or sets a value indicating whether the row passed validation.
    /// When <c>false</c> the row is handled according to the configured
    /// <see cref="Axbus.Core.Enums.RowErrorStrategy"/>.
    /// </summary>
    public bool IsValid { get; set; } = true;

    /// <summary>
    /// Gets the list of validation error messages for this row.
    /// Empty when <see cref="IsValid"/> is <c>true</c>.
    /// </summary>
    public List<string> Errors { get; } = new();

    /// <summary>
    /// Gets a pre-built instance representing a successful validation result.
    /// </summary>
    public static ValidationResult Success { get; } = new() { IsValid = true };

    /// <summary>
    /// Creates a failed <see cref="ValidationResult"/> with one or more error messages.
    /// </summary>
    /// <param name="errors">One or more validation error messages describing why the row failed.</param>
    /// <returns>A new <see cref="ValidationResult"/> with <see cref="IsValid"/> set to <c>false</c>.</returns>
    public static ValidationResult Fail(params string[] errors)
    {
        var result = new ValidationResult { IsValid = false };
        result.Errors.AddRange(errors);
        return result;
    }
}