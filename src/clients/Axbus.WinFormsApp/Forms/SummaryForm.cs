// <copyright file="SummaryForm.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.WinFormsApp.Forms;

using Axbus.Core.Models.Results;
using Axbus.WinFormsApp.ViewModels;

/// <summary>
/// Displays the final <see cref="ConversionSummary"/> after all modules
/// have completed. Shows aggregate statistics (total modules, rows written,
/// duration) and a per-module results grid with output file paths.
/// </summary>
public sealed class SummaryForm : Form
{
    // Aggregate stat labels
    private Label labelOverallStatus = null!;
    private Label labelTotalModules = null!;
    private Label labelSuccessful = null!;
    private Label labelFailed = null!;
    private Label labelTotalRows = null!;
    private Label labelErrorRows = null!;
    private Label labelDuration = null!;

    // Per-module results grid
    private DataGridView gridResults = null!;

    // Close button
    private Button buttonClose = null!;

    /// <summary>
    /// Initializes a new instance of <see cref="SummaryForm"/>.
    /// </summary>
    public SummaryForm()
    {
        InitialiseComponents();
    }

    /// <summary>
    /// Populates the form with data from the provided <see cref="ConversionSummary"/>.
    /// Call this before <see cref="Form.ShowDialog()"/>.
    /// </summary>
    /// <param name="summary">The conversion summary to display.</param>
    public void SetSummary(ConversionSummary summary)
    {
        ArgumentNullException.ThrowIfNull(summary);

        var vm = new ConversionSummaryViewModel(summary);

        labelOverallStatus.Text = vm.OverallStatus;
        labelOverallStatus.ForeColor = summary.FailedModules == 0 ? Color.DarkGreen : Color.DarkRed;
        labelTotalModules.Text = $"Total modules : {vm.TotalModules}";
        labelSuccessful.Text   = $"Successful    : {vm.SuccessfulModules}";
        labelFailed.Text       = $"Failed        : {vm.FailedModules}";
        labelTotalRows.Text    = $"Rows written  : {vm.TotalRowsWritten}";
        labelErrorRows.Text    = $"Error rows    : {vm.TotalErrorRows}";
        labelDuration.Text     = $"Duration      : {vm.TotalDuration}";

        // Bind per-module results to grid
        gridResults.DataSource = vm.ModuleResults
            .Select(r => new
            {
                r.ModuleName,
                r.Status,
                r.RowsWritten,
                r.ErrorRows,
                r.Duration,
                r.OutputPath,
            })
            .ToList();

        gridResults.AutoResizeColumns();
    }

    /// <summary>Initialises all WinForms controls.</summary>
    private void InitialiseComponents()
    {
        Text = "Axbus - Conversion Summary";
        Size = new Size(900, 520);
        StartPosition = FormStartPosition.CenterScreen;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;

        var panelStats = new Panel
        {
            Location = new Point(12, 12),
            Size = new Size(860, 130),
            BorderStyle = BorderStyle.FixedSingle,
        };

        labelOverallStatus = new Label
        {
            Location = new Point(6, 6),
            Size = new Size(840, 24),
            Font = new Font("Segoe UI", 11f, FontStyle.Bold),
            Text = "Completed",
        };

        var statFont = new Font("Consolas", 9f);

        labelTotalModules = new Label { Location = new Point(6, 35),  Size = new Size(280, 18), Font = statFont };
        labelSuccessful   = new Label { Location = new Point(6, 53),  Size = new Size(280, 18), Font = statFont };
        labelFailed       = new Label { Location = new Point(6, 71),  Size = new Size(280, 18), Font = statFont };
        labelTotalRows    = new Label { Location = new Point(300, 35), Size = new Size(280, 18), Font = statFont };
        labelErrorRows    = new Label { Location = new Point(300, 53), Size = new Size(280, 18), Font = statFont };
        labelDuration     = new Label { Location = new Point(300, 71), Size = new Size(280, 18), Font = statFont };

        panelStats.Controls.AddRange(new Control[]
        {
            labelOverallStatus, labelTotalModules, labelSuccessful, labelFailed,
            labelTotalRows, labelErrorRows, labelDuration,
        });

        gridResults = new DataGridView
        {
            Location = new Point(12, 155),
            Size = new Size(860, 290),
            ReadOnly = true,
            AllowUserToAddRows = false,
            AllowUserToDeleteRows = false,
            SelectionMode = DataGridViewSelectionMode.FullRowSelect,
            AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
            RowHeadersVisible = false,
            BackgroundColor = Color.White,
        };

        buttonClose = new Button
        {
            Location = new Point(797, 455),
            Size = new Size(75, 28),
            Text = "Close",
            DialogResult = DialogResult.OK,
        };

        Controls.AddRange(new Control[] { panelStats, gridResults, buttonClose });
        AcceptButton = buttonClose;
    }
}