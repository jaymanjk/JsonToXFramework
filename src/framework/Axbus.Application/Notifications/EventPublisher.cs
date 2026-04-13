// <copyright file="EventPublisher.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Notifications;

using System.Reactive.Subjects;
using Axbus.Core.Abstractions.Notifications;
using Axbus.Core.Models.Notifications;
using Microsoft.Extensions.Logging;

/// <summary>
/// Implements <see cref="IEventPublisher"/> using a
/// <see cref="Subject{T}"/> from System.Reactive.
/// Publishes <see cref="ConversionEvent"/> notifications to all current
/// subscribers. The subject is thread-safe for concurrent publishers.
/// UI consumers should subscribe before calling
/// <see cref="Axbus.Core.Abstractions.Conversion.IConversionRunner.RunAsync"/>
/// to avoid missing events.
/// </summary>
public sealed class EventPublisher : IEventPublisher, IDisposable
{
    /// <summary>
    /// Logger instance for event publishing diagnostic messages.
    /// </summary>
    private readonly ILogger<EventPublisher> logger;

    /// <summary>
    /// The reactive subject that acts as both observer and observable.
    /// </summary>
    private readonly Subject<ConversionEvent> subject = new();

    /// <summary>
    /// Initializes a new instance of <see cref="EventPublisher"/>.
    /// </summary>
    /// <param name="logger">The logger for event publishing messages.</param>
    public EventPublisher(ILogger<EventPublisher> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Gets the observable stream of conversion events.
    /// </summary>
    public IObservable<ConversionEvent> Events => subject;

    /// <summary>
    /// Publishes a <see cref="ConversionEvent"/> to all current subscribers.
    /// </summary>
    /// <param name="conversionEvent">The event to publish.</param>
    public void Publish(ConversionEvent conversionEvent)
    {
        ArgumentNullException.ThrowIfNull(conversionEvent);

        logger.LogDebug(
            "Event published: {EventType} | Module: {ModuleName}",
            conversionEvent.Type,
            conversionEvent.ModuleName);

        subject.OnNext(conversionEvent);
    }

    /// <summary>
    /// Signals that the event stream is complete. No further events will be published.
    /// </summary>
    public void Complete()
    {
        subject.OnCompleted();
        logger.LogDebug("Event stream completed.");
    }

    /// <summary>
    /// Releases the underlying reactive subject.
    /// </summary>
    public void Dispose()
    {
        subject.Dispose();
    }
}