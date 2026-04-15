// <copyright file="PipelineStageTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Enums;

using Axbus.Core.Enums;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="PipelineStage"/> enum.
/// </summary>
[TestFixture]
public sealed class PipelineStageTests : AxbusTestBase
{
    /// <summary>Should_HaveExpectedValues_When_Enumerated.</summary>
    [Test]
    public void Should_HaveExpectedValues_When_Enumerated()
    {
        // Assert - Verify execution order
        Assert.That((int)PipelineStage.Read, Is.EqualTo(0));
        Assert.That((int)PipelineStage.Parse, Is.EqualTo(1));
        Assert.That((int)PipelineStage.Transform, Is.EqualTo(2));
        Assert.That((int)PipelineStage.Validate, Is.EqualTo(3));
        Assert.That((int)PipelineStage.Filter, Is.EqualTo(4));
        Assert.That((int)PipelineStage.Write, Is.EqualTo(5));
    }

    /// <summary>Should_ConvertToString_When_ToStringCalled.</summary>
    [Test]
    public void Should_ConvertToString_When_ToStringCalled()
    {
        // Act & Assert
        Assert.That(PipelineStage.Read.ToString(), Is.EqualTo("Read"));
        Assert.That(PipelineStage.Parse.ToString(), Is.EqualTo("Parse"));
        Assert.That(PipelineStage.Transform.ToString(), Is.EqualTo("Transform"));
        Assert.That(PipelineStage.Write.ToString(), Is.EqualTo("Write"));
    }
}
