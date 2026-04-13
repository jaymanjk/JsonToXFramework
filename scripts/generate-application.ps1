# ==============================================================================
# generate-application.ps1
# Axbus Framework - Axbus.Application Layer Code Generation Script
# Copyright (c) 2026 Axel Johnson International. All rights reserved.
#
# USAGE:
#   PowerShell -ExecutionPolicy Bypass -File .\scripts\generate-application.ps1
#
# PREREQUISITES:
#   - Run generate-core.ps1 first (Axbus.Core must exist)
#   - Run from the repository root
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptVersion = "1.0.0"
$CompanyName   = "Axel Johnson International"
$CopyrightYear = "2026"
$RootPath      = "src/framework/Axbus.Application"

function Write-Banner {
    Write-Host ""
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host "  Axbus.Application - Code Generation Script v$ScriptVersion" -ForegroundColor Cyan
    Write-Host "  Copyright (c) $CopyrightYear $CompanyName. All rights reserved." -ForegroundColor Cyan
    Write-Host "===============================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Phase {
    param([string]$Message)
    Write-Host ""
    Write-Host "  >> $Message" -ForegroundColor Yellow
    Write-Host "  $("-" * 70)" -ForegroundColor Yellow
}

function Write-Ok   { param([string]$m) Write-Host "      [OK] $m" -ForegroundColor Green }
function Write-Info { param([string]$m) Write-Host "      [..] $m" -ForegroundColor White }

function New-SourceFile {
    param([string]$RelativePath, [string]$Content)
    $fullPath  = Join-Path $RootPath $RelativePath
    $directory = Split-Path $fullPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    [System.IO.File]::WriteAllText(
        [System.IO.Path]::GetFullPath($fullPath),
        $Content,
        [System.Text.UTF8Encoding]::new($false)
    )
    Write-Ok $RelativePath
}

if (-not (Test-Path ".git")) {
    Write-Host "  [FAILED] Run from repository root." -ForegroundColor Red; exit 1
}
if (-not (Test-Path $RootPath)) {
    Write-Host "  [FAILED] $RootPath not found. Run setup-axbus.ps1 first." -ForegroundColor Red; exit 1
}
if (-not (Test-Path "src/framework/Axbus.Core/Axbus.Core.csproj")) {
    Write-Host "  [FAILED] Axbus.Core not found. Run generate-core.ps1 first." -ForegroundColor Red; exit 1
}

Write-Banner

# ==============================================================================
# PHASE 1 - MIDDLEWARE
# ==============================================================================

Write-Phase "Phase 1 - Middleware (6 files)"

New-SourceFile "Middleware/PipelineMiddlewareContext.cs" @'
// <copyright file="PipelineMiddlewareContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Middleware;

using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Enums;

/// <summary>
/// Concrete implementation of <see cref="IPipelineMiddlewareContext"/>.
/// Carries contextual information about the pipeline stage being executed
/// through the middleware chain. Created by the pipeline stage executor
/// before invoking the middleware chain.
/// </summary>
public sealed class PipelineMiddlewareContext : IPipelineMiddlewareContext
{
    /// <summary>
    /// Gets the name of the conversion module being executed.
    /// </summary>
    public string ModuleName { get; }

    /// <summary>
    /// Gets the identifier of the plugin executing this stage.
    /// </summary>
    public string PluginId { get; }

    /// <summary>
    /// Gets the pipeline stage being executed.
    /// </summary>
    public PipelineStage Stage { get; }

    /// <summary>
    /// Gets additional properties associated with this stage execution.
    /// </summary>
    public IReadOnlyDictionary<string, object> Properties { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="PipelineMiddlewareContext"/>.
    /// </summary>
    /// <param name="moduleName">The name of the conversion module being executed.</param>
    /// <param name="pluginId">The identifier of the plugin executing this stage.</param>
    /// <param name="stage">The pipeline stage being executed.</param>
    /// <param name="properties">Additional contextual properties, or null for an empty dictionary.</param>
    public PipelineMiddlewareContext(
        string moduleName,
        string pluginId,
        PipelineStage stage,
        Dictionary<string, object>? properties = null)
    {
        ModuleName = moduleName;
        PluginId = pluginId;
        Stage = stage;
        Properties = properties ?? new Dictionary<string, object>();
    }
}
'@

New-SourceFile "Middleware/MiddlewarePipelineBuilder.cs" @'
// <copyright file="MiddlewarePipelineBuilder.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Middleware;

using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Builds and executes the ordered middleware chain for a single pipeline stage.
/// Middleware components are applied in list order so that the first component
/// is the outermost wrapper. The innermost invocation calls the actual stage delegate.
/// This mirrors the ASP.NET Core middleware pipeline design.
/// </summary>
public sealed class MiddlewarePipelineBuilder
{
    /// <summary>
    /// The ordered list of middleware components to apply.
    /// </summary>
    private readonly IReadOnlyList<IPipelineMiddleware> middleware;

    /// <summary>
    /// Initializes a new instance of <see cref="MiddlewarePipelineBuilder"/>
    /// with the specified ordered middleware components.
    /// </summary>
    /// <param name="middleware">The ordered list of middleware components to apply.</param>
    public MiddlewarePipelineBuilder(IReadOnlyList<IPipelineMiddleware> middleware)
    {
        ArgumentNullException.ThrowIfNull(middleware);
        this.middleware = middleware;
    }

    /// <summary>
    /// Executes the middleware chain with the specified context and innermost stage action.
    /// Each middleware component wraps the next, with <paramref name="stageAction"/>
    /// at the innermost position.
    /// </summary>
    /// <param name="context">The middleware context for the current stage execution.</param>
    /// <param name="stageAction">The actual pipeline stage logic to invoke at the innermost position.</param>
    /// <returns>A <see cref="PipelineStageResult"/> from the innermost stage or an intercepting middleware.</returns>
    public async Task<PipelineStageResult> ExecuteAsync(
        IPipelineMiddlewareContext context,
        Func<Task<PipelineStageResult>> stageAction)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(stageAction);

        // Build the chain from the inside out
        // so that middleware[0] is the outermost wrapper
        PipelineStageDelegate chain = () => stageAction();

        for (var i = middleware.Count - 1; i >= 0; i--)
        {
            // Capture current values for the closure
            var current = middleware[i];
            var next = chain;
            chain = () => current.InvokeAsync(context, next);
        }

        return await chain().ConfigureAwait(false);
    }
}
'@

New-SourceFile "Middleware/LoggingMiddleware.cs" @'
// <copyright file="LoggingMiddleware.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Middleware;

using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Pipeline middleware that logs the entry and exit of each pipeline stage.
/// Logs the module name, plugin identifier, stage name and whether the stage
/// succeeded or failed. Should be placed first in the middleware chain so
/// that it wraps all other middleware.
/// </summary>
public sealed class LoggingMiddleware : IPipelineMiddleware
{
    /// <summary>
    /// Logger instance for structured diagnostic output.
    /// </summary>
    private readonly ILogger<LoggingMiddleware> logger;

    /// <summary>
    /// Initializes a new instance of <see cref="LoggingMiddleware"/>.
    /// </summary>
    /// <param name="logger">The logger used for structured stage entry and exit messages.</param>
    public LoggingMiddleware(ILogger<LoggingMiddleware> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Logs stage entry, invokes the next middleware, then logs stage exit with duration.
    /// </summary>
    /// <param name="context">Contextual information about the stage being executed.</param>
    /// <param name="next">The next middleware or stage delegate in the chain.</param>
    /// <returns>The result from the next middleware or stage.</returns>
    public async Task<PipelineStageResult> InvokeAsync(
        IPipelineMiddlewareContext context,
        PipelineStageDelegate next)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(next);

        logger.LogDebug(
            "Stage starting: {Stage} | Module: {ModuleName} | Plugin: {PluginId}",
            context.Stage,
            context.ModuleName,
            context.PluginId);

        var result = await next().ConfigureAwait(false);

        if (result.Success)
        {
            logger.LogDebug(
                "Stage completed: {Stage} | Module: {ModuleName} | Duration: {Duration}ms",
                context.Stage,
                context.ModuleName,
                result.Duration.TotalMilliseconds);
        }
        else
        {
            logger.LogWarning(
                "Stage failed: {Stage} | Module: {ModuleName} | Error: {Error}",
                context.Stage,
                context.ModuleName,
                result.Exception?.Message ?? "Unknown error");
        }

        return result;
    }
}
'@

New-SourceFile "Middleware/TimingMiddleware.cs" @'
// <copyright file="TimingMiddleware.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Middleware;

using System.Diagnostics;
using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Pipeline middleware that measures the elapsed time of each pipeline stage.
/// Sets <see cref="PipelineStageResult.Duration"/> on the result so that
/// downstream middleware and the conversion runner have accurate timing data.
/// Should be placed after <see cref="LoggingMiddleware"/> in the middleware chain.
/// </summary>
public sealed class TimingMiddleware : IPipelineMiddleware
{
    /// <summary>
    /// Starts a stopwatch, invokes the next middleware, then records the elapsed time
    /// in the returned <see cref="PipelineStageResult.Duration"/>.
    /// </summary>
    /// <param name="context">Contextual information about the stage being executed.</param>
    /// <param name="next">The next middleware or stage delegate in the chain.</param>
    /// <returns>The result from the next middleware with <see cref="PipelineStageResult.Duration"/> set.</returns>
    public async Task<PipelineStageResult> InvokeAsync(
        IPipelineMiddlewareContext context,
        PipelineStageDelegate next)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(next);

        // Start timing before invoking the next stage in the chain
        var stopwatch = Stopwatch.StartNew();

        var result = await next().ConfigureAwait(false);

        stopwatch.Stop();

