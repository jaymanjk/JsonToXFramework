// <copyright file="PluginCapabilitiesTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Enums;

using Axbus.Core.Enums;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for the <see cref="PluginCapabilities"/> flags enumeration.
/// </summary>
[TestFixture]
public sealed class PluginCapabilitiesTests : AxbusTestBase
{
    /// <summary>Should_ContainAllCoreStages_When_BundledValueInspected.</summary>
    [Test]
    public void Should_ContainAllCoreStages_When_BundledValueInspected()
    {
        var bundled = PluginCapabilities.Bundled;

        Assert.That(bundled.HasFlag(PluginCapabilities.Reader),      Is.True);
        Assert.That(bundled.HasFlag(PluginCapabilities.Parser),      Is.True);
        Assert.That(bundled.HasFlag(PluginCapabilities.Transformer), Is.True);
        Assert.That(bundled.HasFlag(PluginCapabilities.Writer),      Is.True);
    }

    /// <summary>Should_NotContainValidatorOrFilter_When_BundledValueInspected.</summary>
    [Test]
    public void Should_NotContainValidatorOrFilter_When_BundledValueInspected()
    {
        var bundled = PluginCapabilities.Bundled;

        Assert.That(bundled.HasFlag(PluginCapabilities.Validator), Is.False);
        Assert.That(bundled.HasFlag(PluginCapabilities.Filter),    Is.False);
    }

    /// <summary>Should_AllowWriterOnlyPlugin_When_OnlyWriterCapabilitySet.</summary>
    [Test]
    public void Should_AllowWriterOnlyPlugin_When_OnlyWriterCapabilitySet()
    {
        var writerOnly = PluginCapabilities.Writer;

        Assert.That(writerOnly.HasFlag(PluginCapabilities.Writer), Is.True);
        Assert.That(writerOnly.HasFlag(PluginCapabilities.Reader), Is.False);
    }
}