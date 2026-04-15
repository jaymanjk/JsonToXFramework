// <copyright file="LocalFileSourceConnectorTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Tests.Tests.Connectors;

using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Infrastructure.Connectors;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="LocalFileSourceConnector"/>.
/// </summary>
[TestFixture]
public sealed class LocalFileSourceConnectorTests : AxbusTestBase
{
    private LocalFileSourceConnector sut     = null!;
    private string                   tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut     = new LocalFileSourceConnector(NullLogger<LocalFileSourceConnector>());
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_ReturnOneStreamPerFile_When_AllFilesMode.</summary>
    [Test]
    public async Task Should_ReturnOneStreamPerFile_When_AllFilesMode()
    {
        File.WriteAllText(Path.Combine(tempDir, "a.json"), "[{}]");
        File.WriteAllText(Path.Combine(tempDir, "b.json"), "[{}]");

        var options = new SourceOptions { Path = tempDir, FilePattern = "*.json", ReadMode = "AllFiles" };
        var streams = new List<Stream>();

        await foreach (var s in sut.GetSourceStreamsAsync(options, CancellationToken.None))
            streams.Add(s);

        foreach (var s in streams) s.Dispose();

        Assert.That(streams.Count, Is.EqualTo(2));
    }

    /// <summary>Should_ThrowConnectorException_When_FolderMissing.</summary>
    [Test]
    public void Should_ThrowConnectorException_When_FolderMissing()
    {
        var options = new SourceOptions
        {
            Path     = Path.Combine(tempDir, "nonexistent"),
            ReadMode = "AllFiles",
        };

        Assert.ThrowsAsync<AxbusConnectorException>(async () =>
        {
            await foreach (var _ in sut.GetSourceStreamsAsync(options, CancellationToken.None)) { }
        });
    }
}