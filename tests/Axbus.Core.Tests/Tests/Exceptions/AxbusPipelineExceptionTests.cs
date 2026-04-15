// <copyright file="AxbusPipelineExceptionTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Exceptions;

using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="AxbusPipelineException"/>.
/// </summary>
[TestFixture]
public sealed class AxbusPipelineExceptionTests : AxbusTestBase
{
    /// <summary>Should_StoreMessage_When_CreatedWithMessage.</summary>
    [Test]
    public void Should_StoreMessage_When_CreatedWithMessage()
    {
        // Act
        var sut = new AxbusPipelineException("Test error");

        // Assert
        Assert.That(sut.Message, Is.EqualTo("Test error"));
    }

    /// <summary>Should_StoreInnerException_When_CreatedWithInner.</summary>
    [Test]
    public void Should_StoreInnerException_When_CreatedWithInner()
    {
        // Arrange
        var inner = new InvalidOperationException("Inner error");

        // Act
        var sut = new AxbusPipelineException("Outer error", inner);

        // Assert
        Assert.That(sut.Message, Is.EqualTo("Outer error"));
        Assert.That(sut.InnerException, Is.EqualTo(inner));
    }

    /// <summary>Should_StoreStage_When_CreatedWithStage.</summary>
    [Test]
    public void Should_StoreStage_When_CreatedWithStage()
    {
        // Act
        var sut = new AxbusPipelineException("Test error", PipelineStage.Parse);

        // Assert
        Assert.That(sut.Stage, Is.EqualTo(PipelineStage.Parse));
    }

    /// <summary>Should_StoreStageAndInner_When_CreatedWithBoth.</summary>
    [Test]
    public void Should_StoreStageAndInner_When_CreatedWithBoth()
    {
        // Arrange
        var inner = new ArgumentException("Inner error");

        // Act
        var sut = new AxbusPipelineException("Outer error", PipelineStage.Transform, inner);

        // Assert
        Assert.That(sut.Message, Is.EqualTo("Outer error"));
        Assert.That(sut.Stage, Is.EqualTo(PipelineStage.Transform));
        Assert.That(sut.InnerException, Is.EqualTo(inner));
    }
}
