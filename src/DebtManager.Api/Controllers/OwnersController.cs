using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.Owners;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class OwnersController : BaseApiController
{
    private readonly IOwnerService _ownerService;

    public OwnersController(IOwnerService ownerService)
    {
        _ownerService = ownerService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<OwnerDto>>> GetOwner(CancellationToken ct)
        => Success(await _ownerService.GetOwnerInfoAsync(ct));

    [HttpPut]
    public async Task<ActionResult<ApiResponse<OwnerDto>>> UpdateOwner(
        [FromBody] UpdateOwnerDto dto,
        CancellationToken ct)
        => Success(await _ownerService.UpdateOwnerInfoAsync(dto, ct), "Cập nhật thông tin chủ tài khoản thành công");
}
