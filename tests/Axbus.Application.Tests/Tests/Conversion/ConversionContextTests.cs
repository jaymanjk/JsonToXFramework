// <copyright file="ConversionContextTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Conversion;

using Axbus.Application.Conversion;
using Axbus.Core.Enums;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ConversionContext"/>.
/// </summary>
[TestFixture]
public sealed class ConversionContextTests : AxbusTestBase
{
    /// <summary>Should_StoreModuleAndPath_When_Created.</summary>
    [Test]
    public void Should_StoreModuleAndPath_When_Created()
    {
        // Arrange
        var module = new ConversionModule { ConversionName = "TestModule" };
        var sourcePath = "test.json";

        // Act
        var sut = new ConversionContext(module, sourcePath);

        // Assert
        Assert.That(sut.Module, Is.EqualTo(module));
        Assert.That(sut.CurrentSourcePath, Is.EqualTo(sourcePath));
        Assert.That(sut.IsCancelled, Is.False);
    }

    /// <summary>Should_AllowSettingStageOutputs_When_StagesComplete.</summary>
    [Test]
    public void Should_AllowSettingStageOutputs_When_StagesComplete()
    {
        // Arrange
        var module = new ConversionModule();
        var sut = new ConversionContext(module, "test.json");
        var writeResult = new WriteResult(10, 0, "output.csv", null, OutputFormat.Csv, TimeSpan.Zero);

        // Act
        sut.WriteResult = writeResult;

        // Assert
        Assert.That(sut.WriteResult, Is.EqualTo(writeResult));
    }

    /// <summary>Should_AllowCancellation_When_CancelledSet.</summary>
    [Test]
    public void Should_AllowCancellation_When_CancelledSet()
    {
        // Arrange
        var module = new ConversionModule();
        var sut = new ConversionContext(module, "test.json");

        // Act
        sut.IsCancelled = true;

        // Assert
        Assert.That(sut.IsCancelled, Is.True);
    }

    /// <summary>Should_ThrowArgumentNull_When_ModuleIsNull.</summary>
    [Test]
    public void Should_ThrowArgumentNull_When_ModuleIsNull()
    {
        // Act & Assert
        Assert.Throws<ArgumentNullException>(() => 
            new ConversionContext(null!, "test.json"));
    }

    /// <summary>Should_ThrowArgumentException_When_SourcePathEmpty.</summary>
    [Test]
    public void Should_ThrowArgumentException_When_SourcePathEmpty()
    {
        // Arrange
        var module = new ConversionModule();

        // Act & Assert
        Assert.Throws<ArgumentException>(() => 
            new ConversionContext(module, ""));
    }
}
