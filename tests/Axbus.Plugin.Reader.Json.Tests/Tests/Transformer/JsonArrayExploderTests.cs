// <copyright file="JsonArrayExploderTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Tests.Tests.Transformer;

using System.Text.Json;
using Axbus.Tests.Common.Assertions;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="Axbus.Plugin.Reader.Json.Transformer.JsonArrayExploder"/>.
/// </summary>
[TestFixture]
public sealed class JsonArrayExploderTests : AxbusTestBase
{
    /// <summary>Should_ProduceSingleRow_When_NoArraysPresent.</summary>
    [Test]
    public void Should_ProduceSingleRow_When_NoArraysPresent()
    {
        var element = JsonDocument.Parse("{\"id\":\"1\",\"name\":\"Test\"}").RootElement;
        var rows    = Axbus.Plugin.Reader.Json.Transformer.JsonArrayExploder.Explode(
            element, new Dictionary<string, string>(), string.Empty, 3, 0, "t.json", 1, string.Empty).ToList();

        Assert.That(rows.Count, Is.EqualTo(1));
        FlattenedRowAssertions.HasValue(rows[0], "id",   "1");
        FlattenedRowAssertions.HasValue(rows[0], "name", "Test");
    }

    /// <summary>Should_FlattenNestedObject_When_DotNotationApplied.</summary>
    [Test]
    public void Should_FlattenNestedObject_When_DotNotationApplied()
    {
        var element = JsonDocument.Parse("{\"customer\":{\"name\":\"Acme\",\"city\":\"Stockholm\"}}").RootElement;
        var rows    = Axbus.Plugin.Reader.Json.Transformer.JsonArrayExploder.Explode(
            element, new Dictionary<string, string>(), string.Empty, 3, 0, "t.json", 1, string.Empty).ToList();

        Assert.That(rows.Count, Is.EqualTo(1));
        FlattenedRowAssertions.HasValue(rows[0], "customer.name", "Acme");
        FlattenedRowAssertions.HasValue(rows[0], "customer.city", "Stockholm");
    }

    /// <summary>Should_ExplodeArray_When_NestedArrayPresent.</summary>
    [Test]
    public void Should_ExplodeArray_When_NestedArrayPresent()
    {
        var element = JsonDocument.Parse("{\"id\":\"O1\",\"lines\":[{\"sku\":\"A\"},{\"sku\":\"B\"}]}").RootElement;
        var rows    = Axbus.Plugin.Reader.Json.Transformer.JsonArrayExploder.Explode(
            element, new Dictionary<string, string>(), string.Empty, 3, 0, "t.json", 1, string.Empty).ToList();

        Assert.That(rows.Count,              Is.EqualTo(2));
        Assert.That(rows.All(r => r.IsExploded), Is.True);
    }
}