// <copyright file="JsonToCsvIntegrationTests.cs" company="Axel Johnson International">
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
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// End-to-end integration tests for the JSON-to-CSV pipeline.
/// </summary>
[TestFixture]
public sealed class JsonToCsvIntegrationTests : AxbusTestBase
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

    /// <summary>Should_ProduceValidCsv_When_FlatJsonProcessed.</summary>
    [Test]
    public async Task Should_ProduceValidCsv_When_FlatJsonProcessed()
    {
        var inputPath = Path.Combine(tempIn, "orders.json");
        await File.WriteAllTextAsync(inputPath, """
            [
              {"orderId":"ORD-001","customer":"Acme Corp","amount":1500.00},
              {"orderId":"ORD-002","customer":"Globex Ltd","amount":2750.50}
            ]
            """);

        var opts    = new JsonReaderPluginOptions();
        var reader  = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser  = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var xformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer  = new CsvOutputWriter(NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions { Delimiter = ',', IncludeHeader = true },
            new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));

        var sd = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd = await parser.ParseAsync(sd, CancellationToken.None);
        var td = await xformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(td, new TargetOptions { Path = tempOut }, new PipelineOptions(), CancellationToken.None);

        // Dispose the source stream to release file handle
        await sd.RawData.DisposeAsync();

        Assert.That(File.Exists(result.OutputPath), Is.True);
        Assert.That(result.RowsWritten,             Is.EqualTo(2));
        Assert.That(result.ErrorRowsWritten,        Is.EqualTo(0));

        var lines = await File.ReadAllLinesAsync(result.OutputPath);
        Assert.That(lines.Length,  Is.EqualTo(3));
        Assert.That(lines[0],      Does.Contain("orderId"));
        Assert.That(lines[1],      Does.Contain("ORD-001"));
    }

    /// <summary>Should_ExplodeNestedArrays_When_JsonContainsArrayFields.</summary>
    [Test]
    public async Task Should_ExplodeNestedArrays_When_JsonContainsArrayFields()
    {
        var inputPath = Path.Combine(tempIn, "sales.json");
        await File.WriteAllTextAsync(inputPath, """
            [{"orderId":"SO-001","lines":[{"lineNo":1,"product":"A"},{"lineNo":2,"product":"B"}]}]
            """);

        var opts    = new JsonReaderPluginOptions { MaxExplosionDepth = 3 };
        var reader  = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser  = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var xformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer  = new CsvOutputWriter(NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions(), new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));

        var sd = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd = await parser.ParseAsync(sd, CancellationToken.None);
        var td = await xformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(td, new TargetOptions { Path = tempOut }, new PipelineOptions(), CancellationToken.None);

        // Dispose the source stream to release file handle
        await sd.RawData.DisposeAsync();

        Assert.That(result.RowsWritten, Is.EqualTo(2));
    }

    /// <summary>Should_ProduceEmptyCsv_When_JsonArrayIsEmpty.</summary>
    [Test]
    public async Task Should_ProduceEmptyCsv_When_JsonArrayIsEmpty()
    {
        var inputPath = Path.Combine(tempIn, "empty.json");
        await File.WriteAllTextAsync(inputPath, "[]");

        var opts    = new JsonReaderPluginOptions();
        var reader  = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser  = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        var xformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
        var writer  = new CsvOutputWriter(NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions(), new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));

        var sd = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd = await parser.ParseAsync(sd, CancellationToken.None);
        var td = await xformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var result = await writer.WriteAsync(td, new TargetOptions { Path = tempOut }, new PipelineOptions(), CancellationToken.None);

        // Dispose the source stream to release file handle
        await sd.RawData.DisposeAsync();

        Assert.That(result.RowsWritten, Is.EqualTo(0));
        Assert.That(File.Exists(result.OutputPath), Is.True);
    }
}
