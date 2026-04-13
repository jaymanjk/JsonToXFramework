// <copyright file="PluginCompatibility.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Plugin;

/// <summary>
/// Represents the result of a plugin framework version compatibility check.
/// Produced by the plugin compatibility checker before a plugin is registered.
/// </summary>
public sealed class PluginCompatibility
{
    /// <summary>
    /// Gets or sets a value indicating whether the plugin is compatible
    /// with the running Axbus framework version.
    /// </summary>
    public bool IsCompatible { get; set; }

    /// <summary>
    /// Gets or sets a human-readable explanation of why the plugin is
    /// incompatible. <c>null</c> when <see cref="IsCompatible"/> is <c>true</c>.
    /// </summary>
    public string? Reason { get; set; }

    /// <summary>Gets a pre-built instance representing a compatible result.</summary>
    public static PluginCompatibility Compatible { get; } = new() { IsCompatible = true };

    /// <summary>
    /// Creates an incompatible <see cref="PluginCompatibility"/> result with a reason.
    /// </summary>
    /// <param name="reason">A description of why the plugin is incompatible.</param>
    /// <returns>A new <see cref="PluginCompatibility"/> with <see cref="IsCompatible"/> set to <c>false</c>.</returns>
    public static PluginCompatibility Incompatible(string reason) =>
        new() { IsCompatible = false, Reason = reason };
}