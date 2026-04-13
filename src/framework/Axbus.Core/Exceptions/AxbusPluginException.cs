// <copyright file="AxbusPluginException.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Core.Exceptions;

/// <summary>
/// Represents an error that occurs during plugin loading, initialisation,
/// registration or resolution within the Axbus plugin system.
/// </summary>
public sealed class AxbusPluginException : Exception
{
    /// <summary>
    /// Gets the identifier of the plugin that caused the exception, if known.
    /// </summary>
    public string? PluginId { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusPluginException"/>
    /// with a specified error message.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    public AxbusPluginException(string message)
        : base(message)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusPluginException"/>
    /// with a specified error message and a reference to the inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="innerException">The exception that caused this exception.</param>
    public AxbusPluginException(string message, Exception innerException)
        : base(message, innerException)
    {
    }

    /// <summary>
    /// Initializes a new instance of <see cref="AxbusPluginException"/>
    /// with a specified error message, the plugin identifier, and an optional inner exception.
    /// </summary>
    /// <param name="message">The message that describes the error.</param>
    /// <param name="pluginId">The identifier of the plugin that caused the exception.</param>
    /// <param name="innerException">The exception that caused this exception, or null.</param>
    public AxbusPluginException(string message, string pluginId, Exception? innerException = null)
        : base(message, innerException)
    {
        PluginId = pluginId;
    }
}