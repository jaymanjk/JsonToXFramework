// <copyright file="CsvWriterOptionsValidatorTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Csv.Tests.Tests.Options;

using Axbus.Plugin.Writer.Csv.Options;
using Axbus.Plugin.Writer.Csv.Validators;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="CsvWriterOptionsValidator"/>.
/// </summary>
[TestFixture]
public sealed class CsvWriterOptionsValidatorTests : AxbusTestBase
{
    private CsvWriterOptionsValidator sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new CsvWriterOptionsValidator(); }

    /// <summary>Should_ReturnNoErrors_When_DefaultOptions.</summary>
    [Test]
    public void Should_ReturnNoErrors_When_DefaultOptions()
    {
        Assert.That(sut.Validate(new CsvWriterPluginOptions()).ToList(), Is.Empty);
    }

    /// <summary>Should_ReturnError_When_DelimiterIsNullChar.</summary>
    [Test]
    public void Should_ReturnError_When_DelimiterIsNullChar()
    {
        Assert.That(sut.Validate(new CsvWriterPluginOptions { Delimiter = '\0' }).ToList(), Is.Not.Empty);
    }

    /// <summary>Should_ReturnError_When_EncodingInvalid.</summary>
    [Test]
    public void Should_ReturnError_When_EncodingInvalid()
    {
        Assert.That(sut.Validate(new CsvWriterPluginOptions { Encoding = "NOT-VALID" }).ToList(), Is.Not.Empty);
    }
}