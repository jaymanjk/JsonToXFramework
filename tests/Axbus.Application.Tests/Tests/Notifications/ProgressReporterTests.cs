// <copyright file="ProgressReporterTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Notifications;

using Axbus.Application.Notifications;
using Axbus.Core.Enums;
using Axbus.Core.Models.Notifications;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ProgressReporter"/>.
/// </summary>
[TestFixture]
public sealed class ProgressReporterTests : AxbusTestBase
{
    private ProgressReporter sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new ProgressReporter(); }

    /// <summary>Should_DeliverProgress_When_ConsumerRegistered.</summary>
    [Test]
    public async Task Should_DeliverProgress_When_ConsumerRegistered()
    {
        ConversionProgress? received = null;
        sut.Register(new Progress<ConversionProgress>(p => received = p));
        sut.Report(new ConversionProgress { ModuleName = "M", PercentComplete = 50 });

        // Progress<T> posts to synchronization context, so wait for callback
        await Task.Delay(50);

        Assert.That(received,                 Is.Not.Null);
        Assert.That(received!.ModuleName,     Is.EqualTo("M"));
        Assert.That(received.PercentComplete, Is.EqualTo(50));
    }

    /// <summary>Should_DeliverToAll_When_MultipleConsumersRegistered.</summary>
    [Test]
    public async Task Should_DeliverToAll_When_MultipleConsumersRegistered()
    {
        var count = 0;
        sut.Register(new Progress<ConversionProgress>(_ => count++));
        sut.Register(new Progress<ConversionProgress>(_ => count++));
        sut.Report(new ConversionProgress { ModuleName = "M" });

        // Progress<T> posts to synchronization context, so wait for callbacks
        await Task.Delay(50);

        Assert.That(count, Is.EqualTo(2));
    }

    /// <summary>Should_NotThrow_When_NoConsumersRegistered.</summary>
    [Test]
    public void Should_NotThrow_When_NoConsumersRegistered()
    {
        Assert.DoesNotThrow(() => sut.Report(new ConversionProgress { ModuleName = "M" }));
    }
}
