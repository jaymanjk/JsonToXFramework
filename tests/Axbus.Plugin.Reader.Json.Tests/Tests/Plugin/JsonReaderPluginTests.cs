// <copyright file="JsonReaderPluginTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Tests.Tests.Plugin;

using Axbus.Core.Enums;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="JsonReaderPlugin"/>.
/// </summary>
[TestFixture]
public sealed class JsonReaderPluginTests : AxbusTestBase
{
    private JsonReaderPlugin sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new JsonReaderPlugin(); }

    /// <summary>Should_HaveCorrectPluginId.</summary>
    [Test]
    public void Should_HaveCorrectPluginId()
    {
        Assert.That(sut.PluginId, Is.EqualTo("axbus.plugin.reader.json"));
    }

    /// <summary>Should_DeclareReaderParserTransformer_When_CapabilitiesInspected.</summary>
    [Test]
    public void Should_DeclareReaderParserTransformer_When_CapabilitiesInspected()
    {
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Reader),      Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Parser),      Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Transformer), Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Writer),      Is.False);
    }

    /// <summary>Should_ReturnNullWriter_When_CreateWriterCalled.</summary>
    [Test]
    public void Should_ReturnNullWriter_When_CreateWriterCalled()
    {
        Assert.That(sut.CreateWriter(Services), Is.Null);
    }

    /// <summary>Should_ReturnNonNullStages_When_SupportedFactoriesCalled.</summary>
    [Test]
    public void Should_ReturnNonNullStages_When_SupportedFactoriesCalled()
    {
        Assert.That(sut.CreateReader(Services),      Is.Not.Null);
        Assert.That(sut.CreateParser(Services),      Is.Not.Null);
        Assert.That(sut.CreateTransformer(Services), Is.Not.Null);
    }
}