        // Record duration on the result for upstream middleware and runners
        result.Duration = stopwatch.Elapsed;

        return result;
    }
}
'@

New-SourceFile "Middleware/RetryMiddleware.cs" @'
// <copyright file="RetryMiddleware.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Middleware;

using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Pipeline middleware that retries a failed pipeline stage up to a configured
/// maximum number of attempts with an exponential backoff delay between attempts.
/// Does not retry when the failure is an <see cref="OperationCanceledException"/>.
/// </summary>
public sealed class RetryMiddleware : IPipelineMiddleware
{
    /// <summary>
    /// Logger instance for retry attempt diagnostic messages.
    /// </summary>
    private readonly ILogger<RetryMiddleware> logger;

    /// <summary>
    /// The maximum number of retry attempts after the initial failure.
    /// </summary>
    private readonly int maxRetries;

    /// <summary>
    /// The base delay between retry attempts. Doubled on each subsequent attempt.
    /// </summary>
    private readonly TimeSpan baseDelay;

    /// <summary>
    /// Initializes a new instance of <see cref="RetryMiddleware"/>.
    /// </summary>
    /// <param name="logger">The logger used for retry attempt messages.</param>
    /// <param name="maxRetries">Maximum number of retry attempts after the first failure. Defaults to 3.</param>
    /// <param name="baseDelayMs">Base delay in milliseconds between retries. Defaults to 500ms.</param>
    public RetryMiddleware(ILogger<RetryMiddleware> logger, int maxRetries = 3, int baseDelayMs = 500)
    {
        this.logger = logger;
        this.maxRetries = maxRetries;
        this.baseDelay = TimeSpan.FromMilliseconds(baseDelayMs);
    }

    /// <summary>
    /// Invokes the next middleware and retries up to <see cref="maxRetries"/> times
    /// on failure, using exponential backoff between attempts.
    /// </summary>
    /// <param name="context">Contextual information about the stage being executed.</param>
    /// <param name="next">The next middleware or stage delegate in the chain.</param>
    /// <returns>The result from the first successful invocation, or the final failure result.</returns>
    public async Task<PipelineStageResult> InvokeAsync(
        IPipelineMiddlewareContext context,
        PipelineStageDelegate next)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(next);

        var attempt = 0;

        while (true)
        {
            var result = await next().ConfigureAwait(false);

            // Return immediately on success or cancellation
            if (result.Success || result.Exception is OperationCanceledException)
            {
                return result;
            }

            attempt++;

            if (attempt > maxRetries)
            {
                // All retries exhausted - return the final failure result
                logger.LogError(
                    "Stage {Stage} failed after {Attempts} attempt(s) for module {ModuleName}",
                    context.Stage,
                    attempt,
                    context.ModuleName);
                return result;
            }

            // Calculate exponential backoff delay: baseDelay * 2^(attempt-1)
            var delay = TimeSpan.FromMilliseconds(baseDelay.TotalMilliseconds * Math.Pow(2, attempt - 1));

            logger.LogWarning(
                "Stage {Stage} failed for module {ModuleName}. Retrying attempt {Attempt}/{MaxRetries} in {DelayMs}ms",
                context.Stage,
                context.ModuleName,
                attempt,
                maxRetries,
                delay.TotalMilliseconds);

            await Task.Delay(delay).ConfigureAwait(false);
        }
    }
}
'@

New-SourceFile "Middleware/ErrorHandlingMiddleware.cs" @'
// <copyright file="ErrorHandlingMiddleware.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Middleware;

using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Pipeline middleware that catches unhandled exceptions from stage execution
/// and applies the configured <see cref="RowErrorStrategy"/>.
/// Wraps exceptions in <see cref="AxbusPipelineException"/> with stage context
/// and logs them appropriately before returning a failed <see cref="PipelineStageResult"/>.
/// </summary>
public sealed class ErrorHandlingMiddleware : IPipelineMiddleware
{
    /// <summary>
    /// Logger instance for structured error diagnostic output.
    /// </summary>
    private readonly ILogger<ErrorHandlingMiddleware> logger;

    /// <summary>
    /// The pipeline options containing the configured row error strategy.
    /// </summary>
    private readonly PipelineOptions pipelineOptions;

    /// <summary>
    /// Initializes a new instance of <see cref="ErrorHandlingMiddleware"/>.
    /// </summary>
    /// <param name="logger">The logger used for error messages.</param>
    /// <param name="pipelineOptions">The pipeline options containing the row error strategy.</param>
    public ErrorHandlingMiddleware(ILogger<ErrorHandlingMiddleware> logger, PipelineOptions pipelineOptions)
    {
        this.logger = logger;
        this.pipelineOptions = pipelineOptions;
    }

    /// <summary>
    /// Invokes the next middleware and catches any exceptions, converting them
    /// into a failed <see cref="PipelineStageResult"/> with appropriate logging.
    /// </summary>
    /// <param name="context">Contextual information about the stage being executed.</param>
    /// <param name="next">The next middleware or stage delegate in the chain.</param>
    /// <returns>
    /// The result from the next middleware on success, or a failed result on exception.
    /// </returns>
    public async Task<PipelineStageResult> InvokeAsync(
        IPipelineMiddlewareContext context,
        PipelineStageDelegate next)
    {
        ArgumentNullException.ThrowIfNull(context);
        ArgumentNullException.ThrowIfNull(next);

        try
        {
            return await next().ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            // Always re-throw cancellation - do not treat as pipeline error
            throw;
        }
        catch (AxbusPipelineException ex)
        {
            // Domain exception - log and return failed result
            logger.LogError(
                ex,
                "Pipeline error in stage {Stage} for module {ModuleName}",
                context.Stage,
                context.ModuleName);

            return new PipelineStageResult
            {
                Success = false,
                Stage = context.Stage,
                Exception = ex,
            };
        }
        catch (Exception ex)
        {
            // Unexpected exception - wrap in domain exception and return failed result
            logger.LogError(
                ex,
                "Unexpected error in stage {Stage} for module {ModuleName}",
                context.Stage,
                context.ModuleName);

            var wrapped = new AxbusPipelineException(
                $"Unexpected failure in stage {context.Stage} for module '{context.ModuleName}'",
                context.Stage,
                ex);

            return new PipelineStageResult
            {
                Success = false,
                Stage = context.Stage,
                Exception = wrapped,
            };
        }
    }
}
'@

# ==============================================================================
# PHASE 2 - PIPELINE
# ==============================================================================

Write-Phase "Phase 2 - Pipeline (2 files)"

New-SourceFile "Pipeline/PipelineStageExecutor.cs" @'
// <copyright file="PipelineStageExecutor.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Pipeline;

using Axbus.Application.Middleware;
using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Enums;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Executes a single pipeline stage wrapped in the middleware chain.
/// Creates the <see cref="PipelineMiddlewareContext"/> for the stage,
/// builds the middleware chain via <see cref="MiddlewarePipelineBuilder"/>
/// and invokes the stage action. Used by <see cref="ConversionPipeline"/>
/// to execute each stage uniformly.
/// </summary>
public sealed class PipelineStageExecutor
{
    /// <summary>
    /// Logger instance for structured diagnostic output.
    /// </summary>
    private readonly ILogger<PipelineStageExecutor> logger;

    /// <summary>
    /// The ordered list of middleware components applied to each stage.
    /// </summary>
    private readonly IReadOnlyList<IPipelineMiddleware> middleware;

    /// <summary>
    /// Initializes a new instance of <see cref="PipelineStageExecutor"/>.
    /// </summary>
    /// <param name="logger">The logger for stage execution messages.</param>
    /// <param name="middleware">The ordered middleware components to apply to each stage.</param>
    public PipelineStageExecutor(
        ILogger<PipelineStageExecutor> logger,
        IReadOnlyList<IPipelineMiddleware> middleware)
    {
        this.logger = logger;
        this.middleware = middleware;
    }

    /// <summary>
    /// Executes <paramref name="stageAction"/> for the specified stage
    /// wrapped in the full middleware chain.
    /// </summary>
    /// <typeparam name="TResult">The type of the stage output object.</typeparam>
    /// <param name="moduleName">The name of the conversion module being executed.</param>
    /// <param name="pluginId">The identifier of the plugin executing this stage.</param>
    /// <param name="stage">The pipeline stage being executed.</param>
    /// <param name="stageAction">The actual stage logic to execute at the innermost position.</param>
    /// <param name="cancellationToken">A token to cancel the stage execution.</param>
    /// <returns>The output of type <typeparamref name="TResult"/> produced by the stage.</returns>
    /// <exception cref="Axbus.Core.Exceptions.AxbusPipelineException">
    /// Thrown when the stage fails and the error handling middleware determines it is unrecoverable.
    /// </exception>
    public async Task<TResult> ExecuteAsync<TResult>(
        string moduleName,
        string pluginId,
        PipelineStage stage,
        Func<Task<TResult>> stageAction,
        CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(moduleName);
        ArgumentNullException.ThrowIfNull(stageAction);

        // Create context for this stage execution
        var context = new PipelineMiddlewareContext(moduleName, pluginId, stage);

        // Build and execute the middleware chain
        var builder = new MiddlewarePipelineBuilder(middleware);

        var stageResult = await builder.ExecuteAsync(context, async () =>
        {
            try
            {
                var output = await stageAction().ConfigureAwait(false);
                return new PipelineStageResult
                {
                    Success = true,
                    Stage = stage,
                    Output = output,
                };
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                return new PipelineStageResult
                {
                    Success = false,
                    Stage = stage,
                    Exception = ex,
                };
            }
        }).ConfigureAwait(false);

        if (!stageResult.Success)
        {
            throw stageResult.Exception
                ?? new Axbus.Core.Exceptions.AxbusPipelineException(
                    $"Stage {stage} failed for module '{moduleName}'", stage);
        }

        return (TResult)stageResult.Output!;
    }
}
'@

