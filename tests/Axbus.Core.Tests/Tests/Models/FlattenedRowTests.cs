// <copyright file="FlattenedRowTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="FlattenedRow"/>.
/// </summary>
[TestFixture]
public sealed class FlattenedRowTests : AxbusTestBase
{
    /// <summary>Should_AllowCaseInsensitiveKeyLookup_When_ValuesAccessed.</summary>
    [Test]
    public void Should_AllowCaseInsensitiveKeyLookup_When_ValuesAccessed()
    {
        var row = new FlattenedRow();
        row.Values["CustomerId"] = "C001";

        Assert.That(row.Values.ContainsKey("customerid"), Is.True);
        Assert.That(row.Values["customerId"],              Is.EqualTo("C001"));
    }

    /// <summary>Should_DefaultIsExplodedToFalse_When_RowCreated.</summary>
    [Test]
    public void Should_DefaultIsExplodedToFalse_When_RowCreated()
    {
        Assert.That(new FlattenedRow().IsExploded, Is.False);
    }

    /// <summary>Should_StoreExplosionIndex_When_RowIsExploded.</summary>
    [Test]
    public void Should_StoreExplosionIndex_When_RowIsExploded()
    {
        var row = new FlattenedRow { IsExploded = true, ExplosionIndex = 3 };

        Assert.That(row.IsExploded,     Is.True);
        Assert.That(row.ExplosionIndex, Is.EqualTo(3));
    }

    /// <summary>Should_StoreMetadata_When_RowNumberAndPathSet.</summary>
    [Test]
    public void Should_StoreMetadata_When_RowNumberAndPathSet()
    {
        var row = new FlattenedRow { RowNumber = 42, SourceFilePath = @"C:\input\orders.json" };

        Assert.That(row.RowNumber,      Is.EqualTo(42));
        Assert.That(row.SourceFilePath, Is.EqualTo(@"C:\input\orders.json"));
    }
}