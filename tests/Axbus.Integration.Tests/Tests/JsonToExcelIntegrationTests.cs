// <copyright file="JsonToExcelIntegrationTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Integration.Tests.Tests;

using Axbus.Core.Models.Configuration;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Plugin.Reader.Json.Transformer;
using Axbus.Plugin.Writer.Excel.Internal;
using Axbus.Plugin.Writer.Excel.Options;
using Axbus.Plugin.Writer.Excel.Writer;
using Axbus.Tests.Common.Base;
using ClosedXML.Excel;
using NUnit.Framework;

/// <summary>
/// End-to-end integration tests for the JSON-to-Excel pipeline.
/// </summary>
[TestFixture]
public sealed class JsonToExcelIntegrationTests : AxbusTestBase
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

    /// <summary>Should_ProduceValidXlsx_When_FlatJsonProcessed.</summary>
    [Test]
    public async Task Should_ProduceValidXlsx_When_FlatJsonProcessed()
    {
        var inputPath = Path.Combine(tempIn, "products.json");
        await File.WriteAllTextAsync(inputPath, """
            [
              {"productId":"P001","name":"Widget A","price":25.50},
              {"productId":"P002","name":"Widget B","price":42.00},
              {"productId":"P003","name":"Widget C","price":15.75}
            ]
            """);

        var opts    = new JsonReaderPluginOptions();
        var reader  = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser  = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var xformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer  = new ExcelOutputWriter(NullLogger<ExcelOutputWriter>(),
            new ExcelWriterPluginOptions { SheetName = "Products", AutoFit = false, BoldHeaders = true },
            new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()));

        var sd = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd = await parser.ParseAsync(sd, CancellationToken.None);
        var td = await xformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(td, new TargetOptions { Path = tempOut }, new PipelineOptions(), CancellationToken.None);

        // Dispose the source stream to release file handle
        await sd.RawData.DisposeAsync();

        Assert.That(File.Exists(result.OutputPath), Is.True);
        Assert.That(result.RowsWritten,             Is.EqualTo(3));

        using var wb = new XLWorkbook(result.OutputPath);
        var ws = wb.Worksheet("Products");
        Assert.That(ws,                          Is.Not.Null);
        Assert.That(ws.Cell(1, 1).GetString(),   Is.EqualTo("productId"));
        Assert.That(ws.Cell(2, 1).GetString(),   Is.EqualTo("P001"));
    }

    /// <summary>Should_ApplyBoldHeaders_When_BoldHeadersEnabled.</summary>
    [Test]
    public async Task Should_ApplyBoldHeaders_When_BoldHeadersEnabled()
    {
        var inputPath = Path.Combine(tempIn, "data.json");
        await File.WriteAllTextAsync(inputPath, "[{\"id\":\"1\",\"value\":\"X\"}]");

        var opts    = new JsonReaderPluginOptions();
        var reader  = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser  = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var xformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer  = new ExcelOutputWriter(NullLogger<ExcelOutputWriter>(),
            new ExcelWriterPluginOptions { BoldHeaders = true, AutoFit = false },
            new ExcelSchemaBuilder(NullLogger<ExcelSchemaBuilder>()));

        var sd = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd = await parser.ParseAsync(sd, CancellationToken.None);
        var td = await xformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(td, new TargetOptions { Path = tempOut }, new PipelineOptions(), CancellationToken.None);

        // Dispose the source stream to release file handle
        await sd.RawData.DisposeAsync();

        using var wb = new XLWorkbook(result.OutputPath);
        Assert.That(wb.Worksheets.First().Cell(1, 1).Style.Font.Bold, Is.True);
    }
}
