// <copyright file="ConversionPipeline.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Pipeline;

using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Orchestrates the execution of all pipeline stages for a single source file.
/// Assembles the stage chain Read -> Parse -> Transform -> Write by resolving
/// the appropriate plugin implementations and executing each stage through
/// the middleware chain via <see cref="PipelineStageExecutor"/>.
/// One instance is created per conversion module execution.
/// </summary>
public sealed class ConversionPipeline : IConversionPipeline
{
    /// <summary>
    /// Logger instance for structured pipeline diagnostic output.
    /// </summary>
    private readonly ILogger<ConversionPipeline> logger;

    /// <summary>
    /// The plugin resolved for this pipeline execution.
    /// </summary>
    private readonly IPlugin plugin;

    /// <summary>
    /// The executor that wraps each stage in the middleware chain.
    /// </summary>
    private readonly PipelineStageExecutor stageExecutor;

    /// <summary>
    /// The service provider used to create plugin stage instances.
    /// </summary>
    private readonly IServiceProvider serviceProvider;

    /// <summary>
    /// Initializes a new instance of <see cref="ConversionPipeline"/>.
    /// </summary>
    /// <param name="logger">The logger for pipeline lifecycle messages.</param>
    /// <param name="plugin">The resolved plugin providing stage implementations.</param>
    /// <param name="stageExecutor">The executor that wraps stages in middleware.</param>
    /// <param name="serviceProvider">The service provider for plugin stage creation.</param>
    public ConversionPipeline(
        ILogger<ConversionPipeline> logger,
        IPlugin plugin,
        PipelineStageExecutor stageExecutor,
        IServiceProvider serviceProvider)
    {
        this.logger = logger;
        this.plugin = plugin;
        this.stageExecutor = stageExecutor;
        this.serviceProvider = serviceProvider;
    }

    /// <summary>
    /// Executes the full Read -> Parse -> Transform -> Write pipeline
    /// for the source file at <paramref name="sourcePath"/>.
    /// </summary>
    /// <param name="module">The conversion module configuration to use.</param>
    /// <param name="sourcePath">The full path or URI of the source file to process.</param>
    /// <param name="cancellationToken">A token to cancel the pipeline execution.</param>
    /// <returns>A <see cref="WriteResult"/> containing row counts and output paths.</returns>
    /// <exception cref="AxbusPipelineException">
    /// Thrown when a stage fails and cannot be handled by the configured error strategy.
    /// </exception>
    public async Task<WriteResult> ExecuteAsync(
        ConversionModule module,
        string sourcePath,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(module);
        ArgumentException.ThrowIfNullOrWhiteSpace(sourcePath);

        logger.LogInformation(
            "Pipeline starting for module {ModuleName} | File: {SourcePath}",
            module.ConversionName,
            sourcePath);

        // Build per-file source options so the reader opens exactly this file,
        // not the originating folder path from module.Source
        var perFileSource = new SourceOptions
        {
            Type = module.Source.Type,
            Path = sourcePath,
            FilePattern = module.Source.FilePattern,
            ReadMode = "SingleFile",
        };

        // Stage 1: Read
        var reader = plugin.CreateReader(serviceProvider)
            ?? throw new AxbusPipelineException(
                $"Plugin '{plugin.PluginId}' does not support the Read stage.",
                PipelineStage.Read);

        var sourceData = await stageExecutor.ExecuteAsync(
            module.ConversionName,
            plugin.PluginId,
            PipelineStage.Read,
            () => reader.ReadAsync(perFileSource, cancellationToken),
            cancellationToken).ConfigureAwait(false);

        // Stage 2: Parse
        var parser = plugin.CreateParser(serviceProvider)
            ?? throw new AxbusPipelineException(
                $"Plugin '{plugin.PluginId}' does not support the Parse stage.",
                PipelineStage.Parse);

        var parsedData = await stageExecutor.ExecuteAsync(
            module.ConversionName,
            plugin.PluginId,
            PipelineStage.Parse,
            () => parser.ParseAsync(sourceData, cancellationToken),
            cancellationToken).ConfigureAwait(false);

        // Stage 3: Transform
        var transformer = plugin.CreateTransformer(serviceProvider)
            ?? throw new AxbusPipelineException(
                $"Plugin '{plugin.PluginId}' does not support the Transform stage.",
                PipelineStage.Transform);

        var transformedData = await stageExecutor.ExecuteAsync(
            module.ConversionName,
            plugin.PluginId,
            PipelineStage.Transform,
            () => transformer.TransformAsync(parsedData, module.Pipeline, cancellationToken),
            cancellationToken).ConfigureAwait(false);

        // Stage 4: Write
        var writer = plugin.CreateWriter(serviceProvider)
            ?? throw new AxbusPipelineException(
                $"Plugin '{plugin.PluginId}' does not support the Write stage.",
                PipelineStage.Write);

        var writeResult = await stageExecutor.ExecuteAsync(
            module.ConversionName,
            plugin.PluginId,
            PipelineStage.Write,
            () => writer.WriteAsync(transformedData, module.Target, module.Pipeline, cancellationToken),
            cancellationToken).ConfigureAwait(false);

        logger.LogInformation(
            "Pipeline completed for module {ModuleName} | File: {SourcePath} | Rows: {RowsWritten}",
            module.ConversionName,
            sourcePath,
            writeResult.RowsWritten);

        return writeResult;
    }
}
