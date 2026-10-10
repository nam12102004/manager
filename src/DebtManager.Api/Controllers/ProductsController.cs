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
    public async Task<IActionResult> GetProducts(
        [FromQuery] string? q,
        [FromQuery] int? supplierId,
        [FromQuery] string? warehouse,
        [FromQuery] string? sortBy,
        [FromQuery] string? category,
        [FromQuery] int? page,
        [FromQuery] int pageSize = 15,
        [FromQuery] bool all = false,
        CancellationToken ct = default)
    {
        if (page.HasValue && !all)
        {
            var paged = await _productService.GetPagedProductsAsync(q, supplierId, warehouse, sortBy, page.Value, pageSize, category, ct);
            return Success(paged);
        }

        var list = await _productService.GetProductsAsync(q, supplierId, ct);
        return Success(list);
    }

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

    [HttpGet("categories")]
    public async Task<ActionResult<ApiResponse<List<string>>>> GetCategories(CancellationToken ct)
        => Success(await _productService.GetCategoriesAsync(ct));
}
