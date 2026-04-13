// <copyright file="ProgressForm.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.Forms;

using Axbus.Core.Abstractions.Conversion;
using Axbus.Core.Abstractions.Notifications;
using Axbus.Core.Models.Notifications;
using Axbus.Core.Models.Results;
using Axbus.WinFormsApp.ViewModels;
using Microsoft.Extensions.Logging;

/// <summary>
/// Displays real-time conversion progress including a progress bar,
/// current module status, current file name and a live event log.
/// Runs the conversion asynchronously and allows the user to cancel
/// via a Cancel button. Shows the <see cref="SummaryForm"/> on completion.
/// </summary>
public sealed class ProgressForm : Form
{
    /// <summary>Logger for progress form diagnostic output.</summary>
    private readonly ILogger<ProgressForm> logger;

    /// <summary>The conversion runner that executes all modules.</summary>
    private readonly IConversionRunner conversionRunner;

    /// <summary>The event publisher for subscribing to lifecycle events.</summary>
    private readonly IEventPublisher eventPublisher;

    /// <summary>The factory used to create the summary form on completion.</summary>
    private readonly Bootstrapper.FormFactory formFactory;

    /// <summary>View model tracking current progress state.</summary>
    private readonly ProgressViewModel progressViewModel = new();

    /// <summary>Cancellation token source wired to the Cancel button.</summary>
    private CancellationTokenSource cancellationTokenSource = new();

    // Controls
    private ProgressBar progressBar = null!;
    private Label labelStatus = null!;
    private Label labelCurrentFile = null!;
    private Label labelFileProgress = null!;
    private ListBox listBoxEvents = null!;
    private Button buttonCancel = null!;

    /// <summary>
    /// Initializes a new instance of <see cref="ProgressForm"/>.
    /// </summary>
    /// <param name="logger">The logger for form operations.</param>
    /// <param name="conversionRunner">The conversion runner to execute.</param>
    /// <param name="eventPublisher">The event publisher for live event log.</param>
    /// <param name="formFactory">Factory for creating the summary form.</param>
    public ProgressForm(
        ILogger<ProgressForm> logger,
        IConversionRunner conversionRunner,
        IEventPublisher eventPublisher,
        Bootstrapper.FormFactory formFactory)
    {
        this.logger = logger;
        this.conversionRunner = conversionRunner;
        this.eventPublisher = eventPublisher;
        this.formFactory = formFactory;

        InitialiseComponents();
    }

    /// <summary>
    /// Initialises all WinForms controls and wires up event handlers.
    /// </summary>
    private void InitialiseComponents()
    {
        Text = "Axbus - Conversion Progress";
        Size = new Size(800, 500);
        StartPosition = FormStartPosition.CenterScreen;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;

        // Status label
        labelStatus = new Label
        {
            Location = new Point(12, 12),
            Size = new Size(760, 20),
            Text = "Initialising...",
            Font = new Font("Segoe UI", 9f, FontStyle.Bold),
        };

        // Progress bar
        progressBar = new ProgressBar
        {
            Location = new Point(12, 40),
            Size = new Size(760, 23),
            Minimum = 0,
            Maximum = 100,
            Style = ProgressBarStyle.Continuous,
        };

        // File progress label
        labelFileProgress = new Label
        {
            Location = new Point(12, 70),
            Size = new Size(300, 18),
            Text = "Files: 0 / 0",
        };

        // Current file label
        labelCurrentFile = new Label
        {
            Location = new Point(12, 90),
            Size = new Size(760, 18),
            Text = string.Empty,
            ForeColor = Color.DimGray,
        };

        // Event log list
        listBoxEvents = new ListBox
        {
            Location = new Point(12, 118),
            Size = new Size(760, 300),
            Font = new Font("Consolas", 8.5f),
            HorizontalScrollbar = true,
            SelectionMode = SelectionMode.None,
        };

        // Cancel button
        buttonCancel = new Button
        {
            Location = new Point(697, 430),
            Size = new Size(75, 28),
            Text = "Cancel",
            DialogResult = DialogResult.Cancel,
        };
        buttonCancel.Click += OnCancelClicked;

        Controls.AddRange(new Control[]
        {
            labelStatus, progressBar, labelFileProgress,
            labelCurrentFile, listBoxEvents, buttonCancel,
        });

        Shown += OnFormShown;
    }

    /// <summary>
    /// Starts the conversion run when the form is first shown.
    /// </summary>
    private async void OnFormShown(object? sender, EventArgs e)
    {
        await RunConversionAsync().ConfigureAwait(false);
    }

    /// <summary>
    /// Executes the conversion runner, updating the UI via progress and event callbacks.
    /// </summary>
    private async Task RunConversionAsync()
    {
        cancellationTokenSource = new CancellationTokenSource();

        // Subscribe to event stream - marshal to UI thread
        var subscription = eventPublisher.Events.Subscribe(evt =>
        {
            if (InvokeRequired)
            {
                Invoke(() => AppendEvent(evt));
            }
            else
            {
                AppendEvent(evt);
            }
        });

        // Wire up progress reporter - marshals to UI thread via Progress<T>
        var progress = new Progress<ConversionProgress>(p =>
        {
            progressViewModel.UpdateFrom(p);
            progressBar.Value = progressViewModel.PercentComplete;
            labelStatus.Text = progressViewModel.StatusDisplay;
            labelCurrentFile.Text = progressViewModel.CurrentFile;
            labelFileProgress.Text = progressViewModel.FileProgressDisplay;
        });

        ConversionSummary? summary = null;

        try
        {
            summary = await conversionRunner.RunAsync(progress, cancellationTokenSource.Token)
                .ConfigureAwait(true); // ConfigureAwait(true) to return to UI thread
        }
        catch (OperationCanceledException)
        {
            labelStatus.Text = "Conversion cancelled.";
            logger.LogWarning("Conversion cancelled by user via ProgressForm.");
        }
        catch (Exception ex)
        {
            labelStatus.Text = "Conversion failed. See log for details.";
            logger.LogError(ex, "Conversion failed in ProgressForm.");
            MessageBox.Show(
                $"Conversion failed:\n{ex.Message}",
                "Axbus - Error",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
        finally
        {
            subscription.Dispose();
            buttonCancel.Text = "Close";
        }

        // Show summary form if conversion completed
        if (summary != null)
        {
            var summaryForm = formFactory.Create<SummaryForm>();
            summaryForm.SetSummary(summary);
            Hide();
            summaryForm.ShowDialog(Owner);
            Close();
        }
    }

    /// <summary>
    /// Appends a conversion event to the live event log list box.
    /// </summary>
    /// <param name="evt">The conversion event to append.</param>
    private void AppendEvent(ConversionEvent evt)
    {
        var entry = $"[{evt.Timestamp:HH:mm:ss}] {evt.Type,-25} {evt.ModuleName} | {evt.Message}";
        listBoxEvents.Items.Add(entry);

        // Auto-scroll to latest entry
        if (listBoxEvents.Items.Count > 0)
        {
            listBoxEvents.TopIndex = listBoxEvents.Items.Count - 1;
        }
    }

    /// <summary>
    /// Cancels the running conversion when the Cancel button is clicked.
    /// </summary>
    private void OnCancelClicked(object? sender, EventArgs e)
    {
        if (!cancellationTokenSource.IsCancellationRequested)
        {
            cancellationTokenSource.Cancel();
            buttonCancel.Enabled = false;
            labelStatus.Text = "Cancelling...";
        }
        else
        {
            Close();
        }
    }
}