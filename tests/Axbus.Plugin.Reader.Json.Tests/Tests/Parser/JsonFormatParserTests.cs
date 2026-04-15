// <copyright file="JsonFormatParserTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Tests.Tests.Parser;

using System.Text.Json;
using Axbus.Core.Exceptions;
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Tests.Common.Base;
using Axbus.Tests.Common.Helpers;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="JsonFormatParser"/>.
/// </summary>
[TestFixture]
public sealed class JsonFormatParserTests : AxbusTestBase
{
    private JsonFormatParser CreateSut(string? rootArrayKey = null) =>
        new(NullLogger<JsonFormatParser>(), new JsonReaderPluginOptions { RootArrayKey = rootArrayKey });

    /// <summary>Should_StreamAllElements_When_FlatArrayParsed.</summary>
    [Test]
    public async Task Should_StreamAllElements_When_FlatArrayParsed()
    {
        var sourceData = new SourceData(JsonTestDataHelper.FlatArray(3), "test.json", "json");
        var parsed     = await CreateSut().ParseAsync(sourceData, CancellationToken.None);
        var elements   = new List<JsonElement>();

        await foreach (var el in parsed.Elements) elements.Add(el);

        Assert.That(elements.Count, Is.EqualTo(3));
    }

    /// <summary>Should_ReturnEmptyStream_When_EmptyArray.</summary>
    [Test]
    public async Task Should_ReturnEmptyStream_When_EmptyArray()
    {
        var sourceData = new SourceData(JsonTestDataHelper.EmptyArray(), "empty.json", "json");
        var parsed     = await CreateSut().ParseAsync(sourceData, CancellationToken.None);
        var elements   = new List<JsonElement>();

        await foreach (var el in parsed.Elements) elements.Add(el);

        Assert.That(elements, Is.Empty);
    }

    /// <summary>Should_ThrowPipelineException_When_InvalidJson.</summary>
    [Test]
    public async Task Should_ThrowPipelineException_When_InvalidJson()
    {
        var sourceData = new SourceData(JsonTestDataHelper.InvalidJson(), "bad.json", "json");
        var parsed     = await CreateSut().ParseAsync(sourceData, CancellationToken.None);

        Assert.ThrowsAsync<AxbusPipelineException>(async () =>
        {
            await foreach (var _ in parsed.Elements) { }
        });
    }

    /// <summary>Should_DrillIntoKey_When_RootArrayKeyConfigured.</summary>
    [Test]
    public async Task Should_DrillIntoKey_When_RootArrayKeyConfigured()
    {
        var json       = "{\"items\":[{\"id\":1},{\"id\":2}]}";
        var sourceData = new SourceData(JsonTestDataHelper.ToStream(json), "test.json", "json");
        var parsed     = await CreateSut(rootArrayKey: "items").ParseAsync(sourceData, CancellationToken.None);
        var elements   = new List<JsonElement>();

        await foreach (var el in parsed.Elements) elements.Add(el);

        Assert.That(elements.Count, Is.EqualTo(2));
    }
}