using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.Suppliers;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class SuppliersController : BaseApiController
{
    private readonly ISupplierService _supplierService;

    public SuppliersController(ISupplierService supplierService)
    {
        _supplierService = supplierService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<SupplierDto>>>> GetSuppliers(
        [FromQuery] string? q,
        CancellationToken ct)
        => Success(await _supplierService.GetSuppliersAsync(q, ct));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<SupplierDto>>> GetById(
        int id,
        CancellationToken ct)
        => Success(await _supplierService.GetByIdAsync(id, ct));

    [HttpPost]
    public async Task<ActionResult<ApiResponse<SupplierDto>>> CreateSupplier(
        [FromBody] CreateSupplierDto dto,
        CancellationToken ct)
    {
        var supplier = await _supplierService.CreateSupplierAsync(dto, ct);
        return Created(nameof(GetById), new { id = supplier.Id }, supplier, "Tạo nhà cung cấp thành công");
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResponse<SupplierDto>>> UpdateSupplier(
        int id,
        [FromBody] UpdateSupplierDto dto,
        CancellationToken ct)
        => Success(await _supplierService.UpdateSupplierAsync(id, dto, ct), "Cập nhật nhà cung cấp thành công");

    [HttpGet("{id:int}/debt-history")]
    public async Task<ActionResult<ApiResponse<List<SupplierDebtHistoryDto>>>> GetDebtHistory(
        int id,
        CancellationToken ct)
        => Success(await _supplierService.GetDebtHistoryAsync(id, ct));

    [HttpPost("{id:int}/debt-adjust")]
    public async Task<ActionResult<ApiResponse<bool>>> AdjustDebt(
        int id,
        [FromBody] SupplierDebtAdjustDto dto,
        CancellationToken ct)
        => Success(await _supplierService.AdjustDebtAsync(id, dto, ct), "Điều chỉnh công nợ thành công");
}
