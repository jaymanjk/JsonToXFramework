// <copyright file="JsonTestDataHelper.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Tests.Common.Helpers;

using System.Text;
using System.Text.Json;

/// <summary>
/// Provides helper methods for creating in-memory JSON test data streams.
/// Eliminates the need for physical test data files for simple unit test scenarios.
/// </summary>
public static class JsonTestDataHelper
{
    /// <summary>
    /// Converts a JSON string to a readable <see cref="MemoryStream"/> positioned at the start.
    /// </summary>
    /// <param name="json">The JSON string to convert.</param>
    /// <returns>A <see cref="MemoryStream"/> containing the UTF-8 encoded JSON bytes.</returns>
    public static MemoryStream ToStream(string json)
    {
        var bytes = Encoding.UTF8.GetBytes(json);
        return new MemoryStream(bytes);
    }

    /// <summary>
    /// Creates a stream containing a flat JSON array with the specified number of objects.
    /// Each object has <c>id</c>, <c>name</c> and <c>value</c> fields.
    /// </summary>
    /// <param name="count">Number of objects in the array. Defaults to 3.</param>
    /// <returns>A <see cref="MemoryStream"/> containing the JSON array.</returns>
    public static MemoryStream FlatArray(int count = 3)
    {
        var items = Enumerable.Range(1, count).Select(i => new
        {
            id    = i.ToString(),
            name  = $"Item {i}",
            value = i * 10,
        });

        return ToStream(JsonSerializer.Serialize(items));
    }

    /// <summary>
    /// Creates a stream containing a JSON array with nested customer/address objects.
    /// </summary>
    /// <param name="count">Number of objects. Defaults to 2.</param>
    /// <returns>A <see cref="MemoryStream"/> containing the nested JSON array.</returns>
    public static MemoryStream NestedArray(int count = 2)
    {
        var items = Enumerable.Range(1, count).Select(i => new
        {
            id   = i.ToString(),
            type = "Order",
            customer = new
            {
                name    = $"Customer {i}",
                address = new { city = "Stockholm", country = "Sweden" },
            },
        });

        return ToStream(JsonSerializer.Serialize(items));
    }

    /// <summary>
    /// Creates a stream with a JSON array containing a nested array field
    /// suitable for testing array explosion behaviour.
    /// </summary>
    /// <param name="itemsPerArray">Items in the nested array. Defaults to 2.</param>
    /// <returns>A <see cref="MemoryStream"/> with explosion test JSON.</returns>
    public static MemoryStream ArrayForExplosion(int itemsPerArray = 2)
    {
        var items = new[]
        {
            new
            {
                orderId  = "ORD-001",
                customer = "Acme Corp",
                lines    = Enumerable.Range(1, itemsPerArray).Select(i => new
                {
                    lineNo = i,
                    sku    = $"SKU-{i:D3}",
                    qty    = i * 2,
                }).ToArray(),
            },
        };

        return ToStream(JsonSerializer.Serialize(items));
    }

    /// <summary>Creates a stream containing an empty JSON array <c>[]</c>.</summary>
    public static MemoryStream EmptyArray() => ToStream("[]");

    /// <summary>Creates a stream containing invalid JSON for error handling tests.</summary>
    public static MemoryStream InvalidJson() => ToStream("{ this is not valid json }");
}