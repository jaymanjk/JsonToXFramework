// <copyright file="ConversionEvent.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Notifications;

using Axbus.Core.Enums;

/// <summary>
/// Represents a discrete lifecycle event published to the
/// <see cref="Axbus.Core.Abstractions.Notifications.IEventPublisher"/> observable stream.
/// UI consumers can subscribe to this stream to build live event logs, dashboards
/// or audit trails. Each event is identified by its <see cref="Type"/> and
/// includes contextual information such as the module name and affected file.
/// </summary>
public sealed class ConversionEvent
{
    /// <summary>Gets or sets the UTC timestamp at which this event occurred.</summary>
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    /// <summary>Gets or sets the name of the conversion module that raised this event.</summary>
    public string ModuleName { get; set; } = string.Empty;

    /// <summary>Gets or sets the type of lifecycle event that occurred.</summary>
    public ConversionEventType Type { get; set; }

    /// <summary>Gets or sets a human-readable message describing the event.</summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the name of the file associated with this event, if applicable.
    /// </summary>
    public string? FileName { get; set; }

    /// <summary>
    /// Gets or sets the exception associated with this event, if applicable.
    /// Only set for failure events such as <see cref="ConversionEventType.ModuleFailed"/>
    /// or <see cref="ConversionEventType.FileFailed"/>.
    /// </summary>
    public Exception? Exception { get; set; }
}