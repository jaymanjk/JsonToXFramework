// <copyright file="FileSystemScannerTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Tests.Tests.FileSystem;

using Axbus.Infrastructure.FileSystem;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="FileSystemScanner"/>.
/// </summary>
[TestFixture]
public sealed class FileSystemScannerTests : AxbusTestBase
{
    private FileSystemScanner sut     = null!;
    private string            tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut     = new FileSystemScanner(NullLogger<FileSystemScanner>());
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_ReturnMatchingFiles_When_PatternMatches.</summary>
    [Test]
    public void Should_ReturnMatchingFiles_When_PatternMatches()
    {
        File.WriteAllText(Path.Combine(tempDir, "a.json"), "[]");
        File.WriteAllText(Path.Combine(tempDir, "b.json"), "[]");
        File.WriteAllText(Path.Combine(tempDir, "c.txt"),  "text");

        var results = sut.Scan(tempDir, "*.json").ToList();

        Assert.That(results.Count,                         Is.EqualTo(2));
        Assert.That(results.All(f => f.EndsWith(".json")), Is.True);
    }

    /// <summary>Should_ReturnEmpty_When_FolderDoesNotExist.</summary>
    [Test]
    public void Should_ReturnEmpty_When_FolderDoesNotExist()
    {
        Assert.That(sut.Scan(Path.Combine(tempDir, "missing"), "*.json"), Is.Empty);
    }

    /// <summary>Should_ReturnFilesInAlphaOrder_When_MultipleFilesPresent.</summary>
    [Test]
    public void Should_ReturnFilesInAlphaOrder_When_MultipleFilesPresent()
    {
        File.WriteAllText(Path.Combine(tempDir, "c.json"), "[]");
        File.WriteAllText(Path.Combine(tempDir, "a.json"), "[]");
        File.WriteAllText(Path.Combine(tempDir, "b.json"), "[]");

        var results = sut.Scan(tempDir, "*.json").ToList();

        Assert.That(Path.GetFileName(results[0]), Is.EqualTo("a.json"));
        Assert.That(Path.GetFileName(results[2]), Is.EqualTo("c.json"));
    }

    /// <summary>Should_ReturnEmpty_When_NoFilesMatchPattern.</summary>
    [Test]
    public void Should_ReturnEmpty_When_NoFilesMatchPattern()
    {
        File.WriteAllText(Path.Combine(tempDir, "a.csv"), "data");
        Assert.That(sut.Scan(tempDir, "*.json"), Is.Empty);
    }
}