New-SourceFile "Pipeline/ConversionPipeline.cs" @'
// <copyright file="ConversionPipeline.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Pipeline;

using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Microsoft.Extensions.Logging;

/// <summary>
/// Orchestrates the execution of all pipeline stages for a single source file.
/// Assembles the stage chain Read -> Parse -> Transform -> Write by resolving
/// the appropriate plugin implementations and executing each stage through
/// the middleware chain via <see cref="PipelineStageExecutor"/>.
/// One instance is created per conversion module execution.
/// </summary>
public sealed class ConversionPipeline : IConversionPipeline
{
    /// <summary>
    /// Logger instance for structured pipeline diagnostic output.
    /// </summary>
    private readonly ILogger<ConversionPipeline> logger;

    /// <summary>
    /// The plugin resolved for this pipeline execution.
    /// </summary>
    private readonly IPlugin plugin;

    /// <summary>
    /// The executor that wraps each stage in the middleware chain.
    /// </summary>
    private readonly PipelineStageExecutor stageExecutor;

    /// <summary>
    /// The service provider used to create plugin stage instances.
    /// </summary>
    private readonly IServiceProvider serviceProvider;

    /// <summary>
    /// Initializes a new instance of <see cref="ConversionPipeline"/>.
    /// </summary>
    /// <param name="logger">The logger for pipeline lifecycle messages.</param>
    /// <param name="plugin">The resolved plugin providing stage implementations.</param>
    /// <param name="stageExecutor">The executor that wraps stages in middleware.</param>
    /// <param name="serviceProvider">The service provider for plugin stage creation.</param>
    public ConversionPipeline(
        ILogger<ConversionPipeline> logger,
        IPlugin plugin,
        PipelineStageExecutor stageExecutor,
        IServiceProvider serviceProvider)
    {
        this.logger = logger;
        this.plugin = plugin;
        this.stageExecutor = stageExecutor;
        this.serviceProvider = serviceProvider;
    }

    /// <summary>
    /// Executes the full Read -> Parse -> Transform -> Write pipeline
    /// for the source file at <paramref name="sourcePath"/>.
    /// </summary>
    /// <param name="module">The conversion module configuration to use.</param>
    /// <param name="sourcePath">The full path or URI of the source file to process.</param>
    /// <param name="cancellationToken">A token to cancel the pipeline execution.</param>
    /// <returns>A <see cref="WriteResult"/> containing row counts and output paths.</returns>
    /// <exception cref="AxbusPipelineException">
    /// Thrown when a stage fails and cannot be handled by the configured error strategy.
    /// </exception>
    public async Task<WriteResult> ExecuteAsync(
        ConversionModule module,
        string sourcePath,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(module);
        ArgumentException.ThrowIfNullOrWhiteSpace(sourcePath);

        logger.LogInformation(
            "Pipeline starting for module {ModuleName} | File: {SourcePath}",
            module.ConversionName,
            sourcePath);

        // Stage 1: Read
        var reader = plugin.CreateReader(serviceProvider)
            ?? throw new AxbusPipelineException(
                $"Plugin '{plugin.PluginId}' does not support the Read stage.",
                PipelineStage.Read);

        var sourceData = await stageExecutor.ExecuteAsync(
            module.ConversionName,
            plugin.PluginId,
            PipelineStage.Read,
            () => reader.ReadAsync(module.Source, cancellationToken),
            cancellationToken).ConfigureAwait(false);

        // Stage 2: Parse
        var parser = plugin.CreateParser(serviceProvider)
            ?? throw new AxbusPipelineException(
                $"Plugin '{plugin.PluginId}' does not support the Parse stage.",
                PipelineStage.Parse);

        var parsedData = await stageExecutor.ExecuteAsync(
            module.ConversionName,
            plugin.PluginId,
            PipelineStage.Parse,
            () => parser.ParseAsync(sourceData, cancellationToken),
            cancellationToken).ConfigureAwait(false);

        // Stage 3: Transform
        var transformer = plugin.CreateTransformer(serviceProvider)
            ?? throw new AxbusPipelineException(
                $"Plugin '{plugin.PluginId}' does not support the Transform stage.",
                PipelineStage.Transform);

        var transformedData = await stageExecutor.ExecuteAsync(
            module.ConversionName,
            plugin.PluginId,
            PipelineStage.Transform,
            () => transformer.TransformAsync(parsedData, module.Pipeline, cancellationToken),
            cancellationToken).ConfigureAwait(false);

        // Stage 4: Write
        var writer = plugin.CreateWriter(serviceProvider)
            ?? throw new AxbusPipelineException(
                $"Plugin '{plugin.PluginId}' does not support the Write stage.",
                PipelineStage.Write);

        var writeResult = await stageExecutor.ExecuteAsync(
            module.ConversionName,
            plugin.PluginId,
            PipelineStage.Write,
            () => writer.WriteAsync(transformedData, module.Target, module.Pipeline, cancellationToken),
            cancellationToken).ConfigureAwait(false);

        logger.LogInformation(
            "Pipeline completed for module {ModuleName} | File: {SourcePath} | Rows: {RowsWritten}",
            module.ConversionName,
            sourcePath,
            writeResult.RowsWritten);

        return writeResult;
    }
}
'@

# ==============================================================================
# PHASE 3 - CONVERSION
# ==============================================================================

Write-Phase "Phase 3 - Conversion (2 files)"

New-SourceFile "Conversion/ConversionContext.cs" @'
// <copyright file="ConversionContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Conversion;

using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Concrete implementation of <see cref="IConversionContext"/>.
/// Carries accumulated stage outputs through the conversion pipeline
/// for a single source file within a module execution.
/// Created by the conversion runner before each file is processed
/// and discarded after the pipeline completes.
/// </summary>
public sealed class ConversionContext : IConversionContext
{
    /// <summary>
    /// Gets the conversion module configuration for this execution.
    /// </summary>
    public ConversionModule Module { get; }

    /// <summary>
    /// Gets or sets the output of Stage 1 (Read). Set after Read completes.
    /// </summary>
    public SourceData? SourceData { get; set; }

    /// <summary>
    /// Gets or sets the output of Stage 2 (Parse). Set after Parse completes.
    /// </summary>
    public ParsedData? ParsedData { get; set; }

    /// <summary>
    /// Gets or sets the output of Stage 3 (Transform). Set after Transform completes.
    /// </summary>
    public TransformedData? TransformedData { get; set; }

    /// <summary>
    /// Gets or sets the output of Stage 4 (Write). Set after Write completes.
    /// </summary>
    public WriteResult? WriteResult { get; set; }

    /// <summary>
    /// Gets the path of the source file currently being processed.
    /// </summary>
    public string CurrentSourcePath { get; }

    /// <summary>
    /// Gets or sets a value indicating whether processing of this source file has been cancelled.
    /// </summary>
    public bool IsCancelled { get; set; }

    /// <summary>
    /// Initializes a new instance of <see cref="ConversionContext"/>.
    /// </summary>
    /// <param name="module">The conversion module configuration for this execution.</param>
    /// <param name="currentSourcePath">The path of the source file being processed.</param>
    public ConversionContext(ConversionModule module, string currentSourcePath)
    {
        ArgumentNullException.ThrowIfNull(module);
        ArgumentException.ThrowIfNullOrWhiteSpace(currentSourcePath);

        Module = module;
        CurrentSourcePath = currentSourcePath;
    }
}
'@

New-SourceFile "Conversion/ConversionRunner.cs" @'
// <copyright file="ConversionRunner.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Conversion;

using System.Diagnostics;
using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Abstractions.Factories;
using Axbus.Core.Abstractions.Notifications;
using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Notifications;
using Axbus.Core.Models.Pipeline;
using Axbus.Core.Models.Results;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

/// <summary>
/// Orchestrates the execution of all enabled conversion modules defined in
/// <see cref="AxbusRootSettings.ConversionModules"/>. Handles sequential and
/// parallel execution, progress reporting, event publishing and result aggregation.
/// This is the primary entry point called by both the ConsoleApp and WinFormsApp.
/// </summary>
public sealed class ConversionRunner : IConversionRunner
{
    /// <summary>
    /// Logger instance for structured runner lifecycle messages.
    /// </summary>
    private readonly ILogger<ConversionRunner> logger;

    /// <summary>
    /// Factory for creating conversion pipelines per module.
    /// </summary>
    private readonly IPipelineFactory pipelineFactory;

    /// <summary>
    /// Publisher for lifecycle event notifications.
    /// </summary>
    private readonly IEventPublisher eventPublisher;

    /// <summary>
    /// Reporter for percentage progress notifications.
    /// </summary>
    private readonly IProgressReporter progressReporter;

    /// <summary>
    /// Root settings containing module list and parallelism configuration.
    /// </summary>
    private readonly AxbusRootSettings settings;

    /// <summary>
    /// Initializes a new instance of <see cref="ConversionRunner"/>.
    /// </summary>
    /// <param name="logger">Logger for runner lifecycle messages.</param>
    /// <param name="pipelineFactory">Factory that creates pipelines per module.</param>
    /// <param name="eventPublisher">Publisher for observable event notifications.</param>
    /// <param name="progressReporter">Reporter for IProgress progress notifications.</param>
    /// <param name="options">Root Axbus settings bound from configuration.</param>
    public ConversionRunner(
        ILogger<ConversionRunner> logger,
        IPipelineFactory pipelineFactory,
        IEventPublisher eventPublisher,
        IProgressReporter progressReporter,
        IOptions<AxbusRootSettings> options)
    {
        this.logger = logger;
        this.pipelineFactory = pipelineFactory;
        this.eventPublisher = eventPublisher;
        this.progressReporter = progressReporter;
        this.settings = options.Value;
    }

