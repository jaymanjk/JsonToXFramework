// <copyright file="LocalFileTargetConnectorTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Tests.Tests.Connectors;

using System.Text;
using Axbus.Core.Models.Configuration;
using Axbus.Infrastructure.Connectors;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="LocalFileTargetConnector"/>.
/// </summary>
[TestFixture]
public sealed class LocalFileTargetConnectorTests : AxbusTestBase
{
    private LocalFileTargetConnector sut     = null!;
    private string                   tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut     = new LocalFileTargetConnector(NullLogger<LocalFileTargetConnector>());
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_WriteFile_When_ValidStreamProvided.</summary>
    [Test]
    public async Task Should_WriteFile_When_ValidStreamProvided()
    {
        var content = "id,name\n1,Test";
        var data    = new MemoryStream(Encoding.UTF8.GetBytes(content));
        var options = new TargetOptions { Path = tempDir };

        var outputPath = await sut.WriteAsync(data, "output.csv", options, CancellationToken.None);

        Assert.That(File.Exists(outputPath), Is.True);
        Assert.That(await File.ReadAllTextAsync(outputPath), Is.EqualTo(content));
    }

    /// <summary>Should_CreateDirectory_When_TargetFolderMissing.</summary>
    [Test]
    public async Task Should_CreateDirectory_When_TargetFolderMissing()
    {
        var newFolder = Path.Combine(tempDir, "new_sub");
        var data      = new MemoryStream(Encoding.UTF8.GetBytes("data"));
        var options   = new TargetOptions { Path = newFolder };

        await sut.WriteAsync(data, "file.csv", options, CancellationToken.None);

        Assert.That(Directory.Exists(newFolder), Is.True);
    }

    /// <summary>Should_ReturnFullOutputPath_When_WriteSucceeds.</summary>
    [Test]
    public async Task Should_ReturnFullOutputPath_When_WriteSucceeds()
    {
        var data    = new MemoryStream(Encoding.UTF8.GetBytes("test"));
        var options = new TargetOptions { Path = tempDir };

        var result = await sut.WriteAsync(data, "result.csv", options, CancellationToken.None);

        Assert.That(result, Is.EqualTo(Path.Combine(tempDir, "result.csv")));
    }
}