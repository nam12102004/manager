using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.ExportVouchers;
using DebtManager.Application.DTOs.ImportVouchers;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class ImportsController : BaseApiController
{
    private readonly IImportService _importService;

    public ImportsController(IImportService importService)
    {
        _importService = importService;
    }

    [HttpGet]
    public async Task<IActionResult> GetImports(
        [FromQuery] int? supplierId,
        [FromQuery] string? month,
        [FromQuery] string? date,
        [FromQuery] string? fromDate,
        [FromQuery] string? toDate,
        [FromQuery] string? q,
        [FromQuery] int? page,
        [FromQuery] int pageSize = 15,
        [FromQuery] bool all = false,
        CancellationToken ct = default)
    {
        if (page.HasValue && !all)
        {
            var paged = await _importService.GetPagedImportsAsync(supplierId, month, date, fromDate, toDate, q, page.Value, pageSize, ct);
            return Success(paged);
        }

        var list = await _importService.GetImportsAsync(supplierId, !string.IsNullOrWhiteSpace(date) ? date : month, fromDate, toDate, ct);
        return Success(list);
    }

    [HttpGet("{id:long}")]
    public async Task<ActionResult<ApiResponse<ImportVoucherDto>>> GetById(
        long id,
        CancellationToken ct)
        => Success(await _importService.GetByIdAsync(id, ct));

    [HttpPost]
    public async Task<ActionResult<ApiResponse<ImportVoucherDto>>> CreateImport(
        [FromBody] CreateImportDto dto,
        CancellationToken ct)
    {
        var voucher = await _importService.CreateImportAsync(dto, ct);
        return Created(nameof(GetById), new { id = voucher.Id }, voucher, "Tạo phiếu nhập thành công");
    }

    [HttpPatch("{id:long}/status")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateStatus(
        long id,
        [FromBody] UpdateVoucherStatusDto dto,
        CancellationToken ct)
        => Success(await _importService.UpdateStatusAsync(id, dto.Action, ct), "Cập nhật trạng thái thành công");

    [HttpDelete("{id:long}")]
    public async Task<ActionResult<ApiResponse<bool>>> DeleteImport(
        long id,
        CancellationToken ct)
        => Success(await _importService.DeleteImportAsync(id, ct), "Xóa phiếu nhập thành công");
}
