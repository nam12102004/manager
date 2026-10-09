using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.Receipts;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class ReceiptsController : BaseApiController
{
    private readonly IReceiptService _receiptService;

    public ReceiptsController(IReceiptService receiptService)
    {
        _receiptService = receiptService;
    }

    [HttpGet]
    public async Task<IActionResult> GetReceipts(
        [FromQuery] int? customerId,
        [FromQuery] int? supplierId,
        [FromQuery] string? q,
        [FromQuery] string? month,
        [FromQuery] string? date,
        [FromQuery] string? fromDate,
        [FromQuery] string? toDate,
        [FromQuery] int? page,
        [FromQuery] int pageSize = 15,
        [FromQuery] bool all = false,
        CancellationToken ct = default)
    {
        if (page.HasValue && !all)
        {
            var paged = await _receiptService.GetPagedReceiptsAsync(customerId, supplierId, q, month, date, fromDate, toDate, page.Value, pageSize, ct);
            return Success(paged);
        }

        var list = await _receiptService.GetReceiptsAsync(customerId, supplierId, q, ct);
        return Success(list);
    }

    [HttpGet("{id:long}")]
    public async Task<ActionResult<ApiResponse<ReceiptDto>>> GetById(
        long id,
        CancellationToken ct)
        => Success(await _receiptService.GetByIdAsync(id, ct));

    [HttpPost]
    public async Task<ActionResult<ApiResponse<ReceiptDto>>> CreateReceipt(
        [FromBody] CreateReceiptDto dto,
        CancellationToken ct)
    {
        var receipt = await _receiptService.CreateReceiptAsync(dto, ct);
        return Created(nameof(GetById), new { id = receipt.Id }, receipt, "Tạo phiếu thu thành công");
    }

    [HttpDelete("{id:long}")]
    public async Task<ActionResult<ApiResponse<bool>>> DeleteReceipt(
        long id,
        CancellationToken ct)
        => Success(await _receiptService.DeleteReceiptAsync(id, ct), "Xóa phiếu thu thành công");
}
