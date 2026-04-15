// <copyright file="ExcelSchemaBuilderTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Tests.Tests.Internal;

using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Writer.Excel.Internal;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ExcelSchemaBuilder"/>.
/// </summary>
[TestFixture]
public sealed class ExcelSchemaBuilderTests : AxbusTestBase
{
    private ExcelSchemaBuilder sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()); }

    private static async IAsyncEnumerable<FlattenedRow> MakeRows(IEnumerable<string[]> cols)
    {
        var rn = 1;
        foreach (var c in cols)
        {
            var row = new FlattenedRow { RowNumber = rn++ };
            foreach (var col in c) row.Values[col] = "val";
            yield return row;
            await Task.Yield();
        }
    }

    /// <summary>Should_ReturnExcelFormat_When_SchemaBuilt.</summary>
    [Test]
    public async Task Should_ReturnExcelFormat_When_SchemaBuilt()
    {
        var schema = await sut.BuildAsync(MakeRows(new[] { new[] { "id" } }), CancellationToken.None);
        Assert.That(schema.Format, Is.EqualTo("excel"));
    }

    /// <summary>Should_CollectAllColumns_When_RowsHaveDifferentFields.</summary>
    [Test]
    public async Task Should_CollectAllColumns_When_RowsHaveDifferentFields()
    {
        var schema = await sut.BuildAsync(
            MakeRows(new[] { new[] { "id", "name" }, new[] { "id", "name", "amount" } }),
            CancellationToken.None);

        Assert.That(schema.Columns.Count,             Is.EqualTo(3));
        Assert.That(schema.Columns.Contains("amount"), Is.True);
    }
}