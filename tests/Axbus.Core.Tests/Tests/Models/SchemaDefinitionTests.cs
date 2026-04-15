// <copyright file="SchemaDefinitionTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="SchemaDefinition"/>.
/// </summary>
[TestFixture]
public sealed class SchemaDefinitionTests : AxbusTestBase
{
    /// <summary>Should_PreserveColumnOrder_When_SchemaCreated.</summary>
    [Test]
    public void Should_PreserveColumnOrder_When_SchemaCreated()
    {
        var columns = new[] { "id", "name", "customer.city", "amount" };
        var schema  = new SchemaDefinition(columns, "csv", sourceFileCount: 2);

        Assert.That(schema.Columns.Count, Is.EqualTo(4));
        Assert.That(schema.Columns[0],    Is.EqualTo("id"));
        Assert.That(schema.Columns[2],    Is.EqualTo("customer.city"));
    }

    /// <summary>Should_StoreFormat_When_SchemaCreated.</summary>
    [Test]
    public void Should_StoreFormat_When_SchemaCreated()
    {
        var schema = new SchemaDefinition(new[] { "col1" }, "excel");
        Assert.That(schema.Format, Is.EqualTo("excel"));
    }

    /// <summary>Should_StoreSourceFileCount_When_SchemaCreated.</summary>
    [Test]
    public void Should_StoreSourceFileCount_When_SchemaCreated()
    {
        var schema = new SchemaDefinition(new[] { "col1" }, "csv", sourceFileCount: 5);
        Assert.That(schema.SourceFileCount, Is.EqualTo(5));
    }
}