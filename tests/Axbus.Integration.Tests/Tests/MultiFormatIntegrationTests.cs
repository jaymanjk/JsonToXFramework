// <copyright file="MultiFormatIntegrationTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Integration.Tests.Tests;

using Axbus.Core.Models.Configuration;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Plugin.Reader.Json.Transformer;
using Axbus.Plugin.Writer.Csv.Internal;
using Axbus.Plugin.Writer.Csv.Options;
using Axbus.Plugin.Writer.Csv.Writer;
using Axbus.Plugin.Writer.Excel.Internal;
using Axbus.Plugin.Writer.Excel.Options;
using Axbus.Plugin.Writer.Excel.Writer;
using Axbus.Tests.Common.Base;
using ClosedXML.Excel;
using NUnit.Framework;

/// <summary>
/// Integration tests verifying consistent output across CSV and Excel formats.
/// </summary>
[TestFixture]
public sealed class MultiFormatIntegrationTests : AxbusTestBase
{
    private string tempIn  = null!;
    private string tempOut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        tempIn  = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        tempOut = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempIn);
        Directory.CreateDirectory(tempOut);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        SafeDeleteDirectory(tempIn);
        SafeDeleteDirectory(tempOut);
    }

    /// <summary>
    /// Safely deletes a directory with retry logic to handle file locks.
    /// </summary>
    private static void SafeDeleteDirectory(string path)
    {
        if (!Directory.Exists(path)) return;

        // Force garbage collection to release file handles
        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();

        // Retry logic for directory deletion
        var maxRetries = 3;
        for (var i = 0; i < maxRetries; i++)
        {
            try
            {
                Directory.Delete(path, recursive: true);
                return;
            }
            catch (IOException) when (i < maxRetries - 1)
            {
                Thread.Sleep(100);
            }
            catch (UnauthorizedAccessException) when (i < maxRetries - 1)
            {
                Thread.Sleep(100);
            }
        }
    }

    /// <summary>Should_ProduceSameRowCount_When_SameJsonWrittenToCsvAndExcel.</summary>
    [Test]
    public async Task Should_ProduceSameRowCount_When_SameJsonWrittenToCsvAndExcel()
    {
        var inputPath = Path.Combine(tempIn, "inventory.json");
        await File.WriteAllTextAsync(inputPath, """
            [
              {"sku":"SKU-001","description":"Bolt M8","qty":500},
              {"sku":"SKU-002","description":"Nut M8","qty":500},
              {"sku":"SKU-003","description":"Washer M8","qty":1000}
            ]
            """);

        var opts    = new JsonReaderPluginOptions();
        var pipeline = new PipelineOptions();
        var target   = new TargetOptions { Path = tempOut };
        var reader  = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser  = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var xformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);

        // CSV pass
        var sd1 = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd1 = await parser.ParseAsync(sd1, CancellationToken.None);
        var td1 = await xformer.TransformAsync(pd1, pipeline, CancellationToken.None);
        var csvResult = await new CsvOutputWriter(NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions(), new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()))
            .WriteAsync(td1, target, pipeline, CancellationToken.None);

        // Dispose the first source stream
        await sd1.RawData.DisposeAsync();

        // Excel pass
        var sd2 = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd2 = await parser.ParseAsync(sd2, CancellationToken.None);
        var td2 = await xformer.TransformAsync(pd2, pipeline, CancellationToken.None);
        var xlResult = await new ExcelOutputWriter(NullLogger<ExcelOutputWriter>(),
            new ExcelWriterPluginOptions { AutoFit = false }, new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()))
            .WriteAsync(td2, target, pipeline, CancellationToken.None);

        // Dispose the second source stream
        await sd2.RawData.DisposeAsync();

        Assert.That(csvResult.RowsWritten, Is.EqualTo(3));
        Assert.That(xlResult.RowsWritten,  Is.EqualTo(3));

        var csvLines = await File.ReadAllLinesAsync(csvResult.OutputPath);
        Assert.That(csvLines.Length, Is.EqualTo(4), "1 header + 3 data rows");

        using var wb = new XLWorkbook(xlResult.OutputPath);
        Assert.That(wb.Worksheets.First().LastRowUsed()!.RowNumber(), Is.EqualTo(4));

        var csvCols  = csvLines[0].Split(',').Length;
        var xlCols   = wb.Worksheets.First().LastColumnUsed()!.ColumnNumber();
        Assert.That(csvCols, Is.EqualTo(xlCols), "Same column count in both formats");
    }
}
