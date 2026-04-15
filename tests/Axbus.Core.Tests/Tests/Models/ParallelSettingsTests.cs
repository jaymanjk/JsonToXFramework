// <copyright file="ParallelSettingsTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Models.Configuration;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ParallelSettings"/>.
/// </summary>
[TestFixture]
public sealed class ParallelSettingsTests : AxbusTestBase
{
    /// <summary>Should_HaveDefaultValues_When_Created.</summary>
    [Test]
    public void Should_HaveDefaultValues_When_Created()
    {
        // Act
        var sut = new ParallelSettings();

        // Assert
        Assert.That(sut.MaxDegreeOfParallelism, Is.EqualTo(Environment.ProcessorCount));
        Assert.That(sut.MaxConcurrentFileReads, Is.EqualTo(4));
        Assert.That(sut.MaxConcurrentFileWrites, Is.EqualTo(2));
    }

    /// <summary>Should_AllowPropertyChanges_When_ValuesSet.</summary>
    [Test]
    public void Should_AllowPropertyChanges_When_ValuesSet()
    {
        // Arrange
        var sut = new ParallelSettings();

        // Act
        sut.MaxDegreeOfParallelism = 8;
        sut.MaxConcurrentFileReads = 10;
        sut.MaxConcurrentFileWrites = 5;

        // Assert
        Assert.That(sut.MaxDegreeOfParallelism, Is.EqualTo(8));
        Assert.That(sut.MaxConcurrentFileReads, Is.EqualTo(10));
        Assert.That(sut.MaxConcurrentFileWrites, Is.EqualTo(5));
    }
}
