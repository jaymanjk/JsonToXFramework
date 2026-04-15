// <copyright file="MiddlewarePipelineBuilderTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Middleware;

using Axbus.Application.Middleware;
using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Enums;
using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="MiddlewarePipelineBuilder"/>.
/// </summary>
[TestFixture]
public sealed class MiddlewarePipelineBuilderTests : AxbusTestBase
{
    /// <summary>Should_InvokeStageAction_When_NoMiddlewareRegistered.</summary>
    [Test]
    public async Task Should_InvokeStageAction_When_NoMiddlewareRegistered()
    {
        var builder      = new MiddlewarePipelineBuilder(new List<IPipelineMiddleware>());
        var context      = new PipelineMiddlewareContext("M", "p", PipelineStage.Read);
        var actionCalled = false;

        await builder.ExecuteAsync(context, () =>
        {
            actionCalled = true;
            return Task.FromResult(new PipelineStageResult { Success = true });
        });

        Assert.That(actionCalled, Is.True);
    }

    /// <summary>Should_InvokeMiddlewareOutermostFirst_When_MultipleRegistered.</summary>
    [Test]
    public async Task Should_InvokeMiddlewareOutermostFirst_When_MultipleRegistered()
    {
        var order   = new List<int>();
        var builder = new MiddlewarePipelineBuilder(new[]
        {
            new OrderRecordingMiddleware(1, order),
            new OrderRecordingMiddleware(2, order),
        });

        await builder.ExecuteAsync(
            new PipelineMiddlewareContext("M", "p", PipelineStage.Transform),
            () => Task.FromResult(new PipelineStageResult { Success = true }));

        Assert.That(order[0], Is.EqualTo(1));
        Assert.That(order[1], Is.EqualTo(2));
    }

    private sealed class OrderRecordingMiddleware : IPipelineMiddleware
    {
        private readonly int id;
        private readonly List<int> order;

        public OrderRecordingMiddleware(int id, List<int> order)
        { this.id = id; this.order = order; }

        public async Task<PipelineStageResult> InvokeAsync(
            IPipelineMiddlewareContext context, PipelineStageDelegate next)
        {
            order.Add(id);
            return await next();
        }
    }
}