    /// <summary>
    /// Executes all enabled conversion modules and returns a
    /// <see cref="ConversionSummary"/> with aggregated results.
    /// </summary>
    /// <param name="progress">Optional progress reporter for UI feedback.</param>
    /// <param name="cancellationToken">Token to cancel the run.</param>
    /// <returns>A <see cref="ConversionSummary"/> with per-module results.</returns>
    public async Task<ConversionSummary> RunAsync(
        IProgress<ConversionProgress>? progress = null,
        CancellationToken cancellationToken = default)
    {
        // Register external progress consumer if provided
        if (progress != null)
        {
            progressReporter.Register(progress);
        }

        // Filter and order enabled modules
        var enabledModules = settings.ConversionModules
            .Where(m => m.IsEnabled)
            .OrderBy(m => m.ExecutionOrder)
            .ToList();

        var skippedModules = settings.ConversionModules
            .Where(m => !m.IsEnabled)
            .ToList();

        logger.LogInformation(
            "Conversion run starting | Enabled: {Enabled} | Skipped: {Skipped}",
            enabledModules.Count,
            skippedModules.Count);

        // Publish skipped module events
        foreach (var skipped in skippedModules)
        {
            Publish(skipped.ConversionName, ConversionEventType.ModuleSkipped,
                $"Module '{skipped.ConversionName}' is disabled and will be skipped.");
        }

        var stopwatch = Stopwatch.StartNew();
        var moduleResults = new List<ModuleResult>();

        // Determine whether to run in parallel
        // Root RunInParallel=false is the master safety switch - overrides all module flags
        var rootParallel = settings.RunInParallel;

        if (rootParallel == false)
        {
            // Sequential execution - root safety switch is active
            foreach (var module in enabledModules)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var result = await ExecuteModuleAsync(module, cancellationToken).ConfigureAwait(false);
                moduleResults.Add(result);
            }
        }
        else
        {
            // Root is null or true - respect individual module RunInParallel flags
            var parallelModules = enabledModules.Where(m => m.RunInParallel).ToList();
            var sequentialModules = enabledModules.Where(m => !m.RunInParallel).ToList();

            // Run sequential modules first in order
            foreach (var module in sequentialModules)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var result = await ExecuteModuleAsync(module, cancellationToken).ConfigureAwait(false);
                moduleResults.Add(result);
            }

            // Run parallel modules concurrently with throttling
            if (parallelModules.Count > 0)
            {
                var maxDegree = settings.ParallelSettings.MaxDegreeOfParallelism;
                var semaphore = new SemaphoreSlim(maxDegree);
                var parallelTasks = parallelModules.Select(async module =>
                {
                    await semaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
                    try
                    {
                        return await ExecuteModuleAsync(module, cancellationToken).ConfigureAwait(false);
                    }
                    finally
                    {
                        semaphore.Release();
                    }
                });

                var parallelResults = await Task.WhenAll(parallelTasks).ConfigureAwait(false);
                moduleResults.AddRange(parallelResults);
            }
        }

        stopwatch.Stop();

        // Build and return summary
        var summary = BuildSummary(moduleResults, skippedModules.Count, stopwatch.Elapsed);

        logger.LogInformation(
            "Conversion run complete | Duration: {Duration}ms | Success: {Success} | Failed: {Failed}",
            stopwatch.ElapsedMilliseconds,
            summary.SuccessfulModules,
            summary.FailedModules);

        eventPublisher.Complete();

        return summary;
    }

    /// <summary>
    /// Executes a single conversion module and returns its result.
    /// Handles ContinueOnError logic and publishes lifecycle events.
    /// </summary>
    /// <param name="module">The module to execute.</param>
    /// <param name="cancellationToken">Token to cancel execution.</param>
    /// <returns>A <see cref="ModuleResult"/> for the executed module.</returns>
    private async Task<ModuleResult> ExecuteModuleAsync(
        ConversionModule module,
        CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();

        logger.LogInformation(
            "Module starting: {ModuleName}",
            module.ConversionName);

        Publish(module.ConversionName, ConversionEventType.ModuleStarted,
            $"Module '{module.ConversionName}' started.");

        var result = new ModuleResult
        {
            ModuleName = module.ConversionName,
            Status = ConversionStatus.Converting,
        };

        try
        {
            // Create pipeline for this module
            var pipeline = pipelineFactory.Create(module);

            // Report discovering status
            progressReporter.Report(new ConversionProgress
            {
                ModuleName = module.ConversionName,
                Status = ConversionStatus.Discovering,
                PercentComplete = 0,
            });

            // Get list of source files from source path
            // For now, treat single file execution - full file enumeration
            // is handled by the infrastructure layer connectors
            var writeResult = await pipeline.ExecuteAsync(
                module,
                module.Source.Path,
                cancellationToken).ConfigureAwait(false);

            result.FilesProcessed = 1;
            result.RowsWritten = writeResult.RowsWritten;
            result.ErrorRowsWritten = writeResult.ErrorRowsWritten;
            result.OutputFilePath = writeResult.OutputPath;
            result.ErrorFilePath = writeResult.ErrorFilePath;
            result.Status = ConversionStatus.Completed;

            if (!string.IsNullOrEmpty(writeResult.OutputPath))
            {
                result.OutputFiles.Add(writeResult.OutputPath);
            }

            Publish(module.ConversionName, ConversionEventType.ModuleCompleted,
                $"Module '{module.ConversionName}' completed. Rows written: {result.RowsWritten}");

            logger.LogInformation(
                "Module completed: {ModuleName} | Rows: {Rows} | ErrorRows: {ErrorRows}",
                module.ConversionName,
                result.RowsWritten,
                result.ErrorRowsWritten);
        }
        catch (OperationCanceledException)
        {
            // Always propagate cancellation
            throw;
        }
        catch (Exception ex)
        {
            result.Status = ConversionStatus.Failed;
            result.Errors.Add(ex.Message);

            logger.LogError(
                ex,
                "Module failed: {ModuleName}",
                module.ConversionName);

            Publish(module.ConversionName, ConversionEventType.ModuleFailed,
                $"Module '{module.ConversionName}' failed: {ex.Message}",
                exception: ex);

            if (!module.ContinueOnError)
            {
                throw new AxbusPipelineException(
                    $"Module '{module.ConversionName}' failed and ContinueOnError is false.",
                    ex);
            }
        }
        finally
        {
            stopwatch.Stop();
            result.Duration = stopwatch.Elapsed;

            // Report final progress for this module
            progressReporter.Report(new ConversionProgress
            {
                ModuleName = module.ConversionName,
                Status = result.Status,
                PercentComplete = 100,
            });
        }

        return result;
    }

    /// <summary>
    /// Publishes a <see cref="ConversionEvent"/> to the event stream.
    /// </summary>
    /// <param name="moduleName">The name of the module raising the event.</param>
    /// <param name="eventType">The type of lifecycle event.</param>
    /// <param name="message">A human-readable event message.</param>
    /// <param name="fileName">Optional file name associated with the event.</param>
    /// <param name="exception">Optional exception associated with a failure event.</param>
    private void Publish(
        string moduleName,
        ConversionEventType eventType,
        string message,
        string? fileName = null,
        Exception? exception = null)
    {
        eventPublisher.Publish(new ConversionEvent
        {
            ModuleName = moduleName,
            Type = eventType,
            Message = message,
            FileName = fileName,
            Exception = exception,
        });
    }

    /// <summary>
    /// Builds the <see cref="ConversionSummary"/> from individual module results.
    /// </summary>
    /// <param name="results">The list of module results to aggregate.</param>
    /// <param name="skippedCount">The number of modules that were skipped.</param>
    /// <param name="totalDuration">The total elapsed time for the run.</param>
    /// <returns>A populated <see cref="ConversionSummary"/>.</returns>
    private static ConversionSummary BuildSummary(
        List<ModuleResult> results,
        int skippedCount,
        TimeSpan totalDuration)
    {
        return new ConversionSummary
        {
            TotalModules = results.Count + skippedCount,
            SuccessfulModules = results.Count(r => r.Status == ConversionStatus.Completed),
            FailedModules = results.Count(r => r.Status == ConversionStatus.Failed),
            SkippedModules = skippedCount,
            TotalFilesProcessed = results.Sum(r => r.FilesProcessed),
            TotalRowsWritten = results.Sum(r => r.RowsWritten),
            TotalErrorRows = results.Sum(r => r.ErrorRowsWritten),
            TotalDuration = totalDuration,
            Results = results,
        };
    }
}
'@

# ==============================================================================
# PHASE 4 - PLUGIN
# ==============================================================================

Write-Phase "Phase 4 - Plugin (6 files)"

New-SourceFile "Plugin/PluginCompatibilityChecker.cs" @'
// <copyright file="PluginCompatibilityChecker.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;

/// <summary>
/// Validates whether a plugin is compatible with the running Axbus framework version.
/// Compares the plugin's declared minimum framework version against the current
/// framework version using semantic versioning rules. Incompatible plugins are
/// skipped with an error log rather than causing application startup to fail.
/// </summary>
public sealed class PluginCompatibilityChecker
{
    /// <summary>
    /// Logger instance for compatibility check diagnostic messages.
    /// </summary>
    private readonly ILogger<PluginCompatibilityChecker> logger;

    /// <summary>
    /// The current Axbus framework version to check against.
    /// </summary>
    private readonly Version frameworkVersion;

