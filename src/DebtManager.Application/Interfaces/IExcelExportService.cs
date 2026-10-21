using DebtManager.Application.DTOs.Exports;

namespace DebtManager.Application.Interfaces;

public interface IExcelExportService
{
    string StartReportExport(ExportReportRequestDto request);
    string StartDailyMatrixExport(DailyMatrixExportRequestDto request);
    string StartFullDbExport(FullDbExportRequestDto request);
    Task<ExcelPreviewResultDto> GeneratePreviewAsync(ExportReportRequestDto request, CancellationToken ct = default);
}
