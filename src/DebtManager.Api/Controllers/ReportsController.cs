using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.Reports;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class ReportsController : BaseApiController
{
    private readonly IReportService _reportService;

    public ReportsController(IReportService reportService)
    {
        _reportService = reportService;
    }

    [HttpGet("stock")]
    public async Task<ActionResult<ApiResponse<StockReportResponseDto>>> GetStockReport(
        [FromQuery] string? month,
        CancellationToken ct)
        => Success(await _reportService.GetStockReportAsync(month, ct));

    [HttpGet("debts")]
    public async Task<ActionResult<ApiResponse<DebtReportResponseDto>>> GetDebtReport(
        [FromQuery] string? month,
        CancellationToken ct)
        => Success(await _reportService.GetDebtReportAsync(month, ct));

    [HttpGet("warehouse-sales")]
    public async Task<ActionResult<ApiResponse<WarehouseSalesResponseDto>>> GetWarehouseSales(
        [FromQuery] string? warehouse,
        [FromQuery] string? month,
        [FromQuery] string? type,
        [FromQuery] string? sortBy,
        CancellationToken ct)
        => Success(await _reportService.GetWarehouseSalesAsync(warehouse, month, type, sortBy, ct));
}
