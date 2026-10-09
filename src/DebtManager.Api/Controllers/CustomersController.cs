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
    public async Task<IActionResult> GetCustomers(
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
            var paged = await _customerService.GetPagedCustomersAsync(q, region, sortBy, page.Value, pageSize, ct);
            return Success(paged);
        }

        var list = await _customerService.GetCustomersAsync(q, ct);
        return Success(list);
    }

    [HttpGet("regions")]
    public async Task<ActionResult<ApiResponse<List<string>>>> GetRegions(CancellationToken ct)
        => Success(await _customerService.GetRegionsAsync(ct));

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
        [FromQuery] string? month,
        CancellationToken ct)
        => Success(await _customerService.GetDebtHistoryAsync(id, month, ct));

    [HttpPost("{id:int}/debt-adjust")]
    public async Task<ActionResult<ApiResponse<bool>>> AdjustDebt(
        int id,
        [FromBody] CustomerDebtAdjustDto dto,
        CancellationToken ct)
        => Success(await _customerService.AdjustDebtAsync(id, dto, ct), "Điều chỉnh công nợ thành công");
}
