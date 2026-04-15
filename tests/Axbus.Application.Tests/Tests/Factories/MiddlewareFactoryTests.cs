// <copyright file="MiddlewareFactoryTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Factories;

using Axbus.Application.Factories;
using Axbus.Application.Middleware;
using Axbus.Core.Enums;
using Axbus.Core.Models.Configuration;
using Axbus.Tests.Common.Base;
using Microsoft.Extensions.Logging;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="MiddlewareFactory"/>.
/// </summary>
[TestFixture]
public sealed class MiddlewareFactoryTests : AxbusTestBase
{
    private MiddlewareFactory sut = null!;
    private PipelineOptions pipelineOptions = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        pipelineOptions = new PipelineOptions
        {
            SchemaStrategy = SchemaStrategy.FullScan,
            RowErrorStrategy = RowErrorStrategy.WriteToErrorFile
        };
        sut = new MiddlewareFactory(NullLoggerFactory, pipelineOptions);
    }

    /// <summary>Should_CreateMiddlewareChain_When_CreateCalled.</summary>
    [Test]
    public void Should_CreateMiddlewareChain_When_CreateCalled()
    {
        // Act
        var middleware = sut.Create();

        // Assert
        Assert.That(middleware, Is.Not.Null);
        Assert.That(middleware.Count, Is.GreaterThan(0));
    }

    /// <summary>Should_IncludeLoggingMiddleware_When_ChainCreated.</summary>
    [Test]
    public void Should_IncludeLoggingMiddleware_When_ChainCreated()
    {
        // Act
        var middleware = sut.Create();

        // Assert
        Assert.That(middleware.Any(m => m is LoggingMiddleware), Is.True);
    }

    /// <summary>Should_IncludeTimingMiddleware_When_ChainCreated.</summary>
    [Test]
    public void Should_IncludeTimingMiddleware_When_ChainCreated()
    {
        // Act
        var middleware = sut.Create();

        // Assert
        Assert.That(middleware.Any(m => m is TimingMiddleware), Is.True);
    }

    /// <summary>Should_IncludeErrorHandlingMiddleware_When_ChainCreated.</summary>
    [Test]
    public void Should_IncludeErrorHandlingMiddleware_When_ChainCreated()
    {
        // Act
        var middleware = sut.Create();

        // Assert
        Assert.That(middleware.Any(m => m is ErrorHandlingMiddleware), Is.True);
    }

    /// <summary>Should_OrderMiddlewareCorrectly_When_ChainCreated.</summary>
    [Test]
    public void Should_OrderMiddlewareCorrectly_When_ChainCreated()
    {
        // Act
        var middleware = sut.Create();

        // Assert - Logging should be first (outermost)
        Assert.That(middleware[0], Is.TypeOf<LoggingMiddleware>());
        
        // Timing should be second
        Assert.That(middleware[1], Is.TypeOf<TimingMiddleware>());
        
        // ErrorHandling should be last (innermost)
        Assert.That(middleware[2], Is.TypeOf<ErrorHandlingMiddleware>());
    }

    /// <summary>Should_CreateNewChainEachTime_When_CreateCalledMultipleTimes.</summary>
    [Test]
    public void Should_CreateNewChainEachTime_When_CreateCalledMultipleTimes()
    {
        // Act
        var chain1 = sut.Create();
        var chain2 = sut.Create();

        // Assert - Should be different instances
        Assert.That(chain1, Is.Not.SameAs(chain2));
    }
}
