// <copyright file="ConversionEventTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Enums;
using Axbus.Core.Models.Notifications;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ConversionEvent"/>.
/// </summary>
[TestFixture]
public sealed class ConversionEventTests : AxbusTestBase
{
    /// <summary>Should_StoreAllProperties_When_Created.</summary>
    [Test]
    public void Should_StoreAllProperties_When_Created()
    {
        // Arrange
        var timestamp = DateTime.UtcNow;

        // Act
        var sut = new ConversionEvent
        {
            Timestamp = timestamp,
            ModuleName = "TestModule",
            Type = ConversionEventType.ModuleStarted,
            Message = "Module started",
            FileName = "test.json"
        };

        // Assert
        Assert.That(sut.Timestamp, Is.EqualTo(timestamp));
        Assert.That(sut.ModuleName, Is.EqualTo("TestModule"));
        Assert.That(sut.Type, Is.EqualTo(ConversionEventType.ModuleStarted));
        Assert.That(sut.Message, Is.EqualTo("Module started"));
        Assert.That(sut.FileName, Is.EqualTo("test.json"));
    }

    /// <summary>Should_SetTimestamp_When_Created.</summary>
    [Test]
    public void Should_SetTimestamp_When_Created()
    {
        // Act
        var sut = new ConversionEvent();

        // Assert - Timestamp should be close to now
        Assert.That(sut.Timestamp, Is.EqualTo(DateTime.UtcNow).Within(TimeSpan.FromSeconds(1)));
    }

    /// <summary>Should_AllowExceptionStorage_When_ErrorOccurs.</summary>
    [Test]
    public void Should_AllowExceptionStorage_When_ErrorOccurs()
    {
        // Arrange
        var exception = new InvalidOperationException("Test error");

        // Act
        var sut = new ConversionEvent
        {
            Type = ConversionEventType.ModuleFailed,
            Exception = exception
        };

        // Assert
        Assert.That(sut.Exception, Is.EqualTo(exception));
    }
}
