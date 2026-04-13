// <copyright file="ParallelSettings.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Configuration;

/// <summary>
/// Controls the degree of parallelism used when executing multiple
/// conversion modules concurrently. These settings act as throttles
/// to prevent resource exhaustion on production servers.
/// Configured under <c>ParallelSettings</c> in <c>appsettings.json</c>.
/// </summary>
public sealed class ParallelSettings
{
    /// <summary>
    /// Gets or sets the maximum number of conversion modules
    /// that may execute concurrently.
    /// Defaults to <see cref="Environment.ProcessorCount"/>.
    /// </summary>
    public int MaxDegreeOfParallelism { get; set; } = Environment.ProcessorCount;

    /// <summary>
    /// Gets or sets the maximum number of source files that may be
    /// read concurrently within a single conversion module.
    /// Defaults to <c>4</c>.
    /// </summary>
    public int MaxConcurrentFileReads { get; set; } = 4;

    /// <summary>
    /// Gets or sets the maximum number of output files that may be
    /// written concurrently within a single conversion module.
    /// Defaults to <c>2</c>.
    /// </summary>
    public int MaxConcurrentFileWrites { get; set; } = 2;
}