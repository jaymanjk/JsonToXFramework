// <copyright file="ConversionEventType.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Identifies the type of event published to the
/// <see cref="Axbus.Core.Abstractions.Notifications.IEventPublisher"/> observable stream.
/// Consumers can filter the event stream by type to react to specific lifecycle events.
/// </summary>
public enum ConversionEventType
{
    /// <summary>A conversion module has started execution.</summary>
    ModuleStarted = 0,

    /// <summary>A conversion module completed successfully.</summary>
    ModuleCompleted = 1,

    /// <summary>A conversion module failed with an unrecoverable error.</summary>
    ModuleFailed = 2,

    /// <summary>A conversion module was skipped because it is disabled.</summary>
    ModuleSkipped = 3,

    /// <summary>Processing of a single source file has started.</summary>
    FileStarted = 4,

    /// <summary>Processing of a single source file completed successfully.</summary>
    FileCompleted = 5,

    /// <summary>Processing of a single source file failed.</summary>
    FileFailed = 6,

    /// <summary>Schema discovery across source files has started.</summary>
    SchemaDiscoveryStarted = 7,

    /// <summary>Schema discovery completed and the column schema is finalised.</summary>
    SchemaDiscoveryCompleted = 8,

    /// <summary>A single row has been successfully processed and written.</summary>
    RowProcessed = 9,

    /// <summary>A row failed to process and was handled per the configured row error strategy.</summary>
    RowFailed = 10,

    /// <summary>An output file has been written to the target connector.</summary>
    OutputWritten = 11,
}