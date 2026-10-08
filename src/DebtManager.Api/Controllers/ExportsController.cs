using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.ExportVouchers;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class ExportsController : BaseApiController
{
    private readonly IExportService _exportService;

    public ExportsController(IExportService exportService)
    {
        _exportService = exportService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<ExportVoucherDto>>>> GetExports(
        [FromQuery] int? customerId,
        [FromQuery] string? month,
        CancellationToken ct)
        => Success(await _exportService.GetExportsAsync(customerId, month, ct));

    [HttpGet("{id:long}")]
    public async Task<ActionResult<ApiResponse<ExportVoucherDto>>> GetById(
        long id,
        CancellationToken ct)
        => Success(await _exportService.GetByIdAsync(id, ct));

    [HttpPost]
    public async Task<ActionResult<ApiResponse<ExportVoucherDto>>> CreateExport(
        [FromBody] CreateExportDto dto,
        CancellationToken ct)
    {
        var voucher = await _exportService.CreateExportAsync(dto, ct);
        return Created(nameof(GetById), new { id = voucher.Id }, voucher, "Tạo phiếu xuất thành công");
    }

    [HttpPatch("{id:long}/status")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateStatus(
        long id,
        [FromBody] UpdateVoucherStatusDto dto,
        CancellationToken ct)
        => Success(await _exportService.UpdateStatusAsync(id, dto.Action, ct), "Cập nhật trạng thái thành công");

    [HttpDelete("{id:long}")]
    public async Task<ActionResult<ApiResponse<bool>>> DeleteExport(
        long id,
        CancellationToken ct)
        => Success(await _exportService.DeleteExportAsync(id, ct), "Xóa phiếu xuất thành công");
}
