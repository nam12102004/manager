using DebtManager.Application.DTOs.Exports;

namespace DebtManager.Application.Interfaces;

public interface IExportJobManager
{
    string CreateJob(string initialMessage);
    void UpdateProgress(string jobId, int percentage, string message);
    void CompleteJob(string jobId, string filePath, string fileName);
    void FailJob(string jobId, string error);
    ExportJobStatusDto? GetStatus(string jobId);
    (Stream FileStream, string ContentType, string FileName)? GetFile(string jobId);
}
