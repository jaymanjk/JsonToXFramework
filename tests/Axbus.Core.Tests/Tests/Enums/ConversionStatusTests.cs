// <copyright file="ConversionStatusTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Enums;

using Axbus.Core.Enums;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ConversionStatus"/> enum.
/// </summary>
[TestFixture]
public sealed class ConversionStatusTests : AxbusTestBase
{
    /// <summary>Should_HaveExpectedValues_When_Enumerated.</summary>
    [Test]
    public void Should_HaveExpectedValues_When_Enumerated()
    {
        // Assert
        Assert.That((int)ConversionStatus.NotStarted, Is.EqualTo(0));
        Assert.That((int)ConversionStatus.Discovering, Is.EqualTo(1));
        Assert.That((int)ConversionStatus.Converting, Is.EqualTo(2));
        Assert.That((int)ConversionStatus.Completed, Is.EqualTo(3));
        Assert.That((int)ConversionStatus.Failed, Is.EqualTo(4));
        Assert.That((int)ConversionStatus.Skipped, Is.EqualTo(5));
    }

    /// <summary>Should_ConvertToString_When_ToString Called.</summary>
    [Test]
    public void Should_ConvertToString_When_ToStringCalled()
    {
        // Act & Assert
        Assert.That(ConversionStatus.NotStarted.ToString(), Is.EqualTo("NotStarted"));
        Assert.That(ConversionStatus.Discovering.ToString(), Is.EqualTo("Discovering"));
        Assert.That(ConversionStatus.Converting.ToString(), Is.EqualTo("Converting"));
        Assert.That(ConversionStatus.Completed.ToString(), Is.EqualTo("Completed"));
        Assert.That(ConversionStatus.Failed.ToString(), Is.EqualTo("Failed"));
        Assert.That(ConversionStatus.Skipped.ToString(), Is.EqualTo("Skipped"));
    }
}