    /// <summary>
    /// Initializes a new instance of <see cref="PluginCompatibilityChecker"/>.
    /// </summary>
    /// <param name="logger">The logger for compatibility check messages.</param>
    /// <param name="frameworkVersion">The current framework version to validate against.</param>
    public PluginCompatibilityChecker(ILogger<PluginCompatibilityChecker> logger, Version frameworkVersion)
    {
        this.logger = logger;
        this.frameworkVersion = frameworkVersion;
    }

    /// <summary>
    /// Checks whether the plugin described by <paramref name="manifest"/>
    /// is compatible with the current framework version.
    /// </summary>
    /// <param name="manifest">The plugin manifest containing the declared framework version requirement.</param>
    /// <returns>
    /// A <see cref="PluginCompatibility"/> indicating whether the plugin is compatible
    /// and the reason if it is not.
    /// </returns>
    public PluginCompatibility Check(PluginManifest manifest)
    {
        ArgumentNullException.ThrowIfNull(manifest);

        // Parse the plugin's required framework version from the manifest
        if (!Version.TryParse(manifest.FrameworkVersion, out var requiredVersion))
        {
            var reason = $"Plugin '{manifest.PluginId}' has an invalid FrameworkVersion value: '{manifest.FrameworkVersion}'.";
            logger.LogError(reason);
            return PluginCompatibility.Incompatible(reason);
        }

        // Plugin requires a framework version newer than what is running
        if (requiredVersion > frameworkVersion)
        {
            var reason = $"Plugin '{manifest.PluginId}' requires framework v{requiredVersion} " +
                         $"but current version is v{frameworkVersion}.";
            logger.LogError(reason);
            return PluginCompatibility.Incompatible(reason);
        }

        logger.LogDebug(
            "Plugin '{PluginId}' passed compatibility check. Required: v{Required} | Current: v{Current}",
            manifest.PluginId,
            requiredVersion,
            frameworkVersion);

        return PluginCompatibility.Compatible;
    }
}
'@

New-SourceFile "Plugin/PluginManifestReader.cs" @'
// <copyright file="PluginManifestReader.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using System.Text.Json;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;

/// <summary>
/// Reads and deserialises a plugin manifest file (<c>*.manifest.json</c>)
/// into a <see cref="PluginManifest"/> model. The manifest is read before
/// the plugin assembly is loaded so that version compatibility can be checked
/// without incurring the cost of loading the full assembly.
/// </summary>
public sealed class PluginManifestReader : IPluginManifestReader
{
    /// <summary>
    /// Logger instance for manifest reading diagnostic messages.
    /// </summary>
    private readonly ILogger<PluginManifestReader> logger;

    /// <summary>
    /// JSON serializer options configured for case-insensitive property matching.
    /// </summary>
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    /// <summary>
    /// Initializes a new instance of <see cref="PluginManifestReader"/>.
    /// </summary>
    /// <param name="logger">The logger for manifest reading messages.</param>
    public PluginManifestReader(ILogger<PluginManifestReader> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Reads and deserialises the manifest file at <paramref name="manifestPath"/>.
    /// </summary>
    /// <param name="manifestPath">The full path to the <c>*.manifest.json</c> file.</param>
    /// <param name="cancellationToken">A token to cancel the read operation.</param>
    /// <returns>A <see cref="PluginManifest"/> populated from the manifest file.</returns>
    /// <exception cref="AxbusPluginException">
    /// Thrown when the manifest file cannot be read or contains invalid JSON.
    /// </exception>
    public async Task<PluginManifest> ReadAsync(string manifestPath, CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(manifestPath);

        if (!File.Exists(manifestPath))
        {
            throw new AxbusPluginException(
                $"Manifest file not found: {manifestPath}",
                Path.GetFileNameWithoutExtension(manifestPath));
        }

        logger.LogDebug("Reading plugin manifest: {ManifestPath}", manifestPath);

        try
        {
            await using var stream = File.OpenRead(manifestPath);
            var manifest = await JsonSerializer.DeserializeAsync<PluginManifest>(
                stream,
                SerializerOptions,
                cancellationToken).ConfigureAwait(false);

            if (manifest == null)
            {
                throw new AxbusPluginException(
                    $"Manifest file is empty or could not be deserialised: {manifestPath}",
                    Path.GetFileNameWithoutExtension(manifestPath));
            }

            logger.LogDebug(
                "Manifest read successfully: {PluginId} v{Version}",
                manifest.PluginId,
                manifest.Version);

            return manifest;
        }
        catch (JsonException ex)
        {
            throw new AxbusPluginException(
                $"Manifest file contains invalid JSON: {manifestPath}",
                Path.GetFileNameWithoutExtension(manifestPath),
                ex);
        }
        catch (AxbusPluginException)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw new AxbusPluginException(
                $"Failed to read manifest file: {manifestPath}",
                Path.GetFileNameWithoutExtension(manifestPath),
                ex);
        }
    }
}
'@

New-SourceFile "Plugin/PluginIsolationContext.cs" @'
// <copyright file="PluginIsolationContext.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using System.Reflection;
using System.Runtime.Loader;

/// <summary>
/// An <see cref="AssemblyLoadContext"/> that provides isolation for a single plugin assembly.
/// Each plugin loaded with <see cref="Axbus.Core.Enums.PluginIsolationMode.Isolated"/>
/// gets its own instance of this context, preventing DLL version conflicts between
/// plugins and between plugins and the host application.
/// Implements collectible unloading so that plugins can be removed without restarting.
/// </summary>
public sealed class PluginIsolationContext : AssemblyLoadContext
{
    /// <summary>
    /// The resolver used to locate dependency assemblies from the plugin folder.
    /// </summary>
    private readonly AssemblyDependencyResolver resolver;

    /// <summary>
    /// Initializes a new instance of <see cref="PluginIsolationContext"/>.
    /// </summary>
    /// <param name="pluginAssemblyPath">The full path to the plugin assembly DLL.</param>
    public PluginIsolationContext(string pluginAssemblyPath)
        : base(name: Path.GetFileNameWithoutExtension(pluginAssemblyPath), isCollectible: true)
    {
        resolver = new AssemblyDependencyResolver(pluginAssemblyPath);
    }

    /// <summary>
    /// Resolves an assembly by name, first checking the plugin folder via the
    /// dependency resolver, then falling back to the default load context.
    /// </summary>
    /// <param name="assemblyName">The name of the assembly to resolve.</param>
    /// <returns>The resolved <see cref="Assembly"/>, or <c>null</c> if not found in the plugin folder.</returns>
    protected override Assembly? Load(AssemblyName assemblyName)
    {
        // Try to resolve from the plugin's own folder first
        var assemblyPath = resolver.ResolveAssemblyToPath(assemblyName);

        if (assemblyPath != null)
        {
            // Load from plugin folder into this isolated context
            return LoadFromAssemblyPath(assemblyPath);
        }

        // Fall back to default context for framework and shared assemblies
        return null;
    }
}
'@

New-SourceFile "Plugin/PluginLoader.cs" @'
// <copyright file="PluginLoader.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using System.Reflection;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

/// <summary>
/// Loads plugin assemblies from disk into the appropriate
/// <see cref="System.Runtime.Loader.AssemblyLoadContext"/> and creates
/// <see cref="IPlugin"/> instances ready for registration.
/// Uses <see cref="PluginIsolationContext"/> when isolation is enabled.
/// </summary>
public sealed class PluginLoader : IPluginLoader
{
    /// <summary>
    /// Logger instance for plugin loading diagnostic messages.
    /// </summary>
    private readonly ILogger<PluginLoader> logger;

    /// <summary>
    /// Plugin settings controlling isolation mode.
    /// </summary>
    private readonly PluginSettings pluginSettings;

    /// <summary>
    /// Initializes a new instance of <see cref="PluginLoader"/>.
    /// </summary>
    /// <param name="logger">The logger for plugin loading messages.</param>
    /// <param name="options">Root settings containing plugin isolation configuration.</param>
    public PluginLoader(ILogger<PluginLoader> logger, IOptions<AxbusRootSettings> options)
    {
        this.logger = logger;
        this.pluginSettings = options.Value.PluginSettings;
    }

    /// <summary>
    /// Loads the plugin assembly identified by <paramref name="fileSet"/>
    /// and returns a <see cref="PluginDescriptor"/> with the created plugin instance.
    /// </summary>
    /// <param name="fileSet">The DLL and manifest file paths for the plugin to load.</param>
    /// <param name="cancellationToken">A token to cancel the load operation.</param>
    /// <returns>A populated <see cref="PluginDescriptor"/>.</returns>
    /// <exception cref="AxbusPluginException">
    /// Thrown when the assembly cannot be loaded or contains no valid <see cref="IPlugin"/> implementation.
    /// </exception>
    public async Task<PluginDescriptor> LoadAsync(PluginFileSet fileSet, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(fileSet);

        logger.LogDebug("Loading plugin assembly: {AssemblyPath}", fileSet.AssemblyPath);

        await Task.Yield(); // Ensure async context without blocking

        try
        {
            Assembly assembly;
            var isIsolated = pluginSettings.IsolatePlugins;

            if (isIsolated)
            {
                // Load into isolated AssemblyLoadContext
                var isolationContext = new PluginIsolationContext(fileSet.AssemblyPath);
                assembly = isolationContext.LoadFromAssemblyPath(fileSet.AssemblyPath);
            }
            else
            {
                // Load into default context (not recommended for production)
                assembly = Assembly.LoadFrom(fileSet.AssemblyPath);
            }

            // Find the IPlugin implementation in the loaded assembly
            var pluginType = assembly.GetTypes()
                .FirstOrDefault(t => typeof(IPlugin).IsAssignableFrom(t) && !t.IsAbstract && t.IsClass);

            if (pluginType == null)
            {
                throw new AxbusPluginException(
                    $"Assembly '{fileSet.AssemblyPath}' does not contain a class implementing IPlugin.",
                    Path.GetFileNameWithoutExtension(fileSet.AssemblyPath));
            }

            // Create the plugin instance using the parameterless constructor
            var pluginInstance = (IPlugin?)Activator.CreateInstance(pluginType)
                ?? throw new AxbusPluginException(
                    $"Failed to create instance of plugin type '{pluginType.FullName}'.",
                    pluginType.Name);

            logger.LogInformation(
                "Plugin loaded: {PluginId} v{Version} | Isolated: {Isolated}",
                pluginInstance.PluginId,
                pluginInstance.Version,
                isIsolated);

            return new PluginDescriptor
            {
                Instance = pluginInstance,
                Manifest = new PluginManifest
                {
                    PluginId = pluginInstance.PluginId,
                    Name = pluginInstance.Name,
                    Version = pluginInstance.Version.ToString(),
                },
                Assembly = assembly,
                IsIsolated = isIsolated,
            };
        }
        catch (AxbusPluginException)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw new AxbusPluginException(
                $"Failed to load plugin from '{fileSet.AssemblyPath}': {ex.Message}",
                Path.GetFileNameWithoutExtension(fileSet.AssemblyPath),
                ex);
        }
    }
}
'@

