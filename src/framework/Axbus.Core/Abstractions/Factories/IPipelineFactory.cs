// <copyright file="IPipelineFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Factories;

using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Models.Configuration;

/// <summary>
/// Creates a configured <see cref="IConversionPipeline"/> for a specific
/// conversion module. Resolves the appropriate reader and writer plugins
/// from the registry and assembles the middleware chain.
/// </summary>
public interface IPipelineFactory
{
    /// <summary>
    /// Creates a fully configured <see cref="IConversionPipeline"/> for
    /// the specified <paramref name="module"/>.
    /// Resolves reader and writer plugins from the registry based on
    /// <see cref="ConversionModule.SourceFormat"/>, <see cref="ConversionModule.TargetFormat"/>
    /// and <see cref="ConversionModule.PluginOverride"/>.
    /// </summary>
    /// <param name="module">The conversion module to build a pipeline for.</param>
    /// <returns>A ready-to-execute <see cref="IConversionPipeline"/>.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPluginException">
    /// Thrown when no suitable plugin can be resolved for the module's format combination.
    /// </exception>
    IConversionPipeline Create(ConversionModule module);
}