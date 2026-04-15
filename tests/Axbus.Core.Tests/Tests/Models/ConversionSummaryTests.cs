// <copyright file="ConversionSummaryTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Models.Results;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ConversionSummary"/>.
/// </summary>
[TestFixture]
public sealed class ConversionSummaryTests : AxbusTestBase
{
    /// <summary>Should_HaveDefaultValues_When_Created.</summary>
    [Test]
    public void Should_HaveDefaultValues_When_Created()
    {
        // Act
        var sut = new ConversionSummary();

        // Assert
        Assert.That(sut.TotalModules, Is.EqualTo(0));
        Assert.That(sut.SuccessfulModules, Is.EqualTo(0));
        Assert.That(sut.FailedModules, Is.EqualTo(0));
        Assert.That(sut.SkippedModules, Is.EqualTo(0));
        Assert.That(sut.TotalFilesProcessed, Is.EqualTo(0));
        Assert.That(sut.TotalRowsWritten, Is.EqualTo(0));
        Assert.That(sut.TotalErrorRows, Is.EqualTo(0));
        Assert.That(sut.TotalDuration, Is.EqualTo(TimeSpan.Zero));
        Assert.That(sut.Results, Is.Not.Null);
        Assert.That(sut.Results, Is.Empty);
    }

    /// <summary>Should_StoreAllProperties_When_ValuesSet.</summary>
    [Test]
    public void Should_StoreAllProperties_When_ValuesSet()
    {
        // Arrange & Act
        var sut = new ConversionSummary
        {
            TotalModules = 10,
            SuccessfulModules = 8,
            FailedModules = 1,
            SkippedModules = 1,
            TotalFilesProcessed = 50,
            TotalRowsWritten = 1000,
            TotalErrorRows = 5,
            TotalDuration = TimeSpan.FromMinutes(5)
        };

        // Assert
        Assert.That(sut.TotalModules, Is.EqualTo(10));
        Assert.That(sut.SuccessfulModules, Is.EqualTo(8));
        Assert.That(sut.FailedModules, Is.EqualTo(1));
        Assert.That(sut.SkippedModules, Is.EqualTo(1));
        Assert.That(sut.TotalFilesProcessed, Is.EqualTo(50));
        Assert.That(sut.TotalRowsWritten, Is.EqualTo(1000));
        Assert.That(sut.TotalErrorRows, Is.EqualTo(5));
        Assert.That(sut.TotalDuration, Is.EqualTo(TimeSpan.FromMinutes(5)));
    }

    /// <summary>Should_AllowResultsCollection_When_ResultsAdded.</summary>
    [Test]
    public void Should_AllowResultsCollection_When_ResultsAdded()
    {
        // Arrange
        var sut = new ConversionSummary();

        // Act
        sut.Results.Add(new ModuleResult { ModuleName = "Module1" });
        sut.Results.Add(new ModuleResult { ModuleName = "Module2" });

        // Assert
        Assert.That(sut.Results.Count, Is.EqualTo(2));
        Assert.That(sut.Results[0].ModuleName, Is.EqualTo("Module1"));
        Assert.That(sut.Results[1].ModuleName, Is.EqualTo("Module2"));
    }
}
