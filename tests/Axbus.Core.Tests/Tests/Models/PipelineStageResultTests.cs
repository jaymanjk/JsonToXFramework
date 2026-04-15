// <copyright file="PipelineStageResultTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Enums;
using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="PipelineStageResult"/>.
/// </summary>
[TestFixture]
public sealed class PipelineStageResultTests : AxbusTestBase
{
    /// <summary>Should_IndicateSuccess_When_SuccessTrue.</summary>
    [Test]
    public void Should_IndicateSuccess_When_SuccessTrue()
    {
        // Act
        var sut = new PipelineStageResult
        {
            Success = true,
            Stage = PipelineStage.Read,
            Duration = TimeSpan.FromSeconds(2)
        };

        // Assert
        Assert.That(sut.Success, Is.True);
        Assert.That(sut.Stage, Is.EqualTo(PipelineStage.Read));
        Assert.That(sut.Duration, Is.EqualTo(TimeSpan.FromSeconds(2)));
        Assert.That(sut.Exception, Is.Null);
    }

    /// <summary>Should_IndicateFailure_When_SuccessFalse.</summary>
    [Test]
    public void Should_IndicateFailure_When_SuccessFalse()
    {
        // Arrange
        var exception = new InvalidOperationException("Test error");

        // Act
        var sut = new PipelineStageResult
        {
            Success = false,
            Stage = PipelineStage.Parse,
            Exception = exception
        };

        // Assert
        Assert.That(sut.Success, Is.False);
        Assert.That(sut.Exception, Is.EqualTo(exception));
    }

    /// <summary>Should_StoreOutputData_When_StageSucceeds.</summary>
    [Test]
    public void Should_StoreOutputData_When_StageSucceeds()
    {
        // Arrange
        var output = new { Data = "test" };

        // Act
        var sut = new PipelineStageResult
        {
            Success = true,
            Stage = PipelineStage.Transform,
            Output = output
        };

        // Assert
        Assert.That(sut.Output, Is.EqualTo(output));
    }
}