New-SourceFile "Plugin/PluginContextFactory.cs" @'
// <copyright file="PluginContextFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;

/// <summary>
/// Creates <see cref="IPluginContext"/> instances for use during plugin initialisation.
/// Provides each plugin with its folder path, typed options, a scoped logger
/// and information about the running framework version.
/// </summary>
public sealed class PluginContextFactory
{
    /// <summary>
    /// Logger factory used to create scoped loggers for each plugin.
    /// </summary>
    private readonly ILoggerFactory loggerFactory;

    /// <summary>
    /// Factory for deserialising plugin-specific options from module configuration.
    /// </summary>
    private readonly IPluginOptionsFactory optionsFactory;

    /// <summary>
    /// The current framework version passed to plugins during initialisation.
    /// </summary>
    private readonly FrameworkInfo frameworkInfo;

    /// <summary>
    /// Initializes a new instance of <see cref="PluginContextFactory"/>.
    /// </summary>
    /// <param name="loggerFactory">Factory used to create per-plugin loggers.</param>
    /// <param name="optionsFactory">Factory for creating typed plugin options.</param>
    /// <param name="frameworkInfo">Current framework version and environment information.</param>
    public PluginContextFactory(
        ILoggerFactory loggerFactory,
        IPluginOptionsFactory optionsFactory,
        FrameworkInfo frameworkInfo)
    {
        this.loggerFactory = loggerFactory;
        this.optionsFactory = optionsFactory;
        this.frameworkInfo = frameworkInfo;
    }

    /// <summary>
    /// Creates an <see cref="IPluginContext"/> for the plugin identified by
    /// <paramref name="pluginId"/> using the options from <paramref name="module"/>.
    /// </summary>
    /// <param name="pluginId">The unique identifier of the plugin being initialised.</param>
    /// <param name="pluginFolder">The full path to the plugin folder.</param>
    /// <param name="module">The conversion module whose options should be provided to the plugin.</param>
    /// <returns>A configured <see cref="IPluginContext"/> ready for plugin initialisation.</returns>
    public IPluginContext Create(string pluginId, string pluginFolder, ConversionModule module)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(pluginId);
        ArgumentNullException.ThrowIfNull(module);

        // Create a scoped logger for this specific plugin
        var scopedLogger = loggerFactory.CreateLogger(pluginId);

        // Deserialise plugin options with an empty default if no options are configured
        var options = optionsFactory.Create<EmptyPluginOptions>(module);

        return new DefaultPluginContext(pluginId, pluginFolder, options, scopedLogger, frameworkInfo);
    }

    /// <summary>
    /// Default implementation of <see cref="IPluginContext"/> used during initialisation.
    /// </summary>
    private sealed class DefaultPluginContext : IPluginContext
    {
        /// <summary>Gets the unique identifier of the plugin being initialised.</summary>
        public string PluginId { get; }

        /// <summary>Gets the full path to the folder containing the plugin assembly.</summary>
        public string PluginFolder { get; }

        /// <summary>Gets the strongly-typed options for this plugin.</summary>
        public IPluginOptions Options { get; }

        /// <summary>Gets a scoped logger for the plugin to use during initialisation.</summary>
        public ILogger Logger { get; }

        /// <summary>Gets information about the running Axbus framework version.</summary>
        public FrameworkInfo Framework { get; }

        /// <summary>
        /// Initializes a new instance of <see cref="DefaultPluginContext"/>.
        /// </summary>
        public DefaultPluginContext(
            string pluginId,
            string pluginFolder,
            IPluginOptions options,
            ILogger logger,
            FrameworkInfo frameworkInfo)
        {
            PluginId = pluginId;
            PluginFolder = pluginFolder;
            Options = options;
            Logger = logger;
            Framework = frameworkInfo;
        }
    }

    /// <summary>
    /// Fallback empty options used when no plugin-specific options are configured.
    /// </summary>
    private sealed class EmptyPluginOptions : IPluginOptions
    {
    }
}
'@

New-SourceFile "Plugin/PluginRegistry.cs" @'
// <copyright file="PluginRegistry.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Plugin;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

/// <summary>
/// Maintains the registry of loaded plugins and resolves the appropriate plugin
/// for a given source and target format combination. Applies the configured
/// <see cref="PluginConflictStrategy"/> when multiple plugins support the same
/// format pair.
/// </summary>
public sealed class PluginRegistry : IPluginRegistry
{
    /// <summary>
    /// Logger instance for registry diagnostic messages.
    /// </summary>
    private readonly ILogger<PluginRegistry> logger;

    /// <summary>
    /// The configured conflict resolution strategy.
    /// </summary>
    private readonly PluginConflictStrategy conflictStrategy;

    /// <summary>
    /// All registered plugin descriptors indexed by plugin ID.
    /// </summary>
    private readonly Dictionary<string, PluginDescriptor> descriptors = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>
    /// Format pair to plugin ID mapping for fast resolution.
    /// Key format: "sourceFormat:targetFormat".
    /// </summary>
    private readonly Dictionary<string, string> formatMap = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>
    /// Initializes a new instance of <see cref="PluginRegistry"/>.
    /// </summary>
    /// <param name="logger">The logger for registry operations.</param>
    /// <param name="options">Root settings containing the conflict strategy configuration.</param>
    public PluginRegistry(ILogger<PluginRegistry> logger, IOptions<AxbusRootSettings> options)
    {
        this.logger = logger;
        this.conflictStrategy = options.Value.PluginSettings.ConflictStrategy;
    }

    /// <summary>
    /// Registers a loaded plugin in the registry with conflict resolution.
    /// </summary>
    /// <param name="descriptor">The descriptor of the plugin to register.</param>
    /// <exception cref="AxbusPluginException">
    /// Thrown when <see cref="PluginConflictStrategy.ThrowException"/> is configured
    /// and a conflict exists.
    /// </exception>
    public void Register(PluginDescriptor descriptor)
    {
        ArgumentNullException.ThrowIfNull(descriptor);

        var pluginId = descriptor.Instance.PluginId;

        // Build the format map key for this plugin
        var sourceFormat = descriptor.Manifest.SourceFormat ?? string.Empty;
        var targetFormat = descriptor.Manifest.TargetFormat ?? string.Empty;
        var formatKey = $"{sourceFormat}:{targetFormat}";

        // Handle conflict if a plugin for this format pair is already registered
        if (formatMap.TryGetValue(formatKey, out var existingId) && !string.IsNullOrEmpty(formatKey.Trim(':')))
        {
            var existingDescriptor = descriptors[existingId];

            switch (conflictStrategy)
            {
                case PluginConflictStrategy.UseLatestVersion:
                    var existingVersion = existingDescriptor.Instance.Version;
                    var newVersion = descriptor.Instance.Version;
                    if (newVersion <= existingVersion)
                    {
                        logger.LogWarning(
                            "Plugin conflict: '{NewId}' v{NewVer} skipped in favour of '{ExistingId}' v{ExistingVer}",
                            pluginId, newVersion, existingId, existingVersion);
                        return;
                    }
                    logger.LogInformation(
                        "Plugin conflict resolved: '{NewId}' v{NewVer} replaces '{ExistingId}' v{ExistingVer}",
                        pluginId, newVersion, existingId, existingVersion);
                    break;

                case PluginConflictStrategy.UseFirstRegistered:
                    logger.LogWarning(
                        "Plugin conflict: '{NewId}' skipped - '{ExistingId}' was registered first",
                        pluginId, existingId);
                    return;

                case PluginConflictStrategy.ThrowException:
                    throw new AxbusPluginException(
                        $"Plugin conflict: both '{pluginId}' and '{existingId}' handle format '{formatKey}'. " +
                        "Use PluginOverride in the conversion module to resolve.",
                        pluginId);

                case PluginConflictStrategy.UseExplicitOverride:
                    logger.LogWarning(
                        "Plugin conflict: '{NewId}' and '{ExistingId}' both handle '{FormatKey}'. " +
                        "Use PluginOverride to select explicitly.",
                        pluginId, existingId, formatKey);
                    break;
            }
        }

        descriptors[pluginId] = descriptor;

        if (!string.IsNullOrWhiteSpace(formatKey.Trim(':')))
        {
            formatMap[formatKey] = pluginId;
        }

        logger.LogInformation(
            "Plugin registered: {PluginId} | Source: {Source} | Target: {Target}",
            pluginId,
            sourceFormat,
            targetFormat);
    }

