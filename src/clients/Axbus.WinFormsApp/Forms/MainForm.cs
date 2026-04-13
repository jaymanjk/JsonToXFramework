// <copyright file="MainForm.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.Forms;

using Axbus.Core.Abstractions.Plugin;
using Axbus.Core.Models.Configuration;
using Axbus.WinFormsApp.Bootstrapper;
using Axbus.WinFormsApp.ViewModels;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

/// <summary>
/// The main application form. Displays the list of configured conversion modules,
/// shows loaded plugin information, and provides Start and Exit buttons.
/// Clicking Start launches the <see cref="ProgressForm"/> which runs the conversion.
/// </summary>
public sealed class MainForm : Form
{
    /// <summary>Logger for main form operations.</summary>
    private readonly ILogger<MainForm> logger;

    /// <summary>Axbus root settings containing the module list.</summary>
    private readonly AxbusRootSettings settings;

    /// <summary>All registered plugins for the plugin info panel.</summary>
    private readonly IEnumerable<IPlugin> plugins;

    /// <summary>Factory for creating child forms via DI.</summary>
    private readonly FormFactory formFactory;

    // Controls
    private DataGridView gridModules = null!;
    private ListBox listBoxPlugins = null!;
    private Button buttonStart = null!;
    private Button buttonExit = null!;
    private Label labelModules = null!;
    private Label labelPlugins = null!;
    private StatusStrip statusStrip = null!;
    private ToolStripStatusLabel statusLabel = null!;

    /// <summary>
    /// Initializes a new instance of <see cref="MainForm"/>.
    /// </summary>
    /// <param name="logger">The logger for form operations.</param>
    /// <param name="options">Root Axbus settings.</param>
    /// <param name="plugins">All registered plugins.</param>
    /// <param name="formFactory">DI-aware form factory.</param>
    public MainForm(
        ILogger<MainForm> logger,
        IOptions<AxbusRootSettings> options,
        IEnumerable<IPlugin> plugins,
        FormFactory formFactory)
    {
        this.logger = logger;
        this.settings = options.Value;
        this.plugins = plugins;
        this.formFactory = formFactory;

        InitialiseComponents();
        PopulateModuleGrid();
        PopulatePluginList();
    }

    /// <summary>Initialises all WinForms controls and layout.</summary>
    private void InitialiseComponents()
    {
        Text = "Axbus Framework - Data Conversion Tool";
        Size = new Size(1000, 620);
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(900, 560);

        labelModules = new Label
        {
            Text = "Conversion Modules",
            Location = new Point(12, 10),
            Size = new Size(640, 18),
            Font = new Font("Segoe UI", 9f, FontStyle.Bold),
        };

        gridModules = new DataGridView
        {
            Location = new Point(12, 30),
            Size = new Size(640, 500),
            ReadOnly = true,
            AllowUserToAddRows = false,
            AllowUserToDeleteRows = false,
            SelectionMode = DataGridViewSelectionMode.FullRowSelect,
            AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
            RowHeadersVisible = false,
            BackgroundColor = Color.White,
            Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Bottom,
        };

        labelPlugins = new Label
        {
            Text = "Loaded Plugins",
            Location = new Point(665, 10),
            Size = new Size(300, 18),
            Font = new Font("Segoe UI", 9f, FontStyle.Bold),
        };

        listBoxPlugins = new ListBox
        {
            Location = new Point(665, 30),
            Size = new Size(300, 200),
            Font = new Font("Consolas", 8.5f),
        };

        buttonStart = new Button
        {
            Location = new Point(665, 250),
            Size = new Size(140, 35),
            Text = "Start Conversion",
            Font = new Font("Segoe UI", 9f, FontStyle.Bold),
            BackColor = Color.FromArgb(0, 120, 212),
            ForeColor = Color.White,
            FlatStyle = FlatStyle.Flat,
        };
        buttonStart.Click += OnStartClicked;

        buttonExit = new Button
        {
            Location = new Point(825, 250),
            Size = new Size(140, 35),
            Text = "Exit",
            Font = new Font("Segoe UI", 9f),
        };
        buttonExit.Click += (_, _) => Close();

        statusStrip = new StatusStrip();
        statusLabel = new ToolStripStatusLabel("Ready");
        statusStrip.Items.Add(statusLabel);

        Controls.AddRange(new Control[]
        {
            labelModules, gridModules,
            labelPlugins, listBoxPlugins,
            buttonStart, buttonExit,
            statusStrip,
        });
    }

    /// <summary>Populates the module grid from the settings.</summary>
    private void PopulateModuleGrid()
    {
        var viewModels = settings.ConversionModules
            .Select(m => new ConversionModuleViewModel(m))
            .ToList();

        gridModules.DataSource = viewModels
            .Select(vm => new
            {
                vm.ConversionName,
                vm.Description,
                Enabled = vm.IsEnabled ? "Yes" : "No",
                Source = vm.SourceFormat,
                Target = vm.TargetFormat,
                vm.StatusDisplay,
            })
            .ToList();

        gridModules.AutoResizeColumns();

        statusLabel.Text = $"Ready - {viewModels.Count} module(s) configured | " +
                           $"{viewModels.Count(v => v.IsEnabled)} enabled";
    }

    /// <summary>Populates the plugin list from registered plugins.</summary>
    private void PopulatePluginList()
    {
        foreach (var plugin in plugins)
        {
            listBoxPlugins.Items.Add($"{plugin.Name} v{plugin.Version}");
        }
    }

    /// <summary>Launches the progress form when Start is clicked.</summary>
    private void OnStartClicked(object? sender, EventArgs e)
    {
        logger.LogInformation("Conversion started from MainForm.");
        buttonStart.Enabled = false;
        statusLabel.Text = "Conversion running...";

        try
        {
            var progressForm = formFactory.Create<ProgressForm>();
            progressForm.Owner = this;
            progressForm.FormClosed += (_, _) =>
            {
                buttonStart.Enabled = true;
                statusLabel.Text = "Ready";
                PopulateModuleGrid();
            };
            progressForm.Show(this);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to open ProgressForm.");
            buttonStart.Enabled = true;
            statusLabel.Text = "Error - see log";
            MessageBox.Show(
                $"Failed to start conversion:\n{ex.Message}",
                "Axbus - Error",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
    }
}