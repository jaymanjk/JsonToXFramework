// <copyright file="PluginCapabilities.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Enums;

/// <summary>
/// Describes which pipeline stages a plugin supports.
/// This is a flags enumeration allowing a plugin to declare support
/// for multiple stages simultaneously.
/// A plugin that supports all stages can use the convenience value
/// <see cref="Bundled"/>.
/// </summary>
[Flags]
public enum PluginCapabilities
{
    /// <summary>The plugin supports no pipeline stages.</summary>
    None = 0,

    /// <summary>
    /// The plugin implements <see cref="Axbus.Core.Abstractions.Pipeline.ISourceReader"/>
    /// and can read raw data from a source connector.
    /// </summary>
    Reader = 1,

    /// <summary>
    /// The plugin implements <see cref="Axbus.Core.Abstractions.Pipeline.IFormatParser"/>
    /// and can parse a raw stream into an internal element model.
    /// </summary>
    Parser = 2,

    /// <summary>
    /// The plugin implements <see cref="Axbus.Core.Abstractions.Pipeline.IDataTransformer"/>
    /// and can flatten and transform parsed elements into rows.
    /// </summary>
    Transformer = 4,

    /// <summary>
    /// The plugin implements <see cref="Axbus.Core.Abstractions.Pipeline.IOutputWriter"/>
    /// and can write rows to a target connector.
    /// </summary>
    Writer = 8,

    /// <summary>
    /// The plugin implements <see cref="Axbus.Core.Abstractions.Pipeline.IDataValidator"/>
    /// and can validate rows before writing.
    /// </summary>
    Validator = 16,

    /// <summary>
    /// The plugin implements <see cref="Axbus.Core.Abstractions.Pipeline.IDataFilter"/>
    /// and can filter rows based on configured rules.
    /// </summary>
    Filter = 32,

    /// <summary>
    /// Convenience value indicating the plugin supports all core pipeline stages:
    /// <see cref="Reader"/>, <see cref="Parser"/>, <see cref="Transformer"/> and <see cref="Writer"/>.
    /// </summary>
    Bundled = Reader | Parser | Transformer | Writer,
}