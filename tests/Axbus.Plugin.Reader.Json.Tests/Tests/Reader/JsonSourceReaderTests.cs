// <copyright file="JsonSourceReaderTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Tests.Tests.Reader;

using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="JsonSourceReader"/>.
/// </summary>
[TestFixture]
public sealed class JsonSourceReaderTests : AxbusTestBase
{
    private JsonSourceReader sut     = null!;
    private string           tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut     = new JsonSourceReader(NullLogger<JsonSourceReader>());
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_ReturnSourceData_When_JsonFileExists.</summary>
    [Test]
    public async Task Should_ReturnSourceData_When_JsonFileExists()
    {
        var filePath = Path.Combine(tempDir, "test.json");
        await File.WriteAllTextAsync(filePath, "[{\"id\":1}]");

        var sourceData = await sut.ReadAsync(new SourceOptions { Path = filePath }, CancellationToken.None);

        Assert.That(sourceData.Format,        Is.EqualTo("json"));
        Assert.That(sourceData.SourcePath,    Is.EqualTo(filePath));
        Assert.That(sourceData.ContentLength, Is.GreaterThan(0));

        await sourceData.RawData.DisposeAsync();
    }

    /// <summary>Should_ThrowConnectorException_When_FileNotFound.</summary>
    [Test]
    public void Should_ThrowConnectorException_When_FileNotFound()
    {
        Assert.ThrowsAsync<AxbusConnectorException>(async () =>
            await sut.ReadAsync(
                new SourceOptions { Path = Path.Combine(tempDir, "missing.json") },
                CancellationToken.None));
    }
}