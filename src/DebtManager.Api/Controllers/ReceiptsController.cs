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
    public async Task<ActionResult<ApiResponse<List<ReceiptDto>>>> GetReceipts(
        [FromQuery] int? customerId,
        [FromQuery] int? supplierId,
        [FromQuery] string? q,
        CancellationToken ct)
        => Success(await _receiptService.GetReceiptsAsync(customerId, supplierId, q, ct));

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
