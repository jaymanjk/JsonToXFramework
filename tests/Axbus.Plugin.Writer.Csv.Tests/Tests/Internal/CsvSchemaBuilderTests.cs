// <copyright file="CsvSchemaBuilderTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Tests.Tests.Internal;

using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Writer.Csv.Internal;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="CsvSchemaBuilder"/>.
/// </summary>
[TestFixture]
public sealed class CsvSchemaBuilderTests : AxbusTestBase
{
    private CsvSchemaBuilder sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()); }

    private static async IAsyncEnumerable<FlattenedRow> MakeRows(IEnumerable<Dictionary<string, string>> vals)
    {
        var rn = 1;
        foreach (var v in vals)
        {
            var row = new FlattenedRow { RowNumber = rn++ };
            foreach (var kvp in v) row.Values[kvp.Key] = kvp.Value;
            yield return row;
            await Task.Yield();
        }
    }

    /// <summary>Should_DiscoverColumnsInFirstSeenOrder.</summary>
    [Test]
    public async Task Should_DiscoverColumnsInFirstSeenOrder()
    {
        var rows   = MakeRows(new[] { new Dictionary<string, string> { ["id"] = "1", ["name"] = "A" } });
        var schema = await sut.BuildAsync(rows, CancellationToken.None);

        Assert.That(schema.Columns[0], Is.EqualTo("id"));
        Assert.That(schema.Columns[1], Is.EqualTo("name"));
    }

    /// <summary>Should_UnionColumns_When_RowsHaveDifferentKeys.</summary>
    [Test]
    public async Task Should_UnionColumns_When_RowsHaveDifferentKeys()
    {
        var rows = MakeRows(new[]
        {
            new Dictionary<string, string> { ["id"] = "1" },
            new Dictionary<string, string> { ["id"] = "2", ["extra"] = "X" },
        });
        var schema = await sut.BuildAsync(rows, CancellationToken.None);

        Assert.That(schema.Columns.Count,           Is.EqualTo(2));
        Assert.That(schema.Columns.Contains("extra"), Is.True);
    }

    /// <summary>Should_ReturnEmptySchema_When_NoRows.</summary>
    [Test]
    public async Task Should_ReturnEmptySchema_When_NoRows()
    {
        var schema = await sut.BuildAsync(
            MakeRows(Array.Empty<Dictionary<string, string>>()),
            CancellationToken.None);
        Assert.That(schema.Columns, Is.Empty);
    }
}