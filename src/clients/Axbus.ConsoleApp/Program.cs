// <copyright file="Program.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

using Axbus.ConsoleApp.Bootstrapper;
using Microsoft.Extensions.Hosting;
using Serilog;

// Build and run the Axbus console host.
// All DI wiring, Serilog configuration and plugin registration
// is handled by AppBootstrapper.BuildHost().
// Maximum 15 lines - all complexity lives in AppBootstrapper.

try
{
    var host = AppBootstrapper.BuildHost(args);
    await host.RunAsync().ConfigureAwait(false);
}
catch (Exception ex)
{
    Log.Fatal(ex, "Axbus ConsoleApp terminated unexpectedly.");
}
finally
{
    await Log.CloseAndFlushAsync().ConfigureAwait(false);
}
