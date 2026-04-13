// <copyright file="IDataValidator.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines the optional validation stage of the Axbus conversion pipeline.
/// When a validator is registered the pipeline executes it between the
/// Transform and Write stages. Invalid rows are handled according to the
/// configured <see cref="Axbus.Core.Enums.RowErrorStrategy"/>.
/// Implement this interface in a plugin to add custom business rule validation.
/// </summary>
public interface IDataValidator
{
    /// <summary>
    /// Validates a single <see cref="FlattenedRow"/> and returns a
    /// <see cref="ValidationResult"/> indicating whether the row is valid.
    /// </summary>
    /// <param name="row">The flattened row to validate.</param>
    /// <param name="cancellationToken">A token to cancel the validation operation.</param>
    /// <returns>
    /// A <see cref="ValidationResult"/> with <see cref="ValidationResult.IsValid"/> set to
    /// <c>true</c> if the row passes validation, or <c>false</c> with error messages otherwise.
    /// </returns>
    Task<ValidationResult> ValidateAsync(FlattenedRow row, CancellationToken cancellationToken);
}