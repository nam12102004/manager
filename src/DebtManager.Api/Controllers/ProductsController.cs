using DebtManager.Api.Common;
using DebtManager.Application.Common;
using DebtManager.Application.DTOs.Products;
using DebtManager.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace DebtManager.Api.Controllers;

public class ProductsController : BaseApiController
{
    private readonly IProductService _productService;

    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<ProductDto>>>> GetProducts(
        [FromQuery] string? q,
        [FromQuery] int? supplierId,
        CancellationToken ct)
        => Success(await _productService.GetProductsAsync(q, supplierId, ct));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ApiResponse<ProductDto>>> GetById(
        int id,
        CancellationToken ct)
        => Success(await _productService.GetByIdAsync(id, ct));

    [HttpPost]
    public async Task<ActionResult<ApiResponse<ProductDto>>> CreateProduct(
        [FromBody] CreateProductDto dto,
        CancellationToken ct)
    {
        var product = await _productService.CreateProductAsync(dto, ct);
        return Created(nameof(GetById), new { id = product.Id }, product, "Tạo sản phẩm thành công");
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ApiResponse<ProductDto>>> UpdateProduct(
        int id,
        [FromBody] UpdateProductDto dto,
        CancellationToken ct)
        => Success(await _productService.UpdateProductAsync(id, dto, ct), "Cập nhật sản phẩm thành công");

    [HttpPost("{id:int}/stock-adjust")]
    public async Task<ActionResult<ApiResponse<bool>>> AdjustStock(
        int id,
        [FromBody] StockAdjustDto dto,
        CancellationToken ct)
        => Success(await _productService.AdjustStockAsync(id, dto, ct), "Điều chỉnh tồn kho thành công");

    [HttpGet("{id:int}/stock-history")]
    public async Task<ActionResult<ApiResponse<List<StockHistoryDto>>>> GetStockHistory(
        int id,
        [FromQuery] string? month,
        CancellationToken ct)
        => Success(await _productService.GetStockHistoryAsync(id, month, ct));
}
