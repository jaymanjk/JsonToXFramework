// <copyright file="ValidationResultTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Models;

using Axbus.Core.Models.Pipeline;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="ValidationResult"/>.
/// </summary>
[TestFixture]
public sealed class ValidationResultTests : AxbusTestBase
{
    /// <summary>Should_HaveIsValidTrue_When_SuccessFactoryUsed.</summary>
    [Test]
    public void Should_HaveIsValidTrue_When_SuccessFactoryUsed()
    {
        var result = ValidationResult.Success;

        Assert.That(result.IsValid,      Is.True);
        Assert.That(result.Errors.Count, Is.EqualTo(0));
    }

    /// <summary>Should_HaveIsValidFalse_When_FailFactoryUsedWithMessages.</summary>
    [Test]
    public void Should_HaveIsValidFalse_When_FailFactoryUsedWithMessages()
    {
        var result = ValidationResult.Fail("Field is required.", "Value out of range.");

        Assert.That(result.IsValid,      Is.False);
        Assert.That(result.Errors.Count, Is.EqualTo(2));
        Assert.That(result.Errors[0],    Is.EqualTo("Field is required."));
    }

    /// <summary>Should_ReturnSameInstance_When_SuccessPropertyAccessedTwice.</summary>
    [Test]
    public void Should_ReturnSameInstance_When_SuccessPropertyAccessedTwice()
    {
        Assert.That(ReferenceEquals(ValidationResult.Success, ValidationResult.Success), Is.True);
    }
}