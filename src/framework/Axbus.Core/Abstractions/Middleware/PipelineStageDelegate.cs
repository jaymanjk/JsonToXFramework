// <copyright file="PipelineStageDelegate.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Middleware;

using Axbus.Core.Models.Pipeline;

/// <summary>
/// Represents the next action in the middleware pipeline chain.
/// Each <see cref="IPipelineMiddleware"/> implementation invokes this delegate
/// to pass control to the next middleware in the chain or, for the last middleware,
/// to the actual pipeline stage implementation.
/// This pattern mirrors the ASP.NET Core middleware pipeline design.
/// </summary>
/// <returns>
/// A task returning a <see cref="PipelineStageResult"/> from the next middleware or stage.
/// </returns>
public delegate Task<PipelineStageResult> PipelineStageDelegate();