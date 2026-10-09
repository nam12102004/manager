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
    public async Task<IActionResult> GetSuppliers(
        [FromQuery] string? q,
        [FromQuery] string? region,
        [FromQuery] string? sortBy,
        [FromQuery] int? page,
        [FromQuery] int pageSize = 15,
        [FromQuery] bool all = false,
        CancellationToken ct = default)
    {
        if (page.HasValue && !all)
        {
            var paged = await _supplierService.GetPagedSuppliersAsync(q, region, sortBy, page.Value, pageSize, ct);
            return Success(paged);
        }

        var list = await _supplierService.GetSuppliersAsync(q, ct);
        return Success(list);
    }

    [HttpGet("regions")]
    public async Task<ActionResult<ApiResponse<List<string>>>> GetRegions(CancellationToken ct)
        => Success(await _supplierService.GetRegionsAsync(ct));

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
        [FromQuery] string? month,
        CancellationToken ct)
        => Success(await _supplierService.GetDebtHistoryAsync(id, month, ct));

    [HttpPost("{id:int}/debt-adjust")]
    public async Task<ActionResult<ApiResponse<bool>>> AdjustDebt(
        int id,
        [FromBody] SupplierDebtAdjustDto dto,
        CancellationToken ct)
        => Success(await _supplierService.AdjustDebtAsync(id, dto, ct), "Điều chỉnh công nợ thành công");
}
