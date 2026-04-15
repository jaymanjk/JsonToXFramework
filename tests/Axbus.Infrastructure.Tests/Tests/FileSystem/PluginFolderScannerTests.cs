// <copyright file="PluginFolderScannerTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Tests.Tests.FileSystem;

using Axbus.Infrastructure.FileSystem;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="PluginFolderScanner"/>.
/// </summary>
[TestFixture]
public sealed class PluginFolderScannerTests : AxbusTestBase
{
    private PluginFolderScanner sut     = null!;
    private string              tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut     = new PluginFolderScanner(NullLogger<PluginFolderScanner>());
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_ReturnFileSet_When_DllAndManifestPresent.</summary>
    [Test]
    public void Should_ReturnFileSet_When_DllAndManifestPresent()
    {
        File.WriteAllText(Path.Combine(tempDir, "MyPlugin.dll"),           "fake");
        File.WriteAllText(Path.Combine(tempDir, "MyPlugin.manifest.json"), "{}");

        var results = sut.Scan(tempDir, scanSubFolders: false).ToList();

        Assert.That(results.Count,                                     Is.EqualTo(1));
        Assert.That(Path.GetFileName(results[0].AssemblyPath),         Is.EqualTo("MyPlugin.dll"));
        Assert.That(File.Exists(results[0].ManifestPath),              Is.True);
    }

    /// <summary>Should_SkipDll_When_ManifestMissing.</summary>
    [Test]
    public void Should_SkipDll_When_ManifestMissing()
    {
        File.WriteAllText(Path.Combine(tempDir, "OrphanPlugin.dll"), "fake");
        Assert.That(sut.Scan(tempDir, scanSubFolders: false), Is.Empty);
    }

    /// <summary>Should_ReturnEmpty_When_FolderNotFound.</summary>
    [Test]
    public void Should_ReturnEmpty_When_FolderNotFound()
    {
        Assert.That(sut.Scan(Path.Combine(tempDir, "missing"), scanSubFolders: false), Is.Empty);
    }
}