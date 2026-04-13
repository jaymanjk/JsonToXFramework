// <copyright file="PluginOptionsFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Factories;

using System.Text.Json;
using Axbus.Core.Abstractions.Factories;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Models.Configuration;
using Microsoft.Extensions.Logging;

/// <summary>
/// Deserialises the raw <see cref="ConversionModule.PluginOptions"/> dictionary
/// into a strongly-typed <see cref="IPluginOptions"/> instance. Uses
/// <see cref="JsonSerializer"/> to round-trip the dictionary through JSON
/// so that the plugin's declared options class receives correctly typed values.
/// Unknown keys are captured by properties decorated with
/// <c>[JsonExtensionData]</c> on the options class.
/// </summary>
public sealed class PluginOptionsFactory : IPluginOptionsFactory
{
    /// <summary>
    /// Logger instance for options deserialisation diagnostic messages.
    /// </summary>
    private readonly ILogger<PluginOptionsFactory> logger;

    /// <summary>
    /// JSON serializer options configured for case-insensitive property matching.
    /// </summary>
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    /// <summary>
    /// Initializes a new instance of <see cref="PluginOptionsFactory"/>.
    /// </summary>
    /// <param name="logger">The logger for options deserialisation messages.</param>
    public PluginOptionsFactory(ILogger<PluginOptionsFactory> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Deserialises the plugin options from <paramref name="module"/> into
    /// a strongly-typed <typeparamref name="TOptions"/> instance.
    /// </summary>
    /// <typeparam name="TOptions">The plugin-specific options type.</typeparam>
    /// <param name="module">The conversion module containing the raw plugin options.</param>
    /// <returns>A populated <typeparamref name="TOptions"/> instance.</returns>
    public TOptions Create<TOptions>(ConversionModule module) where TOptions : IPluginOptions, new()
    {
        ArgumentNullException.ThrowIfNull(module);

        if (module.PluginOptions == null || module.PluginOptions.Count == 0)
        {
            // No plugin options configured - return default instance
            return new TOptions();
        }

        try
        {
            // Round-trip through JSON: Dictionary -> JSON string -> TOptions
            var json = JsonSerializer.Serialize(module.PluginOptions, SerializerOptions);
            var options = JsonSerializer.Deserialize<TOptions>(json, SerializerOptions);

            return options ?? new TOptions();
        }
        catch (Exception ex)
        {
            logger.LogWarning(
                ex,
                "Failed to deserialise plugin options for module '{ModuleName}' into {OptionsType}. Using defaults.",
                module.ConversionName,
                typeof(TOptions).Name);

            return new TOptions();
        }
    }
}