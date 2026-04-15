// <copyright file="ConversionModuleTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Models.Configuration;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ConversionModule"/>.
/// </summary>
[TestFixture]
public sealed class ConversionModuleTests : AxbusTestBase
{
    /// <summary>Should_HaveDefaultValues_When_Created.</summary>
    [Test]
    public void Should_HaveDefaultValues_When_Created()
    {
        // Act
        var sut = new ConversionModule();

        // Assert
        Assert.That(sut.ConversionName, Is.Empty);
        Assert.That(sut.IsEnabled, Is.True);
        Assert.That(sut.ExecutionOrder, Is.EqualTo(0));
        Assert.That(sut.ContinueOnError, Is.True);
        Assert.That(sut.RunInParallel, Is.False);
    }

    /// <summary>Should_AllowPropertyChanges_When_ValuesSet.</summary>
    [Test]
    public void Should_AllowPropertyChanges_When_ValuesSet()
    {
        // Arrange
        var sut = new ConversionModule();

        // Act
        sut.ConversionName = "TestModule";
        sut.IsEnabled = false;
        sut.ExecutionOrder = 5;
        sut.SourceFormat = "json";
        sut.TargetFormat = "csv";

        // Assert
        Assert.That(sut.ConversionName, Is.EqualTo("TestModule"));
        Assert.That(sut.IsEnabled, Is.False);
        Assert.That(sut.ExecutionOrder, Is.EqualTo(5));
        Assert.That(sut.SourceFormat, Is.EqualTo("json"));
        Assert.That(sut.TargetFormat, Is.EqualTo("csv"));
    }
}
