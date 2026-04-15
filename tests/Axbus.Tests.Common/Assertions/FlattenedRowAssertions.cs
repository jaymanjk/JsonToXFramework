// <copyright file="FlattenedRowAssertions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Tests.Common.Assertions;

using Axbus.Core.Models.Pipeline;
using NUnit.Framework;

/// <summary>
/// Provides custom NUnit assertion helpers for <see cref="FlattenedRow"/>
/// and collections thereof. Produces clear failure messages that include
/// row number and column names.
/// </summary>
public static class FlattenedRowAssertions
{
    /// <summary>
    /// Asserts that <paramref name="row"/> contains <paramref name="columnName"/>
    /// with the expected <paramref name="value"/>.
    /// </summary>
    /// <param name="row">The row to check.</param>
    /// <param name="columnName">The column name to look up.</param>
    /// <param name="value">The expected value.</param>
    public static void HasValue(FlattenedRow row, string columnName, string value)
    {
        Assert.That(
            row.Values.ContainsKey(columnName),
            Is.True,
            $"Row {row.RowNumber} does not contain column '{columnName}'. " +
            $"Present: {string.Join(", ", row.Values.Keys)}");

        Assert.That(
            row.Values[columnName],
            Is.EqualTo(value),
            $"Row {row.RowNumber} column '{columnName}' expected '{value}' " +
            $"but was '{row.Values[columnName]}'.");
    }

    /// <summary>
    /// Asserts that <paramref name="rows"/> contains exactly <paramref name="expectedCount"/> rows.
    /// </summary>
    /// <param name="rows">The row collection to check.</param>
    /// <param name="expectedCount">The expected row count.</param>
    public static void HasCount(IReadOnlyList<FlattenedRow> rows, int expectedCount)
    {
        Assert.That(rows.Count, Is.EqualTo(expectedCount),
            $"Expected {expectedCount} rows but got {rows.Count}.");
    }

    /// <summary>
    /// Asserts that every row in <paramref name="rows"/> contains <paramref name="columnName"/>.
    /// </summary>
    /// <param name="rows">The rows to check.</param>
    /// <param name="columnName">The column that must exist in every row.</param>
    public static void AllHaveColumn(IReadOnlyList<FlattenedRow> rows, string columnName)
    {
        foreach (var row in rows)
        {
            Assert.That(row.Values.ContainsKey(columnName), Is.True,
                $"Row {row.RowNumber} is missing column '{columnName}'.");
        }
    }

    /// <summary>
    /// Collects all rows from an <see cref="IAsyncEnumerable{T}"/> into a list
    /// for use in synchronous NUnit assertions.
    /// </summary>
    /// <param name="rows">The async row stream to collect.</param>
    /// <param name="cancellationToken">A token to cancel collection.</param>
    /// <returns>A list of all rows from the stream.</returns>
    public static async Task<List<FlattenedRow>> CollectAsync(
        IAsyncEnumerable<FlattenedRow> rows,
        CancellationToken cancellationToken = default)
    {
        var result = new List<FlattenedRow>();
        await foreach (var row in rows.WithCancellation(cancellationToken).ConfigureAwait(false))
        {
            result.Add(row);
        }

        return result;
    }
}