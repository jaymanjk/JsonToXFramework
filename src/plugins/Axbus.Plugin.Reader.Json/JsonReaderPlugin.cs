// <copyright file="JsonReaderPlugin.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json;

using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Reader;
using Axbus.Plugin.Reader.Json.Transformer;
using Axbus.Plugin.Reader.Json.Validators;
using Microsoft.Extensions.Logging;

/// <summary>
/// The entry-point <see cref="IPlugin"/> implementation for the
/// <c>Axbus.Plugin.Reader.Json</c> plugin. This plugin handles the
/// Read, Parse and Transform pipeline stages for JSON source files.
/// It does not implement the Write stage (<see cref="CreateWriter"/> returns null).
/// Register this plugin by adding <c>Axbus.Plugin.Reader.Json</c> to the
/// <c>PluginSettings.Plugins</c> list in <c>appsettings.json</c>.
/// </summary>
public sealed class JsonReaderPlugin : IPlugin
{
    /// <summary>Gets the unique reverse-domain identifier of this plugin.</summary>
    public string PluginId => "axbus.plugin.reader.json";

    /// <summary>Gets the display name of this plugin.</summary>
    public string Name => "JsonReader";

    /// <summary>Gets the semantic version of this plugin.</summary>
    public Version Version => new(1, 0, 0);

    /// <summary>Gets the minimum Axbus framework version required by this plugin.</summary>
    public Version MinFrameworkVersion => new(1, 0, 0);

    /// <summary>
    /// Gets the pipeline capabilities supported by this plugin.
    /// Supports Read, Parse and Transform stages only.
    /// </summary>
    public PluginCapabilities Capabilities =>
        PluginCapabilities.Reader | PluginCapabilities.Parser | PluginCapabilities.Transformer;

    /// <summary>
    /// The options resolved during <see cref="InitializeAsync"/>.
    /// </summary>
    private JsonReaderPluginOptions resolvedOptions = new();

    /// <summary>
    /// Creates the <see cref="ISourceReader"/> for this plugin.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>A new <see cref="JsonSourceReader"/> instance.</returns>
    public ISourceReader? CreateReader(IServiceProvider services)
    {
        var logger = GetLogger<JsonSourceReader>(services);
        return new JsonSourceReader(logger);
    }

    /// <summary>
    /// Creates the <see cref="IFormatParser"/> for this plugin.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>A new <see cref="JsonFormatParser"/> instance.</returns>
    public IFormatParser? CreateParser(IServiceProvider services)
    {
        var logger = GetLogger<JsonFormatParser>(services);
        return new JsonFormatParser(logger, resolvedOptions);
    }

    /// <summary>
    /// Creates the <see cref="IDataTransformer"/> for this plugin.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>A new <see cref="JsonDataTransformer"/> instance.</returns>
    public IDataTransformer? CreateTransformer(IServiceProvider services)
    {
        var logger = GetLogger<JsonDataTransformer>(services);
        return new JsonDataTransformer(logger, resolvedOptions);
    }

    /// <summary>
    /// This plugin does not support the Write stage.
    /// </summary>
    /// <param name="services">The service provider (unused).</param>
    /// <returns>Always <c>null</c>.</returns>
    public IOutputWriter? CreateWriter(IServiceProvider services) => null;

    /// <summary>
    /// Initializes this plugin by validating options and storing them for
    /// use by stage factory methods.
    /// </summary>
    /// <param name="context">The plugin context providing options and logger.</param>
    /// <param name="cancellationToken">A token to cancel initialisation.</param>
    public Task InitializeAsync(IPluginContext context, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(context);

        context.Logger.LogInformation(
            "JsonReaderPlugin initialising: {PluginId} v{Version}",
            PluginId,
            Version);

        // Extract and validate plugin options
        if (context.Options is JsonReaderPluginOptions typedOptions)
        {
            var validator = new JsonReaderOptionsValidator();
            var errors = validator.Validate(typedOptions).ToList();

            if (errors.Count > 0)
            {
                foreach (var error in errors)
                {
                    context.Logger.LogWarning("Plugin options validation: {Error}", error);
                }
            }

            resolvedOptions = typedOptions;
        }

        context.Logger.LogInformation(
            "JsonReaderPlugin initialised: MaxExplosionDepth={Depth} RootArrayKey='{Key}'",
            resolvedOptions.MaxExplosionDepth,
            resolvedOptions.RootArrayKey ?? "(auto-detect)");

        return Task.CompletedTask;
    }

    /// <summary>
    /// Shuts down this plugin. No resources to release for the JSON reader.
    /// </summary>
    /// <param name="cancellationToken">A token to cancel shutdown.</param>
    public Task ShutdownAsync(CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }

    /// <summary>
    /// Creates a typed logger from the service provider, or a null logger if unavailable.
    /// </summary>
    /// <typeparam name="T">The category type for the logger.</typeparam>
    /// <param name="services">The service provider to resolve from.</param>
    /// <returns>An <see cref="ILogger{T}"/> instance.</returns>
    private static ILogger<T> GetLogger<T>(IServiceProvider services)
    {
        return (ILogger<T>?)services.GetService(typeof(ILogger<T>))
            ?? Microsoft.Extensions.Logging.Abstractions.NullLogger<T>.Instance;
    }
}