// <copyright file="WriteResultTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Enums;
using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="WriteResult"/>.
/// </summary>
[TestFixture]
public sealed class WriteResultTests : AxbusTestBase
{
    /// <summary>Should_StoreAllProperties_When_Created.</summary>
    [Test]
    public void Should_StoreAllProperties_When_Created()
    {
        // Arrange & Act
        var sut = new WriteResult(
            RowsWritten: 100,
            ErrorRowsWritten: 5,
            OutputPath: "output.csv",
            ErrorFilePath: "errors.csv",
            Format: OutputFormat.Csv,
            Duration: TimeSpan.FromSeconds(2));

        // Assert
        Assert.That(sut.RowsWritten, Is.EqualTo(100));
        Assert.That(sut.ErrorRowsWritten, Is.EqualTo(5));
        Assert.That(sut.OutputPath, Is.EqualTo("output.csv"));
        Assert.That(sut.ErrorFilePath, Is.EqualTo("errors.csv"));
        Assert.That(sut.Format, Is.EqualTo(OutputFormat.Csv));
        Assert.That(sut.Duration, Is.EqualTo(TimeSpan.FromSeconds(2)));
    }

    /// <summary>Should_AllowNullErrorPath_When_NoErrors.</summary>
    [Test]
    public void Should_AllowNullErrorPath_When_NoErrors()
    {
        // Arrange & Act
        var sut = new WriteResult(
            RowsWritten: 100,
            ErrorRowsWritten: 0,
            OutputPath: "output.csv",
            ErrorFilePath: null,
            Format: OutputFormat.Csv,
            Duration: TimeSpan.FromSeconds(2));

        // Assert
        Assert.That(sut.ErrorFilePath, Is.Null);
        Assert.That(sut.ErrorRowsWritten, Is.EqualTo(0));
    }
}
