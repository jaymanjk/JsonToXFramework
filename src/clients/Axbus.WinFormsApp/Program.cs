// <copyright file="Program.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

using Axbus.WinFormsApp.Bootstrapper;
using Axbus.WinFormsApp.Forms;
using Serilog;

// Enable per-monitor DPI awareness for sharp rendering on high-DPI displays
Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
Application.EnableVisualStyles();
Application.SetCompatibleTextRenderingDefault(false);

// Bootstrap DI container - all wiring lives in AppBootstrapper
IServiceProvider? serviceProvider = null;

try
{
    serviceProvider = AppBootstrapper.Bootstrap();

    // Resolve FormFactory from DI and create the main form
    var formFactory = serviceProvider.GetService(typeof(FormFactory)) as FormFactory
        ?? throw new InvalidOperationException("FormFactory not registered.");

    var mainForm = formFactory.Create<MainForm>();

    // Run the WinForms message loop
    Application.Run(mainForm);
}
catch (Exception ex)
{
    Log.Fatal(ex, "Axbus WinFormsApp terminated unexpectedly.");
    MessageBox.Show(
        $"Axbus failed to start:\n\n{ex.Message}",
        "Axbus - Fatal Error",
        MessageBoxButtons.OK,
        MessageBoxIcon.Error);
}
finally
{
    // Dispose the service provider if it supports it
    if (serviceProvider is IDisposable disposable)
    {
        disposable.Dispose();
    }

    await Log.CloseAndFlushAsync();
}