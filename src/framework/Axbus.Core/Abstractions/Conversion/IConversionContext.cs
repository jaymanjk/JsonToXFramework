// <copyright file="IConversionContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Conversion;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Carries accumulated state through the conversion pipeline stages for a
/// single source file within a module execution. Each stage reads from and
/// writes to the context so that results are available to subsequent stages
/// and middleware components.
/// </summary>
public interface IConversionContext
{
    /// <summary>Gets the conversion module configuration for this execution.</summary>
    ConversionModule Module { get; }

    /// <summary>Gets or sets the output of Stage 1 (Read). Set after Read completes.</summary>
    SourceData? SourceData { get; set; }

    /// <summary>Gets or sets the output of Stage 2 (Parse). Set after Parse completes.</summary>
    ParsedData? ParsedData { get; set; }

    /// <summary>Gets or sets the output of Stage 3 (Transform). Set after Transform completes.</summary>
    TransformedData? TransformedData { get; set; }

    /// <summary>Gets or sets the output of Stage 4 (Write). Set after Write completes.</summary>
    WriteResult? WriteResult { get; set; }

    /// <summary>Gets the path of the source file currently being processed.</summary>
    string CurrentSourcePath { get; }

    /// <summary>
    /// Gets or sets a value indicating whether processing of this source file
    /// should be cancelled. Set by error handling middleware when a non-recoverable
    /// error occurs and <see cref="ConversionModule.ContinueOnError"/> is <c>false</c>.
    /// </summary>
    bool IsCancelled { get; set; }
}