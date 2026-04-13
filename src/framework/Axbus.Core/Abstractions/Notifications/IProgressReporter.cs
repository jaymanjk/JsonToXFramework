// <copyright file="IProgressReporter.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Notifications;

using Axbus.Core.Models.Notifications;

/// <summary>
/// Reports conversion progress to UI consumers via the standard
/// <see cref="IProgress{T}"/> mechanism. Implementations calculate
/// the percentage complete from file and row counts and invoke the
/// registered <see cref="IProgress{ConversionProgress}"/> callback
/// on the correct synchronisation context.
/// </summary>
public interface IProgressReporter
{
    /// <summary>
    /// Reports the current <see cref="ConversionProgress"/> to all registered consumers.
    /// </summary>
    /// <param name="progress">The current progress state to report.</param>
    void Report(ConversionProgress progress);

    /// <summary>
    /// Registers an <see cref="IProgress{ConversionProgress}"/> consumer.
    /// Can be called by UI layers (WinForms, Console) to receive progress updates.
    /// </summary>
    /// <param name="consumer">The progress consumer to register.</param>
    void Register(IProgress<ConversionProgress> consumer);
}