// <copyright file="ConversionEventTypeTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Enums;

using Axbus.Core.Enums;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ConversionEventType"/> enum.
/// </summary>
[TestFixture]
public sealed class ConversionEventTypeTests : AxbusTestBase
{
    /// <summary>Should_HaveExpectedValues_When_Enumerated.</summary>
    [Test]
    public void Should_HaveExpectedValues_When_Enumerated()
    {
        // Assert - Verify all event types exist
        Assert.That((int)ConversionEventType.ModuleStarted, Is.EqualTo(0));
        Assert.That((int)ConversionEventType.ModuleCompleted, Is.EqualTo(1));
        Assert.That((int)ConversionEventType.ModuleFailed, Is.EqualTo(2));
        Assert.That((int)ConversionEventType.ModuleSkipped, Is.EqualTo(3));
        Assert.That((int)ConversionEventType.FileStarted, Is.EqualTo(4));
        Assert.That((int)ConversionEventType.FileCompleted, Is.EqualTo(5));
        Assert.That((int)ConversionEventType.FileFailed, Is.EqualTo(6));
    }

    /// <summary>Should_ConvertToString_When_ToStringCalled.</summary>
    [Test]
    public void Should_ConvertToString_When_ToStringCalled()
    {
        // Act & Assert
        Assert.That(ConversionEventType.ModuleStarted.ToString(), Is.EqualTo("ModuleStarted"));
        Assert.That(ConversionEventType.ModuleCompleted.ToString(), Is.EqualTo("ModuleCompleted"));
        Assert.That(ConversionEventType.ModuleFailed.ToString(), Is.EqualTo("ModuleFailed"));
    }
}
