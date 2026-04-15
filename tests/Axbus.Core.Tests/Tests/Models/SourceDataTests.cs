// <copyright file="SourceDataTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="SourceData"/>.
/// </summary>
[TestFixture]
public sealed class SourceDataTests : AxbusTestBase
{
    /// <summary>Should_StoreAllProperties_When_Created.</summary>
    [Test]
    public void Should_StoreAllProperties_When_Created()
    {
        // Arrange
        using var stream = new MemoryStream();
        var sourcePath = "test.json";
        var format = "json";
        var contentLength = 1024L;

        // Act
        var sut = new SourceData(stream, sourcePath, format, contentLength);

        // Assert
        Assert.That(sut.RawData, Is.EqualTo(stream));
        Assert.That(sut.SourcePath, Is.EqualTo(sourcePath));
        Assert.That(sut.Format, Is.EqualTo(format));
        Assert.That(sut.ContentLength, Is.EqualTo(contentLength));
    }

    /// <summary>Should_DefaultContentLength_When_NotProvided.</summary>
    [Test]
    public void Should_DefaultContentLength_When_NotProvided()
    {
        // Arrange
        using var stream = new MemoryStream();

        // Act
        var sut = new SourceData(stream, "test.json", "json");

        // Assert
        Assert.That(sut.ContentLength, Is.EqualTo(-1));
    }
}
