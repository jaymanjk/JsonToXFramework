// <copyright file="PluginRegistryTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Application.Tests.Tests.Plugin;

using Axbus.Application.Plugin;
using Axbus.Core.Abstractions.Pipeline;
using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Enums;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Plugin;
using Axbus.Tests.Common.Base;
using Microsoft.Extensions.Options;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="PluginRegistry"/>.
/// </summary>
[TestFixture]
public sealed class PluginRegistryTests : AxbusTestBase
{
    private PluginRegistry sut = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        var settings = new AxbusRootSettings
        {
            PluginSettings = new PluginSettings
            {
                ConflictStrategy = PluginConflictStrategy.UseLatestVersion,
            },
        };
        sut = new PluginRegistry(NullLogger<PluginRegistry>(), Options.Create(settings));
    }

    /// <summary>Should_ResolvePlugin_When_PluginRegisteredForFormatPair.</summary>
    [Test]
    public void Should_ResolvePlugin_When_PluginRegisteredForFormatPair()
    {
        sut.Register(BuildDescriptor("test.reader.json", "json", null));
        var plugin = sut.Resolve("json", string.Empty);
        Assert.That(plugin.PluginId, Is.EqualTo("test.reader.json"));
    }

    /// <summary>Should_ResolvePluginById_When_ExplicitIdProvided.</summary>
    [Test]
    public void Should_ResolvePluginById_When_ExplicitIdProvided()
    {
        sut.Register(BuildDescriptor("axbus.plugin.writer.csv", null, "csv"));
        var plugin = sut.ResolveById("axbus.plugin.writer.csv");
        Assert.That(plugin.PluginId, Is.EqualTo("axbus.plugin.writer.csv"));
    }

    /// <summary>Should_ThrowPluginException_When_NoPluginForFormat.</summary>
    [Test]
    public void Should_ThrowPluginException_When_NoPluginForFormat()
    {
        Assert.Throws<AxbusPluginException>(() => sut.Resolve("xml", "csv"));
    }

    /// <summary>Should_ThrowPluginException_When_PluginIdNotRegistered.</summary>
    [Test]
    public void Should_ThrowPluginException_When_PluginIdNotRegistered()
    {
        Assert.Throws<AxbusPluginException>(() => sut.ResolveById("non.existent"));
    }

    /// <summary>Should_ReturnAllDescriptors_When_GetAllCalled.</summary>
    [Test]
    public void Should_ReturnAllDescriptors_When_GetAllCalled()
    {
        sut.Register(BuildDescriptor("plugin.a", "json", null));
        sut.Register(BuildDescriptor("plugin.b", null, "csv"));
        Assert.That(sut.GetAll().Count, Is.EqualTo(2));
    }

    private static PluginDescriptor BuildDescriptor(string pluginId, string? source, string? target) =>
        new()
        {
            Instance = new StubPlugin(pluginId),
            Manifest = new PluginManifest
            {
                PluginId = pluginId, SourceFormat = source,
                TargetFormat = target, Version = "1.0.0", FrameworkVersion = "1.0.0",
            },
            Assembly  = typeof(PluginRegistryTests).Assembly,
            IsIsolated = false,
        };

    private sealed class StubPlugin : IPlugin
    {
        public string PluginId { get; }
        public string Name => PluginId;
        public Version Version => new(1, 0, 0);
        public Version MinFrameworkVersion => new(1, 0, 0);
        public PluginCapabilities Capabilities => PluginCapabilities.Reader;

        public StubPlugin(string id) => PluginId = id;

        public ISourceReader?    CreateReader(IServiceProvider s)      => null;
        public IFormatParser?    CreateParser(IServiceProvider s)      => null;
        public IDataTransformer? CreateTransformer(IServiceProvider s) => null;
        public IOutputWriter?    CreateWriter(IServiceProvider s)      => null;
        public Task InitializeAsync(IPluginContext ctx, CancellationToken ct) => Task.CompletedTask;
        public Task ShutdownAsync(CancellationToken ct) => Task.CompletedTask;
    }
}