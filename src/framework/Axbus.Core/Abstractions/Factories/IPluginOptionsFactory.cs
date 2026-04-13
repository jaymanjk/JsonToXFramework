// <copyright file="IPluginOptionsFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Factories;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Models.Configuration;

/// <summary>
/// Deserialises the raw <see cref="ConversionModule.PluginOptions"/> dictionary
/// into a strongly-typed <see cref="IPluginOptions"/> instance appropriate
/// for the specified plugin. Unknown keys are captured in an overflow
/// dictionary decorated with <c>[JsonExtensionData]</c>.
/// </summary>
public interface IPluginOptionsFactory
{
    /// <summary>
    /// Deserialises the plugin options from <paramref name="module"/> into
    /// a strongly-typed options instance of type <typeparamref name="TOptions"/>.
    /// </summary>
    /// <typeparam name="TOptions">
    /// The plugin-specific options type that implements <see cref="IPluginOptions"/>.
    /// </typeparam>
    /// <param name="module">
    /// The conversion module whose <see cref="ConversionModule.PluginOptions"/>
    /// dictionary is to be deserialised.
    /// </param>
    /// <returns>A populated <typeparamref name="TOptions"/> instance.</returns>
    TOptions Create<TOptions>(ConversionModule module) where TOptions : IPluginOptions, new();
}