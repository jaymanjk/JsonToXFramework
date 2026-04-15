// <copyright file="ConversionModuleBuilder.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Tests.Common.Builders;

using Axbus.Core.Enums;
using Axbus.Core.Models.Configuration;

/// <summary>
/// Fluent test data builder for <see cref="ConversionModule"/>.
/// Provides pre-configured defaults suitable for unit tests and allows
/// selective overrides via a fluent API.
/// </summary>
public sealed class ConversionModuleBuilder
{
    private string conversionName  = "TestModule";
    private string description     = "Test conversion module";
    private bool isEnabled         = true;
    private int executionOrder     = 1;
    private bool continueOnError   = true;
    private bool runInParallel     = false;
    private string sourceFormat    = "json";
    private string targetFormat    = "csv";
    private string? pluginOverride;
    private SourceOptions source   = new() { Path = "C:/test/input", FilePattern = "*.json" };
    private TargetOptions target   = new() { Path = "C:/test/output" };
    private PipelineOptions pipeline = new();

    /// <summary>Sets the conversion name.</summary>
    public ConversionModuleBuilder WithName(string name)
    { conversionName = name; return this; }

    /// <summary>Marks the module as disabled.</summary>
    public ConversionModuleBuilder Disabled()
    { isEnabled = false; return this; }

    /// <summary>Sets the source format.</summary>
    public ConversionModuleBuilder WithSourceFormat(string format)
    { sourceFormat = format; return this; }

    /// <summary>Sets the target format.</summary>
    public ConversionModuleBuilder WithTargetFormat(string format)
    { targetFormat = format; return this; }

    /// <summary>Sets the source path.</summary>
    public ConversionModuleBuilder WithSourcePath(string path)
    { source = new SourceOptions { Path = path, FilePattern = source.FilePattern }; return this; }

    /// <summary>Sets the target path.</summary>
    public ConversionModuleBuilder WithTargetPath(string path)
    { target = new TargetOptions { Path = path }; return this; }

    /// <summary>Sets the pipeline options.</summary>
    public ConversionModuleBuilder WithPipeline(PipelineOptions options)
    { pipeline = options; return this; }

    /// <summary>Sets ContinueOnError to false.</summary>
    public ConversionModuleBuilder StopOnError()
    { continueOnError = false; return this; }

    /// <summary>Sets the explicit plugin override identifier.</summary>
    public ConversionModuleBuilder WithPluginOverride(string pluginId)
    { pluginOverride = pluginId; return this; }

    /// <summary>Enables parallel execution for this module.</summary>
    public ConversionModuleBuilder RunningInParallel()
    { runInParallel = true; return this; }

    /// <summary>Builds and returns the configured <see cref="ConversionModule"/>.</summary>
    public ConversionModule Build() => new()
    {
        ConversionName  = conversionName,
        Description     = description,
        IsEnabled       = isEnabled,
        ExecutionOrder  = executionOrder,
        ContinueOnError = continueOnError,
        RunInParallel   = runInParallel,
        SourceFormat    = sourceFormat,
        TargetFormat    = targetFormat,
        PluginOverride  = pluginOverride,
        Source          = source,
        Target          = target,
        Pipeline        = pipeline,
    };

    /// <summary>Creates a new builder instance with default settings.</summary>
    public static ConversionModuleBuilder Default() => new();

    /// <summary>Creates a builder pre-configured for JSON-to-CSV conversion.</summary>
    public static ConversionModuleBuilder JsonToCsv() =>
        new ConversionModuleBuilder()
            .WithName("TestJsonToCsv")
            .WithSourceFormat("json")
            .WithTargetFormat("csv");

    /// <summary>Creates a builder pre-configured for JSON-to-Excel conversion.</summary>
    public static ConversionModuleBuilder JsonToExcel() =>
        new ConversionModuleBuilder()
            .WithName("TestJsonToExcel")
            .WithSourceFormat("json")
            .WithTargetFormat("excel");
}