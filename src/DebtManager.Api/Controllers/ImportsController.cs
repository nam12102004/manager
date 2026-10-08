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
    public async Task<ActionResult<ApiResponse<List<ImportVoucherDto>>>> GetImports(
        [FromQuery] int? supplierId,
        [FromQuery] string? month,
        CancellationToken ct)
        => Success(await _importService.GetImportsAsync(supplierId, month, ct));

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
