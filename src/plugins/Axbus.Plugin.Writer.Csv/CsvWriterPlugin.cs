// <copyright file="CsvWriterPlugin.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv;

using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Plugin.Writer.Csv.Internal;
using Axbus.Plugin.Writer.Csv.Options;
using Axbus.Plugin.Writer.Csv.Validators;
using Axbus.Plugin.Writer.Csv.Writer;
using Microsoft.Extensions.Logging;

/// <summary>
/// The entry-point <see cref="IPlugin"/> implementation for the
/// <c>Axbus.Plugin.Writer.Csv</c> plugin. This plugin handles the Write
/// pipeline stage for CSV output. It does not implement Read, Parse or
/// Transform stages (<see cref="CreateReader"/>, <see cref="CreateParser"/>
/// and <see cref="CreateTransformer"/> all return null).
/// Register this plugin by adding <c>Axbus.Plugin.Writer.Csv</c> to the
/// <c>PluginSettings.Plugins</c> list in <c>appsettings.json</c>.
/// </summary>
public sealed class CsvWriterPlugin : IPlugin
{
    /// <summary>Gets the unique reverse-domain identifier of this plugin.</summary>
    public string PluginId => "axbus.plugin.writer.csv";

    /// <summary>Gets the display name of this plugin.</summary>
    public string Name => "CsvWriter";

    /// <summary>Gets the semantic version of this plugin.</summary>
    public Version Version => new(1, 0, 0);

    /// <summary>Gets the minimum Axbus framework version required by this plugin.</summary>
    public Version MinFrameworkVersion => new(1, 0, 0);

    /// <summary>
    /// Gets the pipeline capabilities supported by this plugin.
    /// Supports the Write stage only.
    /// </summary>
    public PluginCapabilities Capabilities => PluginCapabilities.Writer;

    /// <summary>
    /// The options resolved during <see cref="InitializeAsync"/>.
    /// </summary>
    private CsvWriterPluginOptions resolvedOptions = new();

    /// <summary>This plugin does not support the Read stage.</summary>
    public ISourceReader? CreateReader(IServiceProvider services) => null;

    /// <summary>This plugin does not support the Parse stage.</summary>
    public IFormatParser? CreateParser(IServiceProvider services) => null;

    /// <summary>This plugin does not support the Transform stage.</summary>
    public IDataTransformer? CreateTransformer(IServiceProvider services) => null;

    /// <summary>
    /// Creates the <see cref="IOutputWriter"/> for this plugin.
    /// Returns a <see cref="CsvOutputWriter"/> that also implements
    /// <see cref="ISchemaAwareWriter"/>.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>A new <see cref="CsvOutputWriter"/> instance.</returns>
    public IOutputWriter? CreateWriter(IServiceProvider services)
    {
        var writerLogger = GetLogger<CsvOutputWriter>(services);
        var schemaLogger = GetLogger<CsvSchemaBuilder>(services);
        var schemaBuilder = new CsvSchemaBuilder(schemaLogger);
        return new CsvOutputWriter(writerLogger, resolvedOptions, schemaBuilder);
    }

    /// <summary>
    /// Initializes this plugin by validating and storing options.
    /// </summary>
    /// <param name="context">The plugin context providing options and logger.</param>
    /// <param name="cancellationToken">A token to cancel initialisation.</param>
    public Task InitializeAsync(IPluginContext context, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(context);

        context.Logger.LogInformation(
            "CsvWriterPlugin initialising: {PluginId} v{Version}",
            PluginId,
            Version);

        if (context.Options is CsvWriterPluginOptions typedOptions)
        {
            var validator = new CsvWriterOptionsValidator();
            var errors = validator.Validate(typedOptions).ToList();

            foreach (var error in errors)
            {
                context.Logger.LogWarning("Plugin options validation: {Error}", error);
            }

            resolvedOptions = typedOptions;
        }

        context.Logger.LogInformation(
            "CsvWriterPlugin initialised: Delimiter='{Delimiter}' Encoding={Encoding} Header={Header}",
            resolvedOptions.Delimiter,
            resolvedOptions.Encoding,
            resolvedOptions.IncludeHeader);

        return Task.CompletedTask;
    }

    /// <summary>Shuts down this plugin. No resources to release.</summary>
    public Task ShutdownAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    /// <summary>Resolves a typed logger from the service provider.</summary>
    private static ILogger<T> GetLogger<T>(IServiceProvider services) =>
        (ILogger<T>?)services.GetService(typeof(ILogger<T>))
        ?? Microsoft.Extensions.Logging.Abstractions.NullLogger<T>.Instance;
}