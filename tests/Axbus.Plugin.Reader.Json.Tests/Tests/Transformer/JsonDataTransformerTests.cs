// <copyright file="JsonDataTransformerTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Tests.Tests.Transformer;

using Axbus.Core.Models.Configuration;
using Axbus.Core.Models.Pipeline;
using Axbus.Plugin.Reader.Json.Options;
using Axbus.Plugin.Reader.Json.Parser;
using Axbus.Plugin.Reader.Json.Transformer;
using Axbus.Tests.Common.Assertions;
using Axbus.Tests.Common.Base;
using Axbus.Tests.Common.Helpers;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="JsonDataTransformer"/>.
/// </summary>
[TestFixture]
public sealed class JsonDataTransformerTests : AxbusTestBase
{
    private JsonFormatParser    parser      = null!;
    private JsonDataTransformer transformer = null!;

    /// <inheritdoc/>
    public override void SetUp()
    {
        base.SetUp();
        var opts    = new JsonReaderPluginOptions { MaxExplosionDepth = 3 };
        parser      = new JsonFormatParser(NullLogger<JsonFormatParser>(), opts);
        transformer = new JsonDataTransformer(NullLogger<JsonDataTransformer>(), opts);
    }

    /// <summary>Should_ProduceFlatRows_When_JsonIsFlatArray.</summary>
    [Test]
    public async Task Should_ProduceFlatRows_When_JsonIsFlatArray()
    {
        var sd   = new SourceData(JsonTestDataHelper.FlatArray(3), "flat.json", "json");
        var pd   = await parser.ParseAsync(sd, CancellationToken.None);
        var td   = await transformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var rows = await FlattenedRowAssertions.CollectAsync(td.Rows);

        FlattenedRowAssertions.HasCount(rows, 3);
        FlattenedRowAssertions.AllHaveColumn(rows, "id");
    }

    /// <summary>Should_UseDotNotation_When_JsonHasNestedObjects.</summary>
    [Test]
    public async Task Should_UseDotNotation_When_JsonHasNestedObjects()
    {
        var sd   = new SourceData(JsonTestDataHelper.NestedArray(1), "nested.json", "json");
        var pd   = await parser.ParseAsync(sd, CancellationToken.None);
        var td   = await transformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var rows = await FlattenedRowAssertions.CollectAsync(td.Rows);

        FlattenedRowAssertions.HasCount(rows, 1);
        FlattenedRowAssertions.AllHaveColumn(rows, "customer.address.city");
    }

    /// <summary>Should_ExplodeArray_When_NestedArrayPresent.</summary>
    [Test]
    public async Task Should_ExplodeArray_When_NestedArrayPresent()
    {
        var sd   = new SourceData(JsonTestDataHelper.ArrayForExplosion(3), "arr.json", "json");
        var pd   = await parser.ParseAsync(sd, CancellationToken.None);
        var td   = await transformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var rows = await FlattenedRowAssertions.CollectAsync(td.Rows);

        Assert.That(rows.Count,                Is.EqualTo(3));
        Assert.That(rows.All(r => r.IsExploded), Is.True);
    }

    /// <summary>Should_ProduceNoRows_When_EmptyArray.</summary>
    [Test]
    public async Task Should_ProduceNoRows_When_EmptyArray()
    {
        var sd   = new SourceData(JsonTestDataHelper.EmptyArray(), "empty.json", "json");
        var pd   = await parser.ParseAsync(sd, CancellationToken.None);
        var td   = await transformer.TransformAsync(pd, new PipelineOptions(), CancellationToken.None);
        var rows = await FlattenedRowAssertions.CollectAsync(td.Rows);

        Assert.That(rows, Is.Empty);
    }
}