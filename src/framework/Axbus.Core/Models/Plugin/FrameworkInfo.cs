// <copyright file="FrameworkInfo.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Models.Plugin;

/// <summary>
/// Provides information about the running Axbus framework version.
/// Passed to plugins via <see cref="Axbus.Core.Abstractions.Plugin.IPluginContext"/>
/// during initialisation so that plugins can perform their own
/// version compatibility checks.
/// </summary>
/// <param name="Version">The semantic version of the running Axbus framework.</param>
/// <param name="Environment">
/// The name of the hosting environment, for example <c>Development</c>,
/// <c>Staging</c> or <c>Production</c>.
/// </param>
public sealed record FrameworkInfo(Version Version, string Environment);