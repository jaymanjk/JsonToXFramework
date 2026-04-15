// <copyright file="PluginCompatibilityTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Models.Plugin;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="PluginCompatibility"/>.
/// </summary>
[TestFixture]
public sealed class PluginCompatibilityTests : AxbusTestBase
{
    /// <summary>Should_BeCompatible_When_CompatibleFactoryUsed.</summary>
    [Test]
    public void Should_BeCompatible_When_CompatibleFactoryUsed()
    {
        var result = PluginCompatibility.Compatible;

        Assert.That(result.IsCompatible, Is.True);
        Assert.That(result.Reason,       Is.Null);
    }

    /// <summary>Should_BeIncompatible_When_IncompatibleFactoryUsedWithReason.</summary>
    [Test]
    public void Should_BeIncompatible_When_IncompatibleFactoryUsedWithReason()
    {
        var reason = "Requires framework v2.0 but current is v1.0.";
        var result = PluginCompatibility.Incompatible(reason);

        Assert.That(result.IsCompatible, Is.False);
        Assert.That(result.Reason,       Is.EqualTo(reason));
    }
}