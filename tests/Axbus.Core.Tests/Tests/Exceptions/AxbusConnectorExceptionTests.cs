// <copyright file="AxbusConnectorExceptionTests.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Tests.Tests.Exceptions;

using Axbus.Core.Exceptions;
using Axbus.Tests.Common.Base;
using NUnit.Framework;

/// <summary>
/// Unit tests for <see cref="AxbusConnectorException"/>.
/// </summary>
[TestFixture]
public sealed class AxbusConnectorExceptionTests : AxbusTestBase
{
    /// <summary>Should_StoreMessage_When_CreatedWithMessage.</summary>
    [Test]
    public void Should_StoreMessage_When_CreatedWithMessage()
    {
        // Act
        var sut = new AxbusConnectorException("Connection failed");

        // Assert
        Assert.That(sut.Message, Is.EqualTo("Connection failed"));
    }

    /// <summary>Should_StoreInnerException_When_CreatedWithInner.</summary>
    [Test]
    public void Should_StoreInnerException_When_CreatedWithInner()
    {
        // Arrange
        var inner = new IOException("File not found");

        // Act
        var sut = new AxbusConnectorException("Connector error", inner);

        // Assert
        Assert.That(sut.Message, Is.EqualTo("Connector error"));
        Assert.That(sut.InnerException, Is.EqualTo(inner));
    }
}
