// <copyright file="ProgressReporter.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Notifications;

using Axbus.Core.Abstractions.Notifications;
using Axbus.Core.Models.Notifications;

/// <summary>
/// Implements <see cref="IProgressReporter"/> using the standard
/// <see cref="IProgress{T}"/> pattern. Allows multiple consumers to register
/// for progress updates. Each registered consumer is invoked on the
/// synchronisation context that was active when it was registered,
/// ensuring safe UI thread callbacks for WinForms consumers.
/// </summary>
public sealed class ProgressReporter : IProgressReporter
{
    /// <summary>
    /// The list of registered progress consumers.
    /// </summary>
    private readonly List<IProgress<ConversionProgress>> consumers = new();

    /// <summary>
    /// Lock object for thread-safe consumer list access.
    /// </summary>
    private readonly object consumerLock = new();

    /// <summary>
    /// Reports <paramref name="progress"/> to all registered consumers.
    /// Each consumer is invoked independently so that a slow consumer
    /// does not block others.
    /// </summary>
    /// <param name="progress">The current progress state to report.</param>
    public void Report(ConversionProgress progress)
    {
        ArgumentNullException.ThrowIfNull(progress);

        List<IProgress<ConversionProgress>> snapshot;

        lock (consumerLock)
        {
            // Take a snapshot to avoid holding the lock during callbacks
            snapshot = new List<IProgress<ConversionProgress>>(consumers);
        }

        foreach (var consumer in snapshot)
        {
            consumer.Report(progress);
        }
    }

    /// <summary>
    /// Registers a new <see cref="IProgress{ConversionProgress}"/> consumer.
    /// </summary>
    /// <param name="consumer">The progress consumer to register.</param>
    public void Register(IProgress<ConversionProgress> consumer)
    {
        ArgumentNullException.ThrowIfNull(consumer);

        lock (consumerLock)
        {
            consumers.Add(consumer);
        }
    }
}