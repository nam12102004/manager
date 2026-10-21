using DebtManager.Api.Common;
using DebtManager.Application.DTOs.Exports;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class ExportController : BaseApiController
{
    private readonly IExcelExportService _exportService;
    private readonly IExportJobManager _jobManager;

    public ExportController(IExcelExportService exportService, IExportJobManager jobManager)
    {
        _exportService = exportService;
        _jobManager = jobManager;
    }

    [HttpPost("preview")]
    public async Task<IActionResult> GetReportPreview([FromBody] ExportReportRequestDto dto, CancellationToken ct)
    {
        var preview = await _exportService.GeneratePreviewAsync(dto, ct);
        return Success(preview);
    }

    [HttpPost("start-report")]
    public IActionResult StartReportExport([FromBody] ExportReportRequestDto dto)
    {
        var jobId = _exportService.StartReportExport(dto);
        return Success(new { jobId }, "Đã khởi tạo tiến trình xuất báo cáo Excel ngầm thành công");
    }

    [HttpPost("start-matrix")]
    public IActionResult StartDailyMatrixExport([FromBody] DailyMatrixExportRequestDto dto)
    {
        var jobId = _exportService.StartDailyMatrixExport(dto);
        return Success(new { jobId }, "Đã khởi tạo tiến trình xuất ma trận Excel ngầm thành công");
    }

    [HttpPost("start-full-db")]
    public IActionResult StartFullDbExport([FromBody] FullDbExportRequestDto dto)
    {
        var jobId = _exportService.StartFullDbExport(dto);
        return Success(new { jobId }, "Đã khởi tạo tiến trình sao lưu toàn bộ dữ liệu Excel ngầm thành công");
    }

    [HttpGet("status/{jobId}")]
    public IActionResult GetJobStatus(string jobId)
    {
        var status = _jobManager.GetStatus(jobId);
        if (status == null)
        {
            return NotFound(new { message = $"Không tìm thấy tác vụ xuất với mã {jobId}" });
        }
        return Success(status);
    }

    [HttpGet("download/{jobId}")]
    public IActionResult DownloadFile(string jobId)
    {
        var fileResult = _jobManager.GetFile(jobId);
        if (fileResult == null)
        {
            return NotFound(new { message = "Tệp xuất chưa sẵn sàng hoặc đã hết hạn" });
        }

        var (stream, contentType, fileName) = fileResult.Value;
        return File(stream, contentType, fileName);
    }
}
