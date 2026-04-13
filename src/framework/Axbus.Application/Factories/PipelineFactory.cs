// <copyright file="PipelineFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Factories;

using Axbus.Application.Pipeline;
using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Abstractions.Factories;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Microsoft.Extensions.Logging;

/// <summary>
/// Creates a fully configured <see cref="IConversionPipeline"/> for a specific
/// conversion module. Resolves the appropriate plugin from the registry,
/// assembles the middleware chain and constructs the pipeline instance.
/// </summary>
public sealed class PipelineFactory : IPipelineFactory
{
    /// <summary>
    /// Logger instance for pipeline factory diagnostic messages.
    /// </summary>
    private readonly ILogger<PipelineFactory> logger;

    /// <summary>
    /// Plugin registry used to resolve reader and writer plugins per module.
    /// </summary>
    private readonly IPluginRegistry pluginRegistry;

    /// <summary>
    /// Middleware factory for assembling the stage middleware chain.
    /// </summary>
    private readonly IMiddlewareFactory middlewareFactory;

    /// <summary>
    /// Logger factory for creating typed loggers for pipeline instances.
    /// </summary>
    private readonly ILoggerFactory loggerFactory;

    /// <summary>
    /// Service provider for passing to plugin stage factory methods.
    /// </summary>
    private readonly IServiceProvider serviceProvider;

    /// <summary>
    /// Initializes a new instance of <see cref="PipelineFactory"/>.
    /// </summary>
    /// <param name="logger">The logger for factory operations.</param>
    /// <param name="pluginRegistry">Registry providing plugin resolution.</param>
    /// <param name="middlewareFactory">Factory for the middleware chain.</param>
    /// <param name="loggerFactory">Factory for creating typed loggers.</param>
    /// <param name="serviceProvider">Service provider passed to plugin stage factories.</param>
    public PipelineFactory(
        ILogger<PipelineFactory> logger,
        IPluginRegistry pluginRegistry,
        IMiddlewareFactory middlewareFactory,
        ILoggerFactory loggerFactory,
        IServiceProvider serviceProvider)
    {
        this.logger = logger;
        this.pluginRegistry = pluginRegistry;
        this.middlewareFactory = middlewareFactory;
        this.loggerFactory = loggerFactory;
        this.serviceProvider = serviceProvider;
    }

    /// <summary>
    /// Creates a fully configured <see cref="IConversionPipeline"/> for <paramref name="module"/>.
    /// </summary>
    /// <param name="module">The conversion module to build a pipeline for.</param>
    /// <returns>A ready-to-execute <see cref="IConversionPipeline"/>.</returns>
    /// <exception cref="AxbusPluginException">
    /// Thrown when no suitable plugin can be resolved for the module format combination.
    /// </exception>
    public IConversionPipeline Create(ConversionModule module)
    {
        ArgumentNullException.ThrowIfNull(module);

        // Resolve plugin - use explicit override if specified, otherwise auto-resolve
        var plugin = !string.IsNullOrWhiteSpace(module.PluginOverride)
            ? pluginRegistry.ResolveById(module.PluginOverride)
            : pluginRegistry.Resolve(module.SourceFormat, module.TargetFormat);

        logger.LogDebug(
            "Creating pipeline for module '{ModuleName}' using plugin '{PluginId}'",
            module.ConversionName,
            plugin.PluginId);

        // Build middleware chain for this module's pipeline options
        var middlewareList = middlewareFactory.Create();

        // Create the stage executor that wraps stages in the middleware chain
        var stageExecutor = new PipelineStageExecutor(
            loggerFactory.CreateLogger<PipelineStageExecutor>(),
            middlewareList);

        return new ConversionPipeline(
            loggerFactory.CreateLogger<ConversionPipeline>(),
            plugin,
            stageExecutor,
            serviceProvider);
    }
}