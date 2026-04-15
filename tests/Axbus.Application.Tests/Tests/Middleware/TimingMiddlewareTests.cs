// <copyright file="TimingMiddlewareTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Middleware;

using Axbus.Application.Middleware;
using Axbus.Core.Enums;
using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="TimingMiddleware"/>.
/// </summary>
[TestFixture]
public sealed class TimingMiddlewareTests : AxbusTestBase
{
    private TimingMiddleware sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut = new TimingMiddleware();
    }

    /// <summary>Should_SetDurationOnResult_When_StageCompletes.</summary>
    [Test]
    public async Task Should_SetDurationOnResult_When_StageCompletes()
    {
        var context = new PipelineMiddlewareContext("M", "p", PipelineStage.Read);
        var result  = await sut.InvokeAsync(context, () => Task.FromResult(
            new PipelineStageResult { Success = true, Stage = PipelineStage.Read }));

        Assert.That(result.Duration, Is.GreaterThanOrEqualTo(TimeSpan.Zero));
    }

    /// <summary>Should_InvokeNextDelegate_When_MiddlewareExecuted.</summary>
    [Test]
    public async Task Should_InvokeNextDelegate_When_MiddlewareExecuted()
    {
        var nextInvoked = false;
        var context     = new PipelineMiddlewareContext("M", "p", PipelineStage.Parse);

        await sut.InvokeAsync(context, () =>
        {
            nextInvoked = true;
            return Task.FromResult(new PipelineStageResult { Success = true });
        });

        Assert.That(nextInvoked, Is.True);
    }

    /// <summary>Should_PassThroughFailedResult_When_NextFails.</summary>
    [Test]
    public async Task Should_PassThroughFailedResult_When_NextFails()
    {
        var context = new PipelineMiddlewareContext("M", "p", PipelineStage.Write);
        var result  = await sut.InvokeAsync(context, () => Task.FromResult(
            new PipelineStageResult { Success = false, Exception = new Exception("fail") }));

        Assert.That(result.Success, Is.False);
    }
}