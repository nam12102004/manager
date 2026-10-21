using System.Collections.Concurrent;
using DebtManager.Application.DTOs.Exports;
using DebtManager.Application.Interfaces;

namespace DebtManager.Application.Services;

public class ExportJobManager : IExportJobManager
{
    private class InternalJobState
    {
        public string JobId { get; set; } = string.Empty;
        public string Status { get; set; } = "queued";
        public int ProgressPercentage { get; set; } = 0;
        public string Message { get; set; } = string.Empty;
        public string? FilePath { get; set; }
        public string? FileName { get; set; }
        public long FileSize { get; set; } = 0;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? CompletedAt { get; set; }
        public string? Error { get; set; }
    }

    private readonly ConcurrentDictionary<string, InternalJobState> _jobs = new();
    private readonly string _tempDirectory;

    public ExportJobManager()
    {
        _tempDirectory = Path.Combine(Path.GetTempPath(), "debtmanager_exports");
        if (!Directory.Exists(_tempDirectory))
        {
            Directory.CreateDirectory(_tempDirectory);
        }
        CleanupOldFiles();
    }

    public string CreateJob(string initialMessage)
    {
        var jobId = $"exp_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}_{Guid.NewGuid():N}"[..24];
        var job = new InternalJobState
        {
            JobId = jobId,
            Status = "queued",
            ProgressPercentage = 0,
            Message = initialMessage,
            CreatedAt = DateTime.UtcNow
        };
        _jobs[jobId] = job;
        return jobId;
    }

    public void UpdateProgress(string jobId, int percentage, string message)
    {
        if (_jobs.TryGetValue(jobId, out var job))
        {
            job.Status = "processing";
            job.ProgressPercentage = Math.Clamp(percentage, 0, 99);
            job.Message = message;
        }
    }

    public void CompleteJob(string jobId, string filePath, string fileName)
    {
        if (_jobs.TryGetValue(jobId, out var job))
        {
            job.Status = "completed";
            job.ProgressPercentage = 100;
            job.Message = "Hoàn tất xuất file Excel";
            job.FilePath = filePath;
            job.FileName = fileName;
            job.CompletedAt = DateTime.UtcNow;
            if (File.Exists(filePath))
            {
                job.FileSize = new FileInfo(filePath).Length;
            }
        }
    }

    public void FailJob(string jobId, string error)
    {
        if (_jobs.TryGetValue(jobId, out var job))
        {
            job.Status = "failed";
            job.Message = "Lỗi khi xuất file Excel";
            job.Error = error;
            job.CompletedAt = DateTime.UtcNow;
        }
    }

    public ExportJobStatusDto? GetStatus(string jobId)
    {
        if (!_jobs.TryGetValue(jobId, out var job))
        {
            return null;
        }

        return new ExportJobStatusDto
        {
            JobId = job.JobId,
            Status = job.Status,
            ProgressPercentage = job.ProgressPercentage,
            Message = job.Message,
            FileName = job.FileName,
            FileSize = job.FileSize,
            CreatedAt = job.CreatedAt,
            CompletedAt = job.CompletedAt,
            Error = job.Error
        };
    }

    public (Stream FileStream, string ContentType, string FileName)? GetFile(string jobId)
    {
        if (!_jobs.TryGetValue(jobId, out var job) || job.Status != "completed" || string.IsNullOrEmpty(job.FilePath))
        {
            return null;
        }

        if (!File.Exists(job.FilePath))
        {
            return null;
        }

        var stream = new FileStream(job.FilePath, FileMode.Open, FileAccess.Read, FileShare.Read);
        return (stream, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", job.FileName ?? $"{jobId}.xlsx");
    }

    private void CleanupOldFiles()
    {
        try
        {
            var cutoff = DateTime.UtcNow.AddHours(-2);
            var dir = new DirectoryInfo(_tempDirectory);
            if (dir.Exists)
            {
                foreach (var file in dir.GetFiles("*.xlsx"))
                {
                    if (file.CreationTimeUtc < cutoff)
                    {
                        try { file.Delete(); } catch { }
                    }
                }
            }

            foreach (var kvp in _jobs)
            {
                if (kvp.Value.CreatedAt < cutoff)
                {
                    _jobs.TryRemove(kvp.Key, out _);
                }
            }
        }
        catch { }
    }
}
