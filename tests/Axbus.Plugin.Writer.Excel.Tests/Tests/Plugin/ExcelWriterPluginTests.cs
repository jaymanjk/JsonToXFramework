// <copyright file="ExcelWriterPluginTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Tests.Tests.Plugin;

using Axbus.Core.Enums;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ExcelWriterPlugin"/>.
/// </summary>
[TestFixture]
public sealed class ExcelWriterPluginTests : AxbusTestBase
{
    private ExcelWriterPlugin sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new ExcelWriterPlugin(); }

    /// <summary>Should_HaveCorrectPluginId.</summary>
    [Test]
    public void Should_HaveCorrectPluginId()
    {
        Assert.That(sut.PluginId, Is.EqualTo("axbus.plugin.writer.excel"));
    }

    /// <summary>Should_DeclareWriterOnly_When_CapabilitiesInspected.</summary>
    [Test]
    public void Should_DeclareWriterOnly_When_CapabilitiesInspected()
    {
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Writer), Is.True);
        Assert.That(sut.Capabilities.HasFlag(PluginCapabilities.Reader), Is.False);
    }

    /// <summary>Should_ReturnNullForNonWriterStages.</summary>
    [Test]
    public void Should_ReturnNullForNonWriterStages()
    {
        Assert.That(sut.CreateReader(Services),      Is.Null);
        Assert.That(sut.CreateParser(Services),      Is.Null);
        Assert.That(sut.CreateTransformer(Services), Is.Null);
    }

    /// <summary>Should_ReturnNonNullWriter.</summary>
    [Test]
    public void Should_ReturnNonNullWriter()
    {
        Assert.That(sut.CreateWriter(Services), Is.Not.Null);
    }
}