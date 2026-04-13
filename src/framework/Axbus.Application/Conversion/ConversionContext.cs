// <copyright file="ConversionContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Conversion;

using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Concrete implementation of <see cref="IConversionContext"/>.
/// Carries accumulated stage outputs through the conversion pipeline
/// for a single source file within a module execution.
/// Created by the conversion runner before each file is processed
/// and discarded after the pipeline completes.
/// </summary>
public sealed class ConversionContext : IConversionContext
{
    /// <summary>
    /// Gets the conversion module configuration for this execution.
    /// </summary>
    public ConversionModule Module { get; }

    /// <summary>
    /// Gets or sets the output of Stage 1 (Read). Set after Read completes.
    /// </summary>
    public SourceData? SourceData { get; set; }

    /// <summary>
    /// Gets or sets the output of Stage 2 (Parse). Set after Parse completes.
    /// </summary>
    public ParsedData? ParsedData { get; set; }

    /// <summary>
    /// Gets or sets the output of Stage 3 (Transform). Set after Transform completes.
    /// </summary>
    public TransformedData? TransformedData { get; set; }

    /// <summary>
    /// Gets or sets the output of Stage 4 (Write). Set after Write completes.
    /// </summary>
    public WriteResult? WriteResult { get; set; }

    /// <summary>
    /// Gets the path of the source file currently being processed.
    /// </summary>
    public string CurrentSourcePath { get; }

    /// <summary>
    /// Gets or sets a value indicating whether processing of this source file has been cancelled.
    /// </summary>
    public bool IsCancelled { get; set; }

    /// <summary>
    /// Initializes a new instance of <see cref="ConversionContext"/>.
    /// </summary>
    /// <param name="module">The conversion module configuration for this execution.</param>
    /// <param name="currentSourcePath">The path of the source file being processed.</param>
    public ConversionContext(ConversionModule module, string currentSourcePath)
    {
        ArgumentNullException.ThrowIfNull(module);
        ArgumentException.ThrowIfNullOrWhiteSpace(currentSourcePath);

        Module = module;
        CurrentSourcePath = currentSourcePath;
    }
}