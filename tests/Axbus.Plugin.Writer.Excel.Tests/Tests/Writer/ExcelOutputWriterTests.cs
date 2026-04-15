// <copyright file="ExcelOutputWriterTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Tests.Tests.Writer;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Writer.Excel.Internal;
using Axbus.Plugin.Writer.Excel.Options;
using Axbus.Plugin.Writer.Excel.Writer;
using Axbus.Tests.Common.Base;
using ClosedXML.Excel;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ExcelOutputWriter"/>.
/// </summary>
[TestFixture]
public sealed class ExcelOutputWriterTests : AxbusTestBase
{
    private string tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    private ExcelOutputWriter CreateWriter(string sheet = "Sheet1") =>
        new(NullLogger<ExcelOutputWriter>(),
            new ExcelWriterPluginOptions { SheetName = sheet, AutoFit = false, BoldHeaders = true },
            new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()));

    private static TransformedData MakeData(int count) =>
        new(Rows: MakeRows(count), SourcePath: "test.json");

    private static async IAsyncEnumerable<FlattenedRow> MakeRows(int count)
    {
        for (var i = 1; i <= count; i++)
        {
            var row = new FlattenedRow { RowNumber = i };
            row.Values["id"]   = i.ToString();
            row.Values["name"] = $"Product {i}";
            yield return row;
            await Task.Yield();
        }
    }

    /// <summary>Should_CreateXlsxFile_When_RowsWritten.</summary>
    [Test]
    public async Task Should_CreateXlsxFile_When_RowsWritten()
    {
        var result = await CreateWriter().WriteAsync(
            MakeData(3), new TargetOptions { Path = tempDir }, new PipelineOptions(), CancellationToken.None);

        Assert.That(File.Exists(result.OutputPath), Is.True);
        Assert.That(result.RowsWritten,             Is.EqualTo(3));
        Assert.That(result.OutputPath,              Does.EndWith(".xlsx"));
    }

    /// <summary>Should_UseConfiguredSheetName_When_Opened.</summary>
    [Test]
    public async Task Should_UseConfiguredSheetName_When_Opened()
    {
        var result = await CreateWriter(sheet: "MyData").WriteAsync(
            MakeData(1), new TargetOptions { Path = tempDir }, new PipelineOptions(), CancellationToken.None);

        using var wb = new XLWorkbook(result.OutputPath);
        Assert.That(wb.Worksheets.Any(ws => ws.Name == "MyData"), Is.True);
    }

    /// <summary>Should_WriteHeaderRowWithColumnNames.</summary>
    [Test]
    public async Task Should_WriteHeaderRowWithColumnNames()
    {
        var result = await CreateWriter().WriteAsync(
            MakeData(2), new TargetOptions { Path = tempDir }, new PipelineOptions(), CancellationToken.None);

        using var wb = new XLWorkbook(result.OutputPath);
        var ws = wb.Worksheets.First();

        Assert.That(ws.Cell(1, 1).GetString(), Is.EqualTo("id"));
        Assert.That(ws.Cell(1, 2).GetString(), Is.EqualTo("name"));
    }
}