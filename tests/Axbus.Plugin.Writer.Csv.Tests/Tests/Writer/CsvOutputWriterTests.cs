// <copyright file="CsvOutputWriterTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Tests.Tests.Writer;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Writer.Csv.Internal;
using Axbus.Plugin.Writer.Csv.Options;
using Axbus.Plugin.Writer.Csv.Writer;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="CsvOutputWriter"/>.
/// </summary>
[TestFixture]
public sealed class CsvOutputWriterTests : AxbusTestBase
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

    private CsvOutputWriter CreateWriter(char delimiter = ',') =>
        new(NullLogger<CsvOutputWriter>(),
            new CsvWriterPluginOptions { Delimiter = delimiter, IncludeHeader = true },
            new CsvSchemaBuilder(NullLogger<CsvSchemaBuilder>()));

    private static TransformedData MakeData(int rowCount) =>
        new(Rows: MakeRows(rowCount), SourcePath: "test.json");

    private static async IAsyncEnumerable<FlattenedRow> MakeRows(int count)
    {
        for (var i = 1; i <= count; i++)
        {
            var row = new FlattenedRow { RowNumber = i };
            row.Values["id"]   = i.ToString();
            row.Values["name"] = $"Item {i}";
            yield return row;
            await Task.Yield();
        }
    }

    /// <summary>Should_CreateOutputFile_When_RowsWritten.</summary>
    [Test]
    public async Task Should_CreateOutputFile_When_RowsWritten()
    {
        var result = await CreateWriter().WriteAsync(
            MakeData(3), new TargetOptions { Path = tempDir }, new PipelineOptions(), CancellationToken.None);

        Assert.That(File.Exists(result.OutputPath), Is.True);
        Assert.That(result.RowsWritten,             Is.EqualTo(3));
    }

    /// <summary>Should_WriteHeaderRow_When_IncludeHeaderTrue.</summary>
    [Test]
    public async Task Should_WriteHeaderRow_When_IncludeHeaderTrue()
    {
        var result = await CreateWriter().WriteAsync(
            MakeData(2), new TargetOptions { Path = tempDir }, new PipelineOptions(), CancellationToken.None);

        var lines = await File.ReadAllLinesAsync(result.OutputPath);

        Assert.That(lines.Length, Is.GreaterThanOrEqualTo(3));
        Assert.That(lines[0], Does.Contain("id"));
        Assert.That(lines[0], Does.Contain("name"));
    }

    /// <summary>Should_UseSemicolon_When_DelimiterConfigured.</summary>
    [Test]
    public async Task Should_UseSemicolon_When_DelimiterConfigured()
    {
        var result  = await CreateWriter(delimiter: ';').WriteAsync(
            MakeData(1), new TargetOptions { Path = tempDir }, new PipelineOptions(), CancellationToken.None);
        var content = await File.ReadAllTextAsync(result.OutputPath);

        Assert.That(content, Does.Contain(";"));
        Assert.That(content, Does.Not.Contain(","));
    }
}