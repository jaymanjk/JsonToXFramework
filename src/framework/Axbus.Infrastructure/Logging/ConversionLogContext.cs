// <copyright file="ConversionLogContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.Logging;

using Serilog.Context;

/// <summary>
/// Enriches Serilog log events with Axbus-specific contextual properties.
/// Push properties onto the log context before executing a conversion module
/// or pipeline stage so that all log messages within that scope automatically
/// include the relevant context. Use the returned <see cref="IDisposable"/>
/// in a <c>using</c> block to automatically pop the properties when the scope exits.
/// </summary>
public static class ConversionLogContext
{
    /// <summary>
    /// Pushes the <paramref name="moduleName"/> property onto the Serilog log context.
    /// All log messages emitted within the returned scope will include the
    /// <c>ConversionModule</c> property, making module-level filtering possible
    /// in log analysis tools.
    /// </summary>
    /// <param name="moduleName">The name of the conversion module being executed.</param>
    /// <returns>
    /// An <see cref="IDisposable"/> that removes the property when disposed.
    /// Use in a <c>using</c> statement to scope the enrichment to the module execution.
    /// </returns>
    public static IDisposable PushModule(string moduleName)
    {
        return LogContext.PushProperty("ConversionModule", moduleName);
    }

    /// <summary>
    /// Pushes both <paramref name="moduleName"/> and <paramref name="pluginId"/>
    /// properties onto the Serilog log context. All log messages within the
    /// returned scope will include both <c>ConversionModule</c> and <c>PluginId</c>
    /// properties for detailed pipeline stage tracing.
    /// </summary>
    /// <param name="moduleName">The name of the conversion module being executed.</param>
    /// <param name="pluginId">The identifier of the plugin executing the current stage.</param>
    /// <returns>
    /// An <see cref="IDisposable"/> that removes both properties when disposed.
    /// </returns>
    public static IDisposable PushModuleAndPlugin(string moduleName, string pluginId)
    {
        // Push both properties - each returns a disposable
        // Combine them into a composite disposable via a simple wrapper
        var moduleDisposable = LogContext.PushProperty("ConversionModule", moduleName);
        var pluginDisposable = LogContext.PushProperty("PluginId", pluginId);

        return new CompositeDisposable(moduleDisposable, pluginDisposable);
    }

    /// <summary>
    /// Combines multiple <see cref="IDisposable"/> instances into one.
    /// Disposes all contained disposables when <see cref="Dispose"/> is called.
    /// </summary>
    private sealed class CompositeDisposable : IDisposable
    {
        /// <summary>
        /// The disposables to combine and dispose together.
        /// </summary>
        private readonly IDisposable[] disposables;

        /// <summary>
        /// Initializes a new instance of <see cref="CompositeDisposable"/>.
        /// </summary>
        /// <param name="disposables">The disposables to combine.</param>
        public CompositeDisposable(params IDisposable[] disposables)
        {
            this.disposables = disposables;
        }

        /// <summary>
        /// Disposes all contained disposables in reverse order.
        /// </summary>
        public void Dispose()
        {
            // Dispose in reverse order to mirror push/pop semantics
            for (var i = disposables.Length - 1; i >= 0; i--)
            {
                disposables[i].Dispose();
            }
        }
    }
}