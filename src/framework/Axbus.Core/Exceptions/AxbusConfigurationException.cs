// <copyright file="AxbusConfigurationException.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Exceptions;

/// <summary>
/// Represents an error caused by invalid or missing configuration within
/// the Axbus framework. This exception is thrown during application startup
/// or module initialisation when required configuration values are absent,
/// malformed or mutually inconsistent.
/// </summary>
public sealed class AxbusConfigurationException : Exception
{
    /// <summary>
    /// Gets the name of the configuration key or section that caused the exception, if known.
    /// </summary>
    public string? ConfigurationKey { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusConfigurationException"/>
    /// with a specified error message.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    public AxbusConfigurationException(string message)
        : base(message)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusConfigurationException"/>
    /// with a specified error message and a reference to the inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="innerException">The exception that caused this exception.</param>
    public AxbusConfigurationException(string message, Exception innerException)
        : base(message, innerException)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusConfigurationException"/>
    /// with a specified error message, the configuration key, and an optional inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="configurationKey">The name of the configuration key or section.</param>
    /// <param name="innerException">The exception that caused this exception, or null.</param>
    public AxbusConfigurationException(string message, string configurationKey, Exception? innerException = null)
        : base(message, innerException)
    {
        ConfigurationKey = configurationKey;
    }
}