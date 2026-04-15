// <copyright file="ErrorHandlingIntegrationTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Integration.Tests.Tests;

using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Integration tests for pipeline error handling.
/// </summary>
[TestFixture]
public sealed class ErrorHandlingIntegrationTests : AxbusTestBase
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
        SafeDeleteDirectory(tempDir);
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

    /// <summary>Should_ThrowConnectorException_When_FileDoesNotExist.</summary>
    [Test]
    public void Should_ThrowConnectorException_When_FileDoesNotExist()
    {
        var reader = new JsonSourceReader(NullLogger<JsonSourceReader>());
        Assert.ThrowsAsync<AxbusConnectorException>(async () =>
            await reader.ReadAsync(
                new SourceOptions { Path = Path.Combine(tempDir, "missing.json") },
                CancellationToken.None));
    }

    /// <summary>Should_ThrowPipelineException_When_InvalidJsonParsed.</summary>
    [Test]
    public async Task Should_ThrowPipelineException_When_InvalidJsonParsed()
    {
        var badFile = Path.Combine(tempDir, "bad.json");
        await File.WriteAllTextAsync(badFile, "{ this is not valid json }");

        var reader = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser = new JsonFormatParser(NullLogger<JsonFormatParser>(), new JsonReaderPluginOptions());
        var sd     = await reader.ReadAsync(new SourceOptions { Path = badFile }, CancellationToken.None);
        var pd     = await parser.ParseAsync(sd, CancellationToken.None);

        Assert.ThrowsAsync<AxbusPipelineException>(async () =>
        {
            await foreach (var _ in pd.Elements) { }
        });

        // Dispose the source stream to release file handle
        await sd.RawData.DisposeAsync();
    }

    /// <summary>Should_ThrowPipelineException_When_RootKeyNotFound.</summary>
    [Test]
    public async Task Should_ThrowPipelineException_When_RootKeyNotFound()
    {
        var inputPath = Path.Combine(tempDir, "data.json");
        await File.WriteAllTextAsync(inputPath, "{\"orders\":[{\"id\":\"1\"}]}");

        var reader = new JsonSourceReader(NullLogger<JsonSourceReader>());
        var parser = new JsonFormatParser(NullLogger<JsonFormatParser>(),
            new JsonReaderPluginOptions { RootArrayKey = "items" });

        var sd = await reader.ReadAsync(new SourceOptions { Path = inputPath }, CancellationToken.None);
        var pd = await parser.ParseAsync(sd, CancellationToken.None);

        Assert.ThrowsAsync<AxbusPipelineException>(async () =>
        {
            await foreach (var _ in pd.Elements) { }
        });

        // Dispose the source stream to release file handle
        await sd.RawData.DisposeAsync();
    }
}
