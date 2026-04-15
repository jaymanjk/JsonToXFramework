// <copyright file="EventPublisherTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Notifications;

using Axbus.Application.Notifications;
using Axbus.Core.Enums;
using Axbus.Core.Models.Notifications;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="EventPublisher"/>.
/// </summary>
[TestFixture]
public sealed class EventPublisherTests : AxbusTestBase
{
    private EventPublisher sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        sut = new EventPublisher(NullLogger<EventPublisher>());
    }

    /// <inheritdoc/>
    public override void TearDown()
    {
        sut?.Dispose();
        base.TearDown();
    }

    /// <summary>Should_PublishEvent_When_Subscribed.</summary>
    [Test]
    public void Should_PublishEvent_When_Subscribed()
    {
        // Arrange
        ConversionEvent? received = null;
        sut.Events.Subscribe(e => received = e);

        var testEvent = new ConversionEvent
        {
            ModuleName = "TestModule",
            Type = ConversionEventType.ModuleStarted,
            Timestamp = DateTime.UtcNow
        };

        // Act
        sut.Publish(testEvent);

        // Assert
        Assert.That(received, Is.Not.Null);
        Assert.That(received!.ModuleName, Is.EqualTo("TestModule"));
        Assert.That(received.Type, Is.EqualTo(ConversionEventType.ModuleStarted));
    }

    /// <summary>Should_PublishToMultipleSubscribers_When_MultipleSubscribed.</summary>
    [Test]
    public void Should_PublishToMultipleSubscribers_When_MultipleSubscribed()
    {
        // Arrange
        var count = 0;
        sut.Events.Subscribe(_ => count++);
        sut.Events.Subscribe(_ => count++);

        var testEvent = new ConversionEvent
        {
            ModuleName = "Test",
            Type = ConversionEventType.ModuleCompleted
        };

        // Act
        sut.Publish(testEvent);

        // Assert
        Assert.That(count, Is.EqualTo(2));
    }

    /// <summary>Should_CompleteStream_When_CompleteCalled.</summary>
    [Test]
    public void Should_CompleteStream_When_CompleteCalled()
    {
        // Arrange
        var completed = false;
        sut.Events.Subscribe(
            onNext: _ => { },
            onCompleted: () => completed = true);

        // Act
        sut.Complete();

        // Assert
        Assert.That(completed, Is.True);
    }

    /// <summary>Should_NotPublishAfterComplete_When_CompleteCalled.</summary>
    [Test]
    public void Should_NotPublishAfterComplete_When_CompleteCalled()
    {
        // Arrange
        var receivedCount = 0;
        sut.Events.Subscribe(_ => receivedCount++);

        var testEvent = new ConversionEvent
        {
            ModuleName = "Test",
            Type = ConversionEventType.ModuleStarted
        };

        // Act
        sut.Publish(testEvent);
        sut.Complete();
        sut.Publish(testEvent); // Should be ignored

        // Assert
        Assert.That(receivedCount, Is.EqualTo(1));
    }
}
