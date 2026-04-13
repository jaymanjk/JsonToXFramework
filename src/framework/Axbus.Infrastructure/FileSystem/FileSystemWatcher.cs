// <copyright file="FileSystemWatcher.cs" company="Axel Johnson International">
// Copyright (c) 2026 Axel Johnson International. All rights reserved.
// </copyright>

namespace Axbus.Infrastructure.FileSystem;

using Microsoft.Extensions.Logging;

/// <summary>
/// Event arguments for the <see cref="FileSystemWatcher.FileDetected"/> event.
/// Contains information about the newly detected file.
/// </summary>
public sealed class FileDetectedEventArgs : EventArgs
{
    /// <summary>
    /// Gets the full path of the detected file.
    /// </summary>
    public string FilePath { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="FileDetectedEventArgs"/>.
    /// </summary>
    /// <param name="filePath">The full path of the detected file.</param>
    public FileDetectedEventArgs(string filePath)
    {
        FilePath = filePath;
    }
}

/// <summary>
/// Watches a local file system folder for new files and raises events
/// when matching files are detected. This watcher is format-agnostic
/// and works with any file type. Useful for building file-drop conversion
/// workflows where files are processed as soon as they arrive.
/// Implements <see cref="IDisposable"/> - call <see cref="Dispose"/> to
/// stop watching and release resources.
/// </summary>
public sealed class FileSystemWatcher : IDisposable
{
    /// <summary>
    /// Logger instance for watcher diagnostic output.
    /// </summary>
    private readonly ILogger<FileSystemWatcher> logger;

    /// <summary>
    /// The underlying .NET file system watcher instance.
    /// </summary>
    private readonly System.IO.FileSystemWatcher watcher;

    /// <summary>
    /// Raised when a new file matching the configured pattern is detected.
    /// </summary>
    public event EventHandler<FileDetectedEventArgs>? FileDetected;

    /// <summary>
    /// Gets the folder path currently being watched.
    /// </summary>
    public string WatchedFolder { get; }

    /// <summary>
    /// Gets the file pattern used to filter detected files.
    /// </summary>
    public string FilePattern { get; }

    /// <summary>
    /// Initializes a new instance of <see cref="FileSystemWatcher"/> and starts watching.
    /// </summary>
    /// <param name="logger">The logger for watcher events.</param>
    /// <param name="folderPath">The full path to the folder to watch.</param>
    /// <param name="filePattern">
    /// The file name pattern to watch for, for example <c>*.json</c>.
    /// Defaults to <c>*.*</c>.
    /// </param>
    public FileSystemWatcher(ILogger<FileSystemWatcher> logger, string folderPath, string filePattern = "*.*")
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(folderPath);

        this.logger = logger;
        WatchedFolder = folderPath;
        FilePattern = filePattern;

        watcher = new System.IO.FileSystemWatcher(folderPath, filePattern)
        {
            NotifyFilter = NotifyFilters.FileName | NotifyFilters.CreationTime,
            EnableRaisingEvents = false,
        };

        watcher.Created += OnFileCreated;

        logger.LogDebug(
            "FileSystemWatcher initialised: {Folder} | Pattern: {Pattern}",
            folderPath,
            filePattern);
    }

    /// <summary>
    /// Starts watching the configured folder for new files.
    /// </summary>
    public void Start()
    {
        watcher.EnableRaisingEvents = true;
        logger.LogInformation("File watching started: {Folder}", WatchedFolder);
    }

    /// <summary>
    /// Stops watching the configured folder.
    /// </summary>
    public void Stop()
    {
        watcher.EnableRaisingEvents = false;
        logger.LogInformation("File watching stopped: {Folder}", WatchedFolder);
    }

    /// <summary>
    /// Handles the file created event from the underlying watcher.
    /// </summary>
    /// <param name="sender">The source of the event.</param>
    /// <param name="e">The file system event arguments containing the file path.</param>
    private void OnFileCreated(object sender, FileSystemEventArgs e)
    {
        logger.LogDebug("New file detected: {FilePath}", e.FullPath);
        FileDetected?.Invoke(this, new FileDetectedEventArgs(e.FullPath));
    }

    /// <summary>
    /// Releases the underlying file system watcher resources.
    /// </summary>
    public void Dispose()
    {
        watcher.Created -= OnFileCreated;
        watcher.Dispose();
        logger.LogDebug("FileSystemWatcher disposed: {Folder}", WatchedFolder);
    }
}
