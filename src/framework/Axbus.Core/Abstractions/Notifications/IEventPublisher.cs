// <copyright file="IEventPublisher.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Notifications;

using Axbus.Core.Models.Notifications;

/// <summary>
/// Publishes conversion lifecycle events to an observable stream.
/// Implemented using <c>System.Reactive</c> subjects. UI consumers can
/// subscribe to <see cref="Events"/> to receive a real-time stream of
/// <see cref="ConversionEvent"/> notifications.
/// </summary>
public interface IEventPublisher
{
    /// <summary>
    /// Gets the observable stream of conversion events.
    /// Subscribe before calling
    /// <see cref="Axbus.Core.Abstractions.Conversion.IConversionRunner.RunAsync"/>
    /// to ensure no events are missed.
    /// </summary>
    IObservable<ConversionEvent> Events { get; }

    /// <summary>
    /// Publishes a <see cref="ConversionEvent"/> to all current subscribers.
    /// Called internally by the conversion runner and pipeline components.
    /// </summary>
    /// <param name="conversionEvent">The event to publish.</param>
    void Publish(ConversionEvent conversionEvent);

    /// <summary>
    /// Signals that the event stream has completed and no further events will be published.
    /// Called by the conversion runner after all modules have finished executing.
    /// </summary>
    void Complete();
}