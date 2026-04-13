// <copyright file="IPluginOptionsValidator.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Plugin;

/// <summary>
/// Validates plugin-specific options before the plugin is initialised.
/// Each plugin should provide an implementation that checks for required
/// fields, valid value ranges and internally consistent configurations.
/// The framework validates options at startup after deserialisation.
/// </summary>
public interface IPluginOptionsValidator
{
    /// <summary>
    /// Validates the specified plugin options instance.
    /// </summary>
    /// <param name="options">The options instance to validate.</param>
    /// <returns>
    /// An empty enumerable when options are valid, or one or more
    /// validation error messages when options are invalid.
    /// </returns>
    IEnumerable<string> Validate(IPluginOptions options);
}