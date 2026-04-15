// <copyright file="AxbusTestBase.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Tests.Common.Base;

using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using NUnit.Framework;

/// <summary>
/// Base class for all Axbus unit and integration tests.
/// Provides a pre-configured DI service provider with logging,
/// a NullLogger factory for tests that do not need log output,
/// and helper properties for common test setup patterns.
/// All test classes in the Axbus test suite should inherit from this class.
/// </summary>
public abstract class AxbusTestBase
{
    /// <summary>
    /// Gets the DI service provider configured in <see cref="SetUp"/>.
    /// Rebuilt before each test to ensure test isolation.
    /// </summary>
    protected IServiceProvider Services { get; private set; } = null!;

    /// <summary>
    /// Gets a null logger factory that discards all log output.
    /// Use when a logger is required but log assertions are not needed.
    /// </summary>
    protected ILoggerFactory NullLoggerFactory { get; } =
        Microsoft.Extensions.Logging.Abstractions.NullLoggerFactory.Instance;

    /// <summary>
    /// Configures the DI service collection before each test.
    /// Override <see cref="ConfigureServices"/> to register additional services.
    /// </summary>
    [SetUp]
    public virtual void SetUp()
    {
        var services = new ServiceCollection();
        services.AddLogging(b => b.AddConsole().SetMinimumLevel(LogLevel.Debug));
        ConfigureServices(services);
        Services = services.BuildServiceProvider();
    }

    /// <summary>
    /// Tears down the service provider after each test.
    /// </summary>
    [TearDown]
    public virtual void TearDown()
    {
        if (Services is IDisposable disposable)
        {
            disposable.Dispose();
        }
    }

    /// <summary>
    /// Override to register additional services required by a test class.
    /// Called during <see cref="SetUp"/> before the provider is built.
    /// </summary>
    /// <param name="services">The service collection to register into.</param>
    protected virtual void ConfigureServices(IServiceCollection services)
    {
    }

    /// <summary>
    /// Creates a typed NullLogger for use in tests that need a logger
    /// but do not assert on log output.
    /// </summary>
    /// <typeparam name="T">The logger category type.</typeparam>
    /// <returns>A <see cref="ILogger{T}"/> that discards all output.</returns>
    protected static ILogger<T> NullLogger<T>() =>
        Microsoft.Extensions.Logging.Abstractions.NullLogger<T>.Instance;
}