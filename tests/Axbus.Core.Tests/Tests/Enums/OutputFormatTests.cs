// <copyright file="OutputFormatTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Enums;

using Axbus.Core.Enums;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for the <see cref="OutputFormat"/> flags enumeration.
/// </summary>
[TestFixture]
public sealed class OutputFormatTests : AxbusTestBase
{
    /// <summary>Should_HaveNoneAsZeroValue_When_EnumIsInspected.</summary>
    [Test]
    public void Should_HaveNoneAsZeroValue_When_EnumIsInspected()
    {
        Assert.That((int)OutputFormat.None, Is.EqualTo(0));
    }

    /// <summary>Should_SupportFlagCombination_When_MultipleFormatsSelected.</summary>
    [Test]
    public void Should_SupportFlagCombination_When_MultipleFormatsSelected()
    {
        var combined = OutputFormat.Csv | OutputFormat.Excel;

        Assert.That(combined.HasFlag(OutputFormat.Csv),   Is.True);
        Assert.That(combined.HasFlag(OutputFormat.Excel), Is.True);
        Assert.That(combined.HasFlag(OutputFormat.Text),  Is.False);
    }

    /// <summary>Should_ReturnDistinctBitValues_When_EnumValuesCompared.</summary>
    [Test]
    public void Should_ReturnDistinctBitValues_When_EnumValuesCompared()
    {
        Assert.That((int)OutputFormat.Csv,   Is.EqualTo(1));
        Assert.That((int)OutputFormat.Excel, Is.EqualTo(2));
        Assert.That((int)OutputFormat.Text,  Is.EqualTo(4));
    }
}