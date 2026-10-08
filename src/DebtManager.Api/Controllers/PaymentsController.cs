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
    public async Task<ActionResult<ApiResponse<List<PaymentDto>>>> GetPayments(
        [FromQuery] int? supplierId,
        [FromQuery] int? customerId,
        [FromQuery] string? q,
        CancellationToken ct)
        => Success(await _paymentService.GetPaymentsAsync(supplierId, customerId, q, ct));

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
