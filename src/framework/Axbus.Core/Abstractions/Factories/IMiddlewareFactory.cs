// <copyright file="IMiddlewareFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Abstractions.Factories;

using Axbus.Core.Abstractions.Middleware;

/// <summary>
/// Resolves and orders the middleware components to be applied to each
/// pipeline stage execution. The default chain always includes logging,
/// timing and error handling middleware. Retry middleware is included
/// when configured.
/// </summary>
public interface IMiddlewareFactory
{
    /// <summary>
    /// Creates the ordered list of <see cref="IPipelineMiddleware"/> components
    /// to apply to pipeline stage executions.
    /// Components are applied in list order: the first component in the list
    /// is the outermost wrapper.
    /// </summary>
    /// <returns>
    /// An ordered list of <see cref="IPipelineMiddleware"/> instances.
    /// </returns>
    IReadOnlyList<IPipelineMiddleware> Create();
}