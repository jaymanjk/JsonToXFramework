// <copyright file="IDataFilter.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Pipeline;

using Axbus.Core.Models.Pipeline;

/// <summary>
/// Defines the optional filter stage of the Axbus conversion pipeline.
/// When a filter is registered the pipeline executes it between the
/// Transform and Write stages. Rows for which the filter returns <c>false</c>
/// are excluded from the output without being treated as errors.
/// Implement this interface in a plugin to add row inclusion/exclusion logic.
/// </summary>
public interface IDataFilter
{
    /// <summary>
    /// Determines whether the specified <see cref="FlattenedRow"/> should be
    /// included in the output.
    /// </summary>
    /// <param name="row">The flattened row to evaluate.</param>
    /// <param name="cancellationToken">A token to cancel the filter evaluation.</param>
    /// <returns>
    /// <c>true</c> if the row should be included in the output;
    /// <c>false</c> if the row should be excluded silently.
    /// </returns>
    Task<bool> ShouldIncludeAsync(FlattenedRow row, CancellationToken cancellationToken);
}