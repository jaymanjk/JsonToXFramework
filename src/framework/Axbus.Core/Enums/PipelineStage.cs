// <copyright file="PipelineStage.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Identifies a specific stage within the Axbus conversion pipeline.
/// The pipeline executes stages in the following order:
/// <see cref="Read"/> -> <see cref="Parse"/> -> <see cref="Transform"/>
/// -> <see cref="Write"/>.
/// <see cref="Validate"/> and <see cref="Filter"/> are optional stages
/// that execute between <see cref="Transform"/> and <see cref="Write"/>.
/// </summary>
public enum PipelineStage
{
    /// <summary>
    /// Stage 1: Raw data is read from the source connector as a byte stream.
    /// Implemented by <see cref="Axbus.Core.Abstractions.Pipeline.ISourceReader"/>.
    /// </summary>
    Read = 0,

    /// <summary>
    /// Stage 2: The raw byte stream is parsed into an internal element model.
    /// Implemented by <see cref="Axbus.Core.Abstractions.Pipeline.IFormatParser"/>.
    /// </summary>
    Parse = 1,

    /// <summary>
    /// Stage 3: Parsed elements are flattened and transformed into rows.
    /// Implemented by <see cref="Axbus.Core.Abstractions.Pipeline.IDataTransformer"/>.
    /// </summary>
    Transform = 2,

    /// <summary>
    /// Optional Stage: Rows are validated before writing.
    /// Implemented by <see cref="Axbus.Core.Abstractions.Pipeline.IDataValidator"/>.
    /// </summary>
    Validate = 3,

    /// <summary>
    /// Optional Stage: Rows are filtered based on configured rules.
    /// Implemented by <see cref="Axbus.Core.Abstractions.Pipeline.IDataFilter"/>.
    /// </summary>
    Filter = 4,

    /// <summary>
    /// Stage 4: Transformed rows are written to the target connector.
    /// Implemented by <see cref="Axbus.Core.Abstractions.Pipeline.IOutputWriter"/>.
    /// </summary>
    Write = 5,
}