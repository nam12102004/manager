using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.Customers;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class CustomersController : BaseApiController
{
    private readonly ICustomerService _customerService;

    public CustomersController(ICustomerService customerService)
    {
        _customerService = customerService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<CustomerDto>>>> GetCustomers(
        [FromQuery] string? q,
        CancellationToken ct)
        => Success(await _customerService.GetCustomersAsync(q, ct));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<CustomerDto>>> GetById(
        int id,
        CancellationToken ct)
        => Success(await _customerService.GetByIdAsync(id, ct));

    [HttpPost]
    public async Task<ActionResult<ApiResponse<CustomerDto>>> CreateCustomer(
        [FromBody] CreateCustomerDto dto,
        CancellationToken ct)
    {
        var customer = await _customerService.CreateCustomerAsync(dto, ct);
        return Created(nameof(GetById), new { id = customer.Id }, customer, "Tạo khách hàng thành công");
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResponse<CustomerDto>>> UpdateCustomer(
        int id,
        [FromBody] UpdateCustomerDto dto,
        CancellationToken ct)
        => Success(await _customerService.UpdateCustomerAsync(id, dto, ct), "Cập nhật khách hàng thành công");

    [HttpGet("{id:int}/debt-history")]
    public async Task<ActionResult<ApiResponse<List<CustomerDebtHistoryDto>>>> GetDebtHistory(
        int id,
        CancellationToken ct)
        => Success(await _customerService.GetDebtHistoryAsync(id, ct));

    [HttpPost("{id:int}/debt-adjust")]
    public async Task<ActionResult<ApiResponse<bool>>> AdjustDebt(
        int id,
        [FromBody] CustomerDebtAdjustDto dto,
        CancellationToken ct)
        => Success(await _customerService.AdjustDebtAsync(id, dto, ct), "Điều chỉnh công nợ thành công");
}
