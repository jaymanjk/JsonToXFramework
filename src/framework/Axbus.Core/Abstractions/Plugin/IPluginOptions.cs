// <copyright file="IPluginOptions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Marker interface for plugin-specific options classes.
/// Each plugin declares a strongly-typed options class that implements
/// this interface. The framework deserialises the <c>PluginOptions</c>
/// section from the conversion module configuration into the plugin's
/// declared options type using
/// <see cref="Axbus.Core.Abstractions.Factories.IPluginOptionsFactory"/>.
/// Unknown configuration keys are captured in the overflow dictionary
/// using <c>[JsonExtensionData]</c>.
/// </summary>
public interface IPluginOptions
{
}