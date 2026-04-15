// <copyright file="PluginManifestReaderTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Plugin;

using System.Text;
using Axbus.Application.Plugin;
using Axbus.Core.Exceptions;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="PluginManifestReader"/>.
/// </summary>
[TestFixture]
public sealed class PluginManifestReaderTests : AxbusTestBase
{
    private PluginManifestReader sut     = null!;
    private string               tempDir = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut     = new PluginManifestReader(NullLogger<PluginManifestReader>());
        tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        base.TearDown();
        if (Directory.Exists(tempDir)) Directory.Delete(tempDir, recursive: true);
    }

    /// <summary>Should_DeserialiseManifest_When_ValidJsonProvided.</summary>
    [Test]
    public async Task Should_DeserialiseManifest_When_ValidJsonProvided()
    {
        var path = Path.Combine(tempDir, "test.manifest.json");
        var json = """
            {
                "Name": "TestPlugin", "PluginId": "test.plugin",
                "Version": "1.0.0", "FrameworkVersion": "1.0.0",
                "SourceFormat": "json", "TargetFormat": null,
                "SupportedStages": ["Read","Parse"],
                "IsBundled": false, "Author": "AJI",
                "Description": "Test", "Dependencies": []
            }
            """;

        await File.WriteAllTextAsync(path, json, Encoding.UTF8);
        var manifest = await sut.ReadAsync(path, CancellationToken.None);

        Assert.That(manifest.Name,     Is.EqualTo("TestPlugin"));
        Assert.That(manifest.PluginId, Is.EqualTo("test.plugin"));
        Assert.That(manifest.SupportedStages.Count, Is.EqualTo(2));
    }

    /// <summary>Should_ThrowPluginException_When_FileNotFound.</summary>
    [Test]
    public void Should_ThrowPluginException_When_FileNotFound()
    {
        Assert.ThrowsAsync<AxbusPluginException>(async () =>
            await sut.ReadAsync(Path.Combine(tempDir, "missing.json"), CancellationToken.None));
    }

    /// <summary>Should_ThrowPluginException_When_InvalidJsonInManifest.</summary>
    [Test]
    public async Task Should_ThrowPluginException_When_InvalidJsonInManifest()
    {
        var path = Path.Combine(tempDir, "bad.manifest.json");
        await File.WriteAllTextAsync(path, "{ invalid }", Encoding.UTF8);

        Assert.ThrowsAsync<AxbusPluginException>(async () =>
            await sut.ReadAsync(path, CancellationToken.None));
    }
}