    /// <summary>
    /// Resolves the best plugin for the specified source and target format combination.
    /// </summary>
    /// <param name="sourceFormat">The source format identifier.</param>
    /// <param name="targetFormat">The target format identifier.</param>
    /// <returns>The resolved <see cref="IPlugin"/> instance.</returns>
    /// <exception cref="AxbusPluginException">Thrown when no plugin handles the format pair.</exception>
    public IPlugin Resolve(string sourceFormat, string targetFormat)
    {
        var formatKey = $"{sourceFormat}:{targetFormat}";

        if (!formatMap.TryGetValue(formatKey, out var pluginId))
        {
            throw new AxbusPluginException(
                $"No plugin registered for format pair '{formatKey}'. " +
                "Check PluginSettings.Plugins in appsettings.json.");
        }

        return descriptors[pluginId].Instance;
    }

    /// <summary>
    /// Resolves a plugin by its explicit plugin identifier.
    /// </summary>
    /// <param name="pluginId">The unique identifier of the plugin to resolve.</param>
    /// <returns>The matching <see cref="IPlugin"/> instance.</returns>
    /// <exception cref="AxbusPluginException">Thrown when no plugin with the ID is registered.</exception>
    public IPlugin ResolveById(string pluginId)
    {
        if (!descriptors.TryGetValue(pluginId, out var descriptor))
        {
            throw new AxbusPluginException(
                $"No plugin registered with ID '{pluginId}'.",
                pluginId);
        }

        return descriptor.Instance;
    }

    /// <summary>
    /// Gets all currently registered plugin descriptors.
    /// </summary>
    /// <returns>A read-only collection of all registered descriptors.</returns>
    public IReadOnlyCollection<PluginDescriptor> GetAll() => descriptors.Values;
}
'@

# ==============================================================================
# PHASE 5 - FACTORIES
# ==============================================================================

Write-Phase "Phase 5 - Factories (3 files)"

New-SourceFile "Factories/PluginOptionsFactory.cs" @'
// <copyright file="PluginOptionsFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Factories;

using System.Text.Json;
using Axbus.Core.Abstractions.Factories;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Models.Configuration;
using Microsoft.Extensions.Logging;

/// <summary>
/// Deserialises the raw <see cref="ConversionModule.PluginOptions"/> dictionary
/// into a strongly-typed <see cref="IPluginOptions"/> instance. Uses
/// <see cref="JsonSerializer"/> to round-trip the dictionary through JSON
/// so that the plugin's declared options class receives correctly typed values.
/// Unknown keys are captured by properties decorated with
/// <c>[JsonExtensionData]</c> on the options class.
/// </summary>
public sealed class PluginOptionsFactory : IPluginOptionsFactory
{
    /// <summary>
    /// Logger instance for options deserialisation diagnostic messages.
    /// </summary>
    private readonly ILogger<PluginOptionsFactory> logger;

    /// <summary>
    /// JSON serializer options configured for case-insensitive property matching.
    /// </summary>
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    /// <summary>
    /// Initializes a new instance of <see cref="PluginOptionsFactory"/>.
    /// </summary>
    /// <param name="logger">The logger for options deserialisation messages.</param>
    public PluginOptionsFactory(ILogger<PluginOptionsFactory> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Deserialises the plugin options from <paramref name="module"/> into
    /// a strongly-typed <typeparamref name="TOptions"/> instance.
    /// </summary>
    /// <typeparam name="TOptions">The plugin-specific options type.</typeparam>
    /// <param name="module">The conversion module containing the raw plugin options.</param>
    /// <returns>A populated <typeparamref name="TOptions"/> instance.</returns>
    public TOptions Create<TOptions>(ConversionModule module) where TOptions : IPluginOptions, new()
    {
        ArgumentNullException.ThrowIfNull(module);

        if (module.PluginOptions == null || module.PluginOptions.Count == 0)
        {
            // No plugin options configured - return default instance
            return new TOptions();
        }

        try
        {
            // Round-trip through JSON: Dictionary -> JSON string -> TOptions
            var json = JsonSerializer.Serialize(module.PluginOptions, SerializerOptions);
            var options = JsonSerializer.Deserialize<TOptions>(json, SerializerOptions);

            return options ?? new TOptions();
        }
        catch (Exception ex)
        {
            logger.LogWarning(
                ex,
                "Failed to deserialise plugin options for module '{ModuleName}' into {OptionsType}. Using defaults.",
                module.ConversionName,
                typeof(TOptions).Name);

            return new TOptions();
        }
    }
}
'@

New-SourceFile "Factories/MiddlewareFactory.cs" @'
// <copyright file="MiddlewareFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Factories;

using Axbus.Application.Middleware;
using Axbus.Core.Abstractions.Factories;
using Axbus.Core.Abstractions.Middleware;
using Axbus.Core.Models.Configuration;
using Microsoft.Extensions.Logging;

/// <summary>
/// Resolves and orders the middleware chain applied to each pipeline stage execution.
/// The default chain is: <see cref="LoggingMiddleware"/> (outermost)
/// -> <see cref="TimingMiddleware"/> -> <see cref="ErrorHandlingMiddleware"/> (innermost).
/// This ordering ensures that logging captures the total duration including error handling,
/// and that timing is accurate for the actual stage work.
/// </summary>
public sealed class MiddlewareFactory : IMiddlewareFactory
{
    /// <summary>
    /// Logger factory used to create loggers for each middleware component.
    /// </summary>
    private readonly ILoggerFactory loggerFactory;

    /// <summary>
    /// The pipeline options containing the row error strategy for error handling middleware.
    /// </summary>
    private readonly PipelineOptions pipelineOptions;

    /// <summary>
    /// Initializes a new instance of <see cref="MiddlewareFactory"/>.
    /// </summary>
    /// <param name="loggerFactory">Factory for creating typed loggers per middleware.</param>
    /// <param name="pipelineOptions">Pipeline options for the error handling middleware.</param>
    public MiddlewareFactory(ILoggerFactory loggerFactory, PipelineOptions pipelineOptions)
    {
        this.loggerFactory = loggerFactory;
        this.pipelineOptions = pipelineOptions;
    }

    /// <summary>
    /// Creates the ordered middleware chain for pipeline stage execution.
    /// Components are listed outermost first.
    /// </summary>
    /// <returns>An ordered read-only list of middleware components.</returns>
    public IReadOnlyList<IPipelineMiddleware> Create()
    {
        return new List<IPipelineMiddleware>
        {
            // Outermost: logging wraps everything so it records total time including errors
            new LoggingMiddleware(loggerFactory.CreateLogger<LoggingMiddleware>()),

            // Timing: measures elapsed time for the stage and all inner middleware
            new TimingMiddleware(),

            // Innermost: error handling catches exceptions from the stage itself
            new ErrorHandlingMiddleware(
                loggerFactory.CreateLogger<ErrorHandlingMiddleware>(),
                pipelineOptions),
        };
    }
}
'@

New-SourceFile "Factories/PipelineFactory.cs" @'
// <copyright file="PipelineFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Factories;

using Axbus.Application.Pipeline;
using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Abstractions.Factories;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Microsoft.Extensions.Logging;

/// <summary>
/// Creates a fully configured <see cref="IConversionPipeline"/> for a specific
/// conversion module. Resolves the appropriate plugin from the registry,
/// assembles the middleware chain and constructs the pipeline instance.
/// </summary>
public sealed class PipelineFactory : IPipelineFactory
{
    /// <summary>
    /// Logger instance for pipeline factory diagnostic messages.
    /// </summary>
    private readonly ILogger<PipelineFactory> logger;

    /// <summary>
    /// Plugin registry used to resolve reader and writer plugins per module.
    /// </summary>
    private readonly IPluginRegistry pluginRegistry;

    /// <summary>
    /// Middleware factory for assembling the stage middleware chain.
    /// </summary>
    private readonly IMiddlewareFactory middlewareFactory;

    /// <summary>
    /// Logger factory for creating typed loggers for pipeline instances.
    /// </summary>
    private readonly ILoggerFactory loggerFactory;

    /// <summary>
    /// Service provider for passing to plugin stage factory methods.
    /// </summary>
    private readonly IServiceProvider serviceProvider;

    /// <summary>
    /// Initializes a new instance of <see cref="PipelineFactory"/>.
    /// </summary>
    /// <param name="logger">The logger for factory operations.</param>
    /// <param name="pluginRegistry">Registry providing plugin resolution.</param>
    /// <param name="middlewareFactory">Factory for the middleware chain.</param>
    /// <param name="loggerFactory">Factory for creating typed loggers.</param>
    /// <param name="serviceProvider">Service provider passed to plugin stage factories.</param>
    public PipelineFactory(
        ILogger<PipelineFactory> logger,
        IPluginRegistry pluginRegistry,
        IMiddlewareFactory middlewareFactory,
        ILoggerFactory loggerFactory,
        IServiceProvider serviceProvider)
    {
        this.logger = logger;
        this.pluginRegistry = pluginRegistry;
        this.middlewareFactory = middlewareFactory;
        this.loggerFactory = loggerFactory;
        this.serviceProvider = serviceProvider;
    }

