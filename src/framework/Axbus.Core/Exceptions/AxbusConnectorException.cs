// <copyright file="AxbusConnectorException.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Exceptions;

/// <summary>
/// Represents an error that occurs within an Axbus source or target connector.
/// Connector exceptions are typically caused by file system access failures,
/// network errors, or permission issues when reading from or writing to
/// a data source or target.
/// </summary>
public sealed class AxbusConnectorException : Exception
{
    /// <summary>
    /// Gets the path or URI of the resource that caused the exception, if known.
    /// </summary>
    public string? ResourcePath { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusConnectorException"/>
    /// with a specified error message.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    public AxbusConnectorException(string message)
        : base(message)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusConnectorException"/>
    /// with a specified error message and a reference to the inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="innerException">The exception that caused this exception.</param>
    public AxbusConnectorException(string message, Exception innerException)
        : base(message, innerException)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusConnectorException"/>
    /// with a specified error message, the resource path, and an optional inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="resourcePath">The path or URI of the resource that caused the exception.</param>
    /// <param name="innerException">The exception that caused this exception, or null.</param>
    public AxbusConnectorException(string message, string resourcePath, Exception? innerException = null)
        : base(message, innerException)
    {
        ResourcePath = resourcePath;
    }
}