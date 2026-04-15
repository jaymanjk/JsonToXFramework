// <copyright file="ExcelWriterOptionsValidatorTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Plugin.Writer.Excel.Tests.Tests.Options;

using Axbus.Plugin.Writer.Excel.Options;
using Axbus.Plugin.Writer.Excel.Validators;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ExcelWriterOptionsValidator"/>.
/// </summary>
[TestFixture]
public sealed class ExcelWriterOptionsValidatorTests : AxbusTestBase
{
    private ExcelWriterOptionsValidator sut = null!;

    /// <inheritdoc/>
    public override void SetUp() { base.SetUp(); sut = new ExcelWriterOptionsValidator(); }

    /// <summary>Should_ReturnNoErrors_When_DefaultOptions.</summary>
    [Test]
    public void Should_ReturnNoErrors_When_DefaultOptions()
    {
        Assert.That(sut.Validate(new ExcelWriterPluginOptions()).ToList(), Is.Empty);
    }

    /// <summary>Should_ReturnError_When_SheetNameTooLong.</summary>
    [Test]
    public void Should_ReturnError_When_SheetNameTooLong()
    {
        Assert.That(sut.Validate(new ExcelWriterPluginOptions { SheetName = new string('A', 32) }).ToList(), Is.Not.Empty);
    }

    /// <summary>Should_ReturnError_When_SheetNameContainsForbiddenChar.</summary>
    [TestCase(":")] [TestCase("\\")] [TestCase("/")] [TestCase("?")]
    [TestCase("*")] [TestCase("[")] [TestCase("]")]
    public void Should_ReturnError_When_SheetNameContainsForbiddenChar(string ch)
    {
        Assert.That(sut.Validate(new ExcelWriterPluginOptions { SheetName = $"Sheet{ch}Name" }).ToList(), Is.Not.Empty);
    }

    /// <summary>Should_ReturnError_When_SheetNameEmpty.</summary>
    [Test]
    public void Should_ReturnError_When_SheetNameEmpty()
    {
        Assert.That(sut.Validate(new ExcelWriterPluginOptions { SheetName = "" }).ToList(), Is.Not.Empty);
    }
}