    /// <summary>
    /// Creates a fully configured <see cref="IConversionPipeline"/> for <paramref name="module"/>.
    /// </summary>
    /// <param name="module">The conversion module to build a pipeline for.</param>
    /// <returns>A ready-to-execute <see cref="IConversionPipeline"/>.</returns>
    /// <exception cref="AxbusPluginException">
    /// Thrown when no suitable plugin can be resolved for the module format combination.
    /// </exception>
    public IConversionPipeline Create(ConversionModule module)
    {
        ArgumentNullException.ThrowIfNull(module);

        // Resolve plugin - use explicit override if specified, otherwise auto-resolve
        var plugin = !string.IsNullOrWhiteSpace(module.PluginOverride)
            ? pluginRegistry.ResolveById(module.PluginOverride)
            : pluginRegistry.Resolve(module.SourceFormat, module.TargetFormat);

        logger.LogDebug(
            "Creating pipeline for module '{ModuleName}' using plugin '{PluginId}'",
            module.ConversionName,
            plugin.PluginId);

        // Build middleware chain for this module's pipeline options
        var middlewareList = middlewareFactory.Create();

        // Create the stage executor that wraps stages in the middleware chain
        var stageExecutor = new PipelineStageExecutor(
            loggerFactory.CreateLogger<PipelineStageExecutor>(),
            middlewareList);

        return new ConversionPipeline(
            loggerFactory.CreateLogger<ConversionPipeline>(),
            plugin,
            stageExecutor,
            serviceProvider);
    }
}
'@

# ==============================================================================
# PHASE 6 - NOTIFICATIONS
# ==============================================================================

Write-Phase "Phase 6 - Notifications (2 files)"

New-SourceFile "Notifications/ProgressReporter.cs" @'
// <copyright file="ProgressReporter.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Notifications;

using Axbus.Core.Abstractions.Notifications;
using Axbus.Core.Models.Notifications;

/// <summary>
/// Implements <see cref="IProgressReporter"/> using the standard
/// <see cref="IProgress{T}"/> pattern. Allows multiple consumers to register
/// for progress updates. Each registered consumer is invoked on the
/// synchronisation context that was active when it was registered,
/// ensuring safe UI thread callbacks for WinForms consumers.
/// </summary>
public sealed class ProgressReporter : IProgressReporter
{
    /// <summary>
    /// The list of registered progress consumers.
    /// </summary>
    private readonly List<IProgress<ConversionProgress>> consumers = new();

    /// <summary>
    /// Lock object for thread-safe consumer list access.
    /// </summary>
    private readonly object consumerLock = new();

    /// <summary>
    /// Reports <paramref name="progress"/> to all registered consumers.
    /// Each consumer is invoked independently so that a slow consumer
    /// does not block others.
    /// </summary>
    /// <param name="progress">The current progress state to report.</param>
    public void Report(ConversionProgress progress)
    {
        ArgumentNullException.ThrowIfNull(progress);

        List<IProgress<ConversionProgress>> snapshot;

        lock (consumerLock)
        {
            // Take a snapshot to avoid holding the lock during callbacks
            snapshot = new List<IProgress<ConversionProgress>>(consumers);
        }

        foreach (var consumer in snapshot)
        {
            consumer.Report(progress);
        }
    }

    /// <summary>
    /// Registers a new <see cref="IProgress{ConversionProgress}"/> consumer.
    /// </summary>
    /// <param name="consumer">The progress consumer to register.</param>
    public void Register(IProgress<ConversionProgress> consumer)
    {
        ArgumentNullException.ThrowIfNull(consumer);

        lock (consumerLock)
        {
            consumers.Add(consumer);
        }
    }
}
'@

New-SourceFile "Notifications/EventPublisher.cs" @'
// <copyright file="EventPublisher.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Notifications;

using System.Reactive.Subjects;
using Axbus.Core.Abstractions.Notifications;
using Axbus.Core.Models.Notifications;
using Microsoft.Extensions.Logging;

/// <summary>
/// Implements <see cref="IEventPublisher"/> using a
/// <see cref="Subject{T}"/> from System.Reactive.
/// Publishes <see cref="ConversionEvent"/> notifications to all current
/// subscribers. The subject is thread-safe for concurrent publishers.
/// UI consumers should subscribe before calling
/// <see cref="Axbus.Core.Abstractions.Conversion.IConversionRunner.RunAsync"/>
/// to avoid missing events.
/// </summary>
public sealed class EventPublisher : IEventPublisher, IDisposable
{
    /// <summary>
    /// Logger instance for event publishing diagnostic messages.
    /// </summary>
    private readonly ILogger<EventPublisher> logger;

    /// <summary>
    /// The reactive subject that acts as both observer and observable.
    /// </summary>
    private readonly Subject<ConversionEvent> subject = new();

    /// <summary>
    /// Initializes a new instance of <see cref="EventPublisher"/>.
    /// </summary>
    /// <param name="logger">The logger for event publishing messages.</param>
    public EventPublisher(ILogger<EventPublisher> logger)
    {
        this.logger = logger;
    }

    /// <summary>
    /// Gets the observable stream of conversion events.
    /// </summary>
    public IObservable<ConversionEvent> Events => subject;

    /// <summary>
    /// Publishes a <see cref="ConversionEvent"/> to all current subscribers.
    /// </summary>
    /// <param name="conversionEvent">The event to publish.</param>
    public void Publish(ConversionEvent conversionEvent)
    {
        ArgumentNullException.ThrowIfNull(conversionEvent);

        logger.LogDebug(
            "Event published: {EventType} | Module: {ModuleName}",
            conversionEvent.Type,
            conversionEvent.ModuleName);

        subject.OnNext(conversionEvent);
    }

    /// <summary>
    /// Signals that the event stream is complete. No further events will be published.
    /// </summary>
    public void Complete()
    {
        subject.OnCompleted();
        logger.LogDebug("Event stream completed.");
    }

    /// <summary>
    /// Releases the underlying reactive subject.
    /// </summary>
    public void Dispose()
    {
        subject.Dispose();
    }
}
'@

# ==============================================================================
# PHASE 7 - DI EXTENSIONS
# ==============================================================================

Write-Phase "Phase 7 - Extensions (1 file)"

New-SourceFile "Extensions/ApplicationServiceExtensions.cs" @'
// <copyright file="ApplicationServiceExtensions.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Extensions;

using Axbus.Application.Conversion;
using Axbus.Application.Factories;
using Axbus.Application.Notifications;
using Axbus.Application.Plugin;
using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Abstractions.Factories;
using Axbus.Core.Abstractions.Notifications;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Plugin;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

/// <summary>
/// Provides extension methods for registering all Axbus Application layer
/// services into the dependency injection container. Call
/// <see cref="AddAxbusApplication"/> from the application bootstrapper
/// to wire up the conversion runner, pipeline factory, plugin registry,
/// middleware factory and notification services.
/// </summary>
public static class ApplicationServiceExtensions
{
    /// <summary>
    /// Registers all Axbus Application layer services into <paramref name="services"/>.
    /// </summary>
    /// <param name="services">The service collection to register services into.</param>
    /// <param name="configuration">The application configuration used to bind <see cref="AxbusRootSettings"/>.</param>
    /// <returns>The same <paramref name="services"/> instance for fluent chaining.</returns>
    public static IServiceCollection AddAxbusApplication(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        ArgumentNullException.ThrowIfNull(services);
        ArgumentNullException.ThrowIfNull(configuration);

        // Bind root settings from configuration
        services.Configure<AxbusRootSettings>(configuration);

        // Register framework version info
        services.AddSingleton(new FrameworkInfo(new Version(1, 0, 0), "Production"));

        // Conversion runner - main entry point
        services.AddSingleton<IConversionRunner, ConversionRunner>();

        // Pipeline factory - creates pipelines per module
        services.AddSingleton<IPipelineFactory, PipelineFactory>();

        // Middleware factory - builds the stage middleware chain
        services.AddSingleton<IMiddlewareFactory>(sp =>
        {
            var loggerFactory = sp.GetRequiredService<Microsoft.Extensions.Logging.ILoggerFactory>();
            // Use default pipeline options for the middleware factory
            // Individual module options are applied per execution
            return new MiddlewareFactory(loggerFactory, new PipelineOptions());
        });

        // Plugin registry - stores and resolves loaded plugins
        services.AddSingleton<IPluginRegistry, PluginRegistry>();

        // Plugin loader - loads assemblies into AssemblyLoadContext
        services.AddSingleton<IPluginLoader, PluginLoader>();

        // Plugin manifest reader - deserialises manifest JSON files
        services.AddSingleton<IPluginManifestReader, PluginManifestReader>();

        // Plugin options factory - deserialises module plugin options
        services.AddSingleton<IPluginOptionsFactory, PluginOptionsFactory>();

        // Plugin context factory - creates IPluginContext for initialisation
        services.AddSingleton<PluginContextFactory>();

        // Notifications - progress and event publishing
        services.AddSingleton<IProgressReporter, ProgressReporter>();
        services.AddSingleton<IEventPublisher, EventPublisher>();

        return services;
    }
}
'@

# ==============================================================================
# SUMMARY
# ==============================================================================

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "  [DONE] Axbus.Application - All files generated successfully!" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Files generated:" -ForegroundColor White
Write-Host "    [OK]  6 Middleware" -ForegroundColor Green
Write-Host "    [OK]  2 Pipeline" -ForegroundColor Green
Write-Host "    [OK]  2 Conversion" -ForegroundColor Green
Write-Host "    [OK]  6 Plugin" -ForegroundColor Green
Write-Host "    [OK]  3 Factories" -ForegroundColor Green
Write-Host "    [OK]  2 Notifications" -ForegroundColor Green
Write-Host "    [OK]  1 Extensions" -ForegroundColor Green
Write-Host ""
Write-Host "  Total: 22 source files" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next Steps:" -ForegroundColor Yellow
Write-Host "    1. Save to: scripts/generate-application.ps1" -ForegroundColor White
Write-Host "    2. Run: PowerShell -ExecutionPolicy Bypass -File .\scripts\generate-application.ps1" -ForegroundColor White
Write-Host "    3. Build: dotnet build src/framework/Axbus.Application/Axbus.Application.csproj" -ForegroundColor White
Write-Host "    4. Verify: 0 errors" -ForegroundColor White
Write-Host "    5. Message 3 generates Axbus.Infrastructure" -ForegroundColor White
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""
