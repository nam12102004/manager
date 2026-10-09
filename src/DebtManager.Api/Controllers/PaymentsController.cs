using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.ExportVouchers;
using DebtManager.Application.DTOs.Payments;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class PaymentsController : BaseApiController
{
    private readonly IPaymentService _paymentService;

    public PaymentsController(IPaymentService paymentService)
    {
        _paymentService = paymentService;
    }

    [HttpGet]
    public async Task<IActionResult> GetPayments(
        [FromQuery] int? supplierId,
        [FromQuery] int? customerId,
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
            var paged = await _paymentService.GetPagedPaymentsAsync(supplierId, customerId, q, month, date, fromDate, toDate, page.Value, pageSize, ct);
            return Success(paged);
        }

        var list = await _paymentService.GetPaymentsAsync(supplierId, customerId, q, ct);
        return Success(list);
    }

    [HttpGet("{id:long}")]
    public async Task<ActionResult<ApiResponse<PaymentDto>>> GetById(
        long id,
        CancellationToken ct)
        => Success(await _paymentService.GetByIdAsync(id, ct));

    [HttpPost]
    public async Task<ActionResult<ApiResponse<PaymentDto>>> CreatePayment(
        [FromBody] CreatePaymentDto dto,
        CancellationToken ct)
    {
        var payment = await _paymentService.CreatePaymentAsync(dto, ct);
        return Created(nameof(GetById), new { id = payment.Id }, payment, "Tạo phiếu chi thành công");
    }

    [HttpPatch("{id:long}/status")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateStatus(
        long id,
        [FromBody] UpdateVoucherStatusDto dto,
        CancellationToken ct)
        => Success(await _paymentService.UpdateStatusAsync(id, dto.Action, ct), "Cập nhật trạng thái thành công");

    [HttpDelete("{id:long}")]
    public async Task<ActionResult<ApiResponse<bool>>> DeletePayment(
        long id,
        CancellationToken ct)
        => Success(await _paymentService.DeletePaymentAsync(id, ct), "Xóa phiếu chi thành công");
}
