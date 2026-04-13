// <copyright file="JsonArrayExploder.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Reader.Json.Transformer;

using System.Text.Json;
using Axbus.Core.Models.Pipeline;

/// <summary>
/// Handles the explosion of nested JSON arrays into multiple
/// <see cref="FlattenedRow"/> instances. When a JSON property value is an array
/// each element of the array generates a new row with the parent field values
/// repeated. Arrays nested beyond <c>maxDepth</c> are serialised as a JSON
/// string rather than being exploded further.
/// </summary>
internal static class JsonArrayExploder
{
    /// <summary>
    /// Explodes a <see cref="JsonElement"/> that may contain nested arrays
    /// into one or more <see cref="FlattenedRow"/> instances. Non-array values
    /// are returned as a single row. Arrays are exploded up to
    /// <paramref name="maxDepth"/> levels deep.
    /// </summary>
    /// <param name="element">The JSON element to explode.</param>
    /// <param name="parentValues">
    /// Key-value pairs from ancestor elements to repeat on every exploded row.
    /// </param>
    /// <param name="prefix">The dot-notation prefix for field names at this level.</param>
    /// <param name="maxDepth">The maximum explosion depth. Beyond this arrays become JSON strings.</param>
    /// <param name="currentDepth">The current recursion depth (starts at 0).</param>
    /// <param name="sourcePath">The source file path for row metadata.</param>
    /// <param name="rowNumber">The base row number for metadata.</param>
    /// <param name="nullPlaceholder">The value to use for null or missing fields.</param>
    /// <returns>One or more flattened rows produced by explosion.</returns>
    internal static IEnumerable<FlattenedRow> Explode(
        JsonElement element,
        Dictionary<string, string> parentValues,
        string prefix,
        int maxDepth,
        int currentDepth,
        string sourcePath,
        int rowNumber,
        string nullPlaceholder)
    {
        if (element.ValueKind != JsonValueKind.Object)
        {
            // Non-object: create a single row with parent values
            var simpleRow = new FlattenedRow
            {
                RowNumber = rowNumber,
                SourceFilePath = sourcePath,
            };

            foreach (var kvp in parentValues)
            {
                simpleRow.Values[kvp.Key] = kvp.Value;
            }

            if (!string.IsNullOrEmpty(prefix))
            {
                simpleRow.Values[prefix] = GetScalarValue(element, nullPlaceholder);
            }

            yield return simpleRow;
            yield break;
        }

        // Collect scalar fields and identify array fields at this level
        var scalarValues = new Dictionary<string, string>(parentValues, StringComparer.OrdinalIgnoreCase);
        var arrayFields = new List<(string Key, JsonElement ArrayElement)>();

        foreach (var property in element.EnumerateObject())
        {
            var fieldKey = string.IsNullOrEmpty(prefix)
                ? property.Name
                : $"{prefix}.{property.Name}";

            if (property.Value.ValueKind == JsonValueKind.Array && currentDepth < maxDepth)
            {
                // This array will be exploded
                arrayFields.Add((fieldKey, property.Value));
            }
            else if (property.Value.ValueKind == JsonValueKind.Object)
            {
                // Recurse into nested objects to flatten with dot-notation
                FlattenObject(property.Value, fieldKey, scalarValues, maxDepth, currentDepth + 1, nullPlaceholder);
            }
            else
            {
                // Scalar value or array beyond max depth
                scalarValues[fieldKey] = property.Value.ValueKind == JsonValueKind.Array
                    ? property.Value.GetRawText() // Serialize array as JSON string
                    : GetScalarValue(property.Value, nullPlaceholder);
            }
        }

        if (arrayFields.Count == 0)
        {
            // No arrays to explode - yield a single row
            var row = new FlattenedRow
            {
                RowNumber = rowNumber,
                SourceFilePath = sourcePath,
            };

            foreach (var kvp in scalarValues)
            {
                row.Values[kvp.Key] = kvp.Value;
            }

            yield return row;
        }
        else
        {
            // Explode each array field into multiple rows
            // For multiple array fields use the first array as the primary explosion axis
            var (primaryKey, primaryArray) = arrayFields[0];
            var explosionIndex = 0;

            foreach (var arrayItem in primaryArray.EnumerateArray())
            {
                foreach (var explodedRow in Explode(
                    arrayItem,
                    scalarValues,
                    primaryKey,
                    maxDepth,
                    currentDepth + 1,
                    sourcePath,
                    rowNumber,
                    nullPlaceholder))
                {
                    explodedRow.IsExploded = true;
                    explodedRow.ExplosionIndex = explosionIndex;
                    yield return explodedRow;
                }

                explosionIndex++;
            }
        }
    }

    /// <summary>
    /// Recursively flattens a nested JSON object into the scalar values dictionary
    /// using dot-notation keys.
    /// </summary>
    /// <param name="element">The nested object element to flatten.</param>
    /// <param name="prefix">The dot-notation prefix for all fields in this object.</param>
    /// <param name="target">The dictionary to populate with flattened key-value pairs.</param>
    /// <param name="maxDepth">Maximum explosion depth for nested arrays.</param>
    /// <param name="currentDepth">Current recursion depth.</param>
    /// <param name="nullPlaceholder">Value for null or missing fields.</param>
    private static void FlattenObject(
        JsonElement element,
        string prefix,
        Dictionary<string, string> target,
        int maxDepth,
        int currentDepth,
        string nullPlaceholder)
    {
        foreach (var property in element.EnumerateObject())
        {
            var fieldKey = $"{prefix}.{property.Name}";

            if (property.Value.ValueKind == JsonValueKind.Object)
            {
                FlattenObject(property.Value, fieldKey, target, maxDepth, currentDepth + 1, nullPlaceholder);
            }
            else if (property.Value.ValueKind == JsonValueKind.Array && currentDepth >= maxDepth)
            {
                // Beyond max depth - serialize as JSON string
                target[fieldKey] = property.Value.GetRawText();
            }
            else
            {
                target[fieldKey] = GetScalarValue(property.Value, nullPlaceholder);
            }
        }
    }

    /// <summary>
    /// Converts a scalar <see cref="JsonElement"/> to its string representation.
    /// </summary>
    /// <param name="element">The JSON element to convert.</param>
    /// <param name="nullPlaceholder">The value to return for null elements.</param>
    /// <returns>The string representation of the element value.</returns>
    private static string GetScalarValue(JsonElement element, string nullPlaceholder)
    {
        return element.ValueKind switch
        {
            JsonValueKind.String => element.GetString() ?? nullPlaceholder,
            JsonValueKind.Number => element.GetRawText(),
            JsonValueKind.True   => "true",
            JsonValueKind.False  => "false",
            JsonValueKind.Null   => nullPlaceholder,
            _                    => element.GetRawText(),
        };
    }
}