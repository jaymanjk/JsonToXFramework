// <copyright file="FormFactory.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.Bootstrapper;

using Microsoft.Extensions.DependencyInjection;

/// <summary>
/// A DI-aware factory for creating WinForms <see cref="Form"/> instances.
/// Resolves form instances from the DI container so that all form
/// constructor dependencies are satisfied automatically. Use this factory
/// instead of <c>new FormName()</c> to ensure proper DI integration.
/// Register forms as transient services in <see cref="AppBootstrapper"/>.
/// </summary>
public sealed class FormFactory
{
    /// <summary>
    /// The DI service provider used to resolve form instances.
    /// </summary>
    private readonly IServiceProvider serviceProvider;

    /// <summary>
    /// Initializes a new instance of <see cref="FormFactory"/>.
    /// </summary>
    /// <param name="serviceProvider">The application service provider.</param>
    public FormFactory(IServiceProvider serviceProvider)
    {
        this.serviceProvider = serviceProvider;
    }

    /// <summary>
    /// Creates a new instance of <typeparamref name="TForm"/> by resolving it
    /// from the DI container. All constructor dependencies of the form are
    /// automatically satisfied by the container.
    /// </summary>
    /// <typeparam name="TForm">
    /// The type of form to create. Must be a <see cref="Form"/> subclass
    /// registered in the DI container.
    /// </typeparam>
    /// <returns>A new <typeparamref name="TForm"/> instance with all dependencies injected.</returns>
    /// <exception cref="InvalidOperationException">
    /// Thrown when <typeparamref name="TForm"/> is not registered in the DI container.
    /// </exception>
    public TForm Create<TForm>() where TForm : Form
    {
        return serviceProvider.GetRequiredService<TForm>();
    }
}