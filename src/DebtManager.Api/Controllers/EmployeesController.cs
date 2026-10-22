using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.Employees;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class EmployeesController : BaseApiController
{
    private readonly IEmployeeService _employeeService;

    public EmployeesController(IEmployeeService employeeService)
    {
        _employeeService = employeeService;
    }

    [HttpGet]
    public async Task<IActionResult> GetEmployees(
        [FromQuery] string? q,
        [FromQuery] string? month,
        [FromQuery] string? date,
        [FromQuery] string? fromDate,
        [FromQuery] string? toDate,
        CancellationToken ct = default)
    {
        var employees = await _employeeService.GetEmployeesAsync(q, month, date, fromDate, toDate, ct);
        return Success(employees);
    }

    [HttpGet("export-excel")]
    public async Task<IActionResult> ExportExcel(
        [FromQuery] int? employeeId,
        [FromQuery] string? month,
        [FromQuery] string? date,
        [FromQuery] string? fromDate,
        [FromQuery] string? toDate,
        CancellationToken ct = default)
    {
        var (bytes, fileName) = await _employeeService.ExportEmployeeSalesExcelAsync(employeeId, month, date, fromDate, toDate, ct);
        return File(bytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
    }

    [HttpGet("{id:int}/export-excel")]
    public async Task<IActionResult> ExportEmployeeExcel(
        int id,
        [FromQuery] string? month,
        [FromQuery] string? date,
        [FromQuery] string? fromDate,
        [FromQuery] string? toDate,
        CancellationToken ct = default)
    {
        var (bytes, fileName) = await _employeeService.ExportEmployeeSalesExcelAsync(id, month, date, fromDate, toDate, ct);
        return File(bytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<EmployeeDto>>> GetById(int id, CancellationToken ct)
    {
        var employee = await _employeeService.GetByIdAsync(id, ct);
        return Success(employee);
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<EmployeeDto>>> CreateEmployee(
        [FromBody] CreateEmployeeDto dto,
        CancellationToken ct)
    {
        var employee = await _employeeService.CreateEmployeeAsync(dto, ct);
        return Created(nameof(GetById), new { id = employee.Id }, employee, "Thêm nhân viên thành công");
    }

    [HttpDelete("{id:int}")]
    public async Task<ActionResult<ApiResponse<bool>>> DeleteEmployee(
        int id,
        CancellationToken ct)
    {
        var result = await _employeeService.DeleteEmployeeAsync(id, ct);
        return Success(result, "Xóa nhân viên thành công");
    }
}
