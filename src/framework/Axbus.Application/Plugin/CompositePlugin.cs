// <copyright file="CompositePlugin.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;

/// <summary>
/// Combines a dedicated reader plugin and a dedicated writer plugin into a single
/// <see cref="IPlugin"/> implementation. The Read, Parse and Transform pipeline
/// stages are delegated to the <paramref name="readerPlugin"/>, while the Write
/// stage is delegated to the <paramref name="writerPlugin"/>. This allows the
/// framework's single-plugin pipeline model to work with the architecture's
/// separated reader and writer plugin assemblies.
/// </summary>
internal sealed class CompositePlugin : IPlugin
{
    /// <summary>
    /// The plugin that handles the Read, Parse and Transform stages.
    /// </summary>
    private readonly IPlugin readerPlugin;

    /// <summary>
    /// The plugin that handles the Write stage.
    /// </summary>
    private readonly IPlugin writerPlugin;

    /// <summary>
    /// Initializes a new instance of <see cref="CompositePlugin"/>.
    /// </summary>
    /// <param name="readerPlugin">The plugin providing Read, Parse and Transform stages.</param>
    /// <param name="writerPlugin">The plugin providing the Write stage.</param>
    public CompositePlugin(IPlugin readerPlugin, IPlugin writerPlugin)
    {
        this.readerPlugin = readerPlugin;
        this.writerPlugin = writerPlugin;
    }

    /// <summary>Gets the plugin identifier from the writer plugin (represents the full format pair).</summary>
    public string PluginId => writerPlugin.PluginId;

    /// <summary>Gets a combined display name from both constituent plugins.</summary>
    public string Name => $"{readerPlugin.Name}+{writerPlugin.Name}";

    /// <summary>Gets the version from the writer plugin.</summary>
    public Version Version => writerPlugin.Version;

    /// <summary>
    /// Gets the minimum framework version required, taking the higher of the two plugins.
    /// </summary>
    public Version MinFrameworkVersion =>
        readerPlugin.MinFrameworkVersion >= writerPlugin.MinFrameworkVersion
            ? readerPlugin.MinFrameworkVersion
            : writerPlugin.MinFrameworkVersion;

    /// <summary>Gets the combined capabilities of both constituent plugins.</summary>
    public PluginCapabilities Capabilities => readerPlugin.Capabilities | writerPlugin.Capabilities;

    /// <summary>
    /// Creates the <see cref="ISourceReader"/> by delegating to the reader plugin.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>The reader plugin's <see cref="ISourceReader"/> instance.</returns>
    public ISourceReader? CreateReader(IServiceProvider services) =>
        readerPlugin.CreateReader(services);

    /// <summary>
    /// Creates the <see cref="IFormatParser"/> by delegating to the reader plugin.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>The reader plugin's <see cref="IFormatParser"/> instance.</returns>
    public IFormatParser? CreateParser(IServiceProvider services) =>
        readerPlugin.CreateParser(services);

    /// <summary>
    /// Creates the <see cref="IDataTransformer"/> by delegating to the reader plugin.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>The reader plugin's <see cref="IDataTransformer"/> instance.</returns>
    public IDataTransformer? CreateTransformer(IServiceProvider services) =>
        readerPlugin.CreateTransformer(services);

    /// <summary>
    /// Creates the <see cref="IOutputWriter"/> by delegating to the writer plugin.
    /// </summary>
    /// <param name="services">The service provider for dependency resolution.</param>
    /// <returns>The writer plugin's <see cref="IOutputWriter"/> instance.</returns>
    public IOutputWriter? CreateWriter(IServiceProvider services) =>
        writerPlugin.CreateWriter(services);

    /// <summary>
    /// Initializes both constituent plugins with the supplied context.
    /// </summary>
    /// <param name="context">The plugin context providing options and metadata.</param>
    /// <param name="cancellationToken">A token to cancel initialization.</param>
    public async Task InitializeAsync(IPluginContext context, CancellationToken cancellationToken)
    {
        await readerPlugin.InitializeAsync(context, cancellationToken).ConfigureAwait(false);
        await writerPlugin.InitializeAsync(context, cancellationToken).ConfigureAwait(false);
    }

    /// <summary>
    /// Shuts down both constituent plugins.
    /// </summary>
    /// <param name="cancellationToken">A token to cancel shutdown.</param>
    public async Task ShutdownAsync(CancellationToken cancellationToken)
    {
        await readerPlugin.ShutdownAsync(cancellationToken).ConfigureAwait(false);
        await writerPlugin.ShutdownAsync(cancellationToken).ConfigureAwait(false);
    }
}
