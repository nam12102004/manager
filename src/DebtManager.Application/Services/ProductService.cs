using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.DTOs.Products;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Common;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services;

public class ProductService : IProductService
{
    private readonly IUnitOfWork _uow;

    public ProductService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<List<ProductDto>> GetProductsAsync(string? search = null, int? supplierId = null, CancellationToken ct = default)
    {
        var query = _uow.Products.Query()
            .Include(p => p.Supplier)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(p => p.Name.ToLower().Contains(s) ||
                                     p.Sku.ToLower().Contains(s) ||
                                     (p.Category != null && p.Category.ToLower().Contains(s)) ||
                                     (p.Barcode != null && p.Barcode.ToLower().Contains(s)));
        }

        if (supplierId.HasValue)
        {
            query = query.Where(p => p.SupplierId == supplierId.Value);
        }

        var products = await query.OrderByDescending(p => p.Id).ToListAsync(ct);

        return products.Select(MapToDto).ToList();
    }

    public async Task<ProductDto> GetByIdAsync(int id, CancellationToken ct = default)
    {
        var product = await _uow.Products.Query()
            .Include(p => p.Supplier)
            .FirstOrDefaultAsync(p => p.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy sản phẩm với ID {id}");

        return MapToDto(product);
    }

    public async Task<ProductDto> CreateProductAsync(CreateProductDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            throw new ValidationException("Tên sản phẩm không được để trống");
        }

        if (dto.SupplierId.HasValue)
        {
            var supplierExists = await _uow.Suppliers.Query().AnyAsync(s => s.Id == dto.SupplierId.Value, ct);
            if (!supplierExists)
            {
                throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {dto.SupplierId.Value}");
            }
        }

        var sku = string.IsNullOrWhiteSpace(dto.Sku)
            ? $"SP{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000000):D6}"
            : dto.Sku.Trim();

        var totalStock = dto.StockWarehouse1 + dto.StockWarehouse2 + dto.StockWarehouse3;

        var product = new Product
        {
            Sku = sku,
            Name = dto.Name.Trim(),
            Category = dto.Category?.Trim(),
            Uom = dto.Uom?.Trim(),
            Barcode = dto.Barcode?.Trim(),
            SupplierId = dto.SupplierId,
            UnitCost = dto.UnitCost,
            WholesalePrice = dto.WholesalePrice,
            RetailPrice = dto.RetailPrice,
            StockWarehouse1 = dto.StockWarehouse1,
            StockWarehouse2 = dto.StockWarehouse2,
            StockWarehouse3 = dto.StockWarehouse3,
            TotalStock = totalStock,
            ReorderPoint = dto.ReorderPoint,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _uow.Products.AddAsync(product, ct);
        await _uow.SaveChangesAsync(ct);

        // Record initial stock if any
        if (dto.StockWarehouse1 != 0)
        {
            await RecordInitialStockAsync(product.Id, DomainConstants.Warehouses.Warehouse1, dto.StockWarehouse1, ct);
        }
        if (dto.StockWarehouse2 != 0)
        {
            await RecordInitialStockAsync(product.Id, DomainConstants.Warehouses.Warehouse2, dto.StockWarehouse2, ct);
        }
        if (dto.StockWarehouse3 != 0)
        {
            await RecordInitialStockAsync(product.Id, DomainConstants.Warehouses.Warehouse3, dto.StockWarehouse3, ct);
        }

        if (dto.StockWarehouse1 != 0 || dto.StockWarehouse2 != 0 || dto.StockWarehouse3 != 0)
        {
            await _uow.SaveChangesAsync(ct);
        }

        // Reload with supplier details
        return await GetByIdAsync(product.Id, ct);
    }

    public async Task<ProductDto> UpdateProductAsync(int id, UpdateProductDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            throw new ValidationException("Tên sản phẩm không được để trống");
        }

        var product = await _uow.Products.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy sản phẩm với ID {id}");

        if (dto.SupplierId.HasValue)
        {
            var supplierExists = await _uow.Suppliers.Query().AnyAsync(s => s.Id == dto.SupplierId.Value, ct);
            if (!supplierExists)
            {
                throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {dto.SupplierId.Value}");
            }
        }

        product.Name = dto.Name.Trim();
        product.Category = dto.Category?.Trim();
        product.Uom = dto.Uom?.Trim();
        product.Barcode = dto.Barcode?.Trim();
        product.SupplierId = dto.SupplierId;
        product.UnitCost = dto.UnitCost;
        product.WholesalePrice = dto.WholesalePrice;
        product.RetailPrice = dto.RetailPrice;
        product.ReorderPoint = dto.ReorderPoint;
        product.UpdatedAt = DateTime.UtcNow;

        _uow.Products.Update(product);
        await _uow.SaveChangesAsync(ct);

        return await GetByIdAsync(product.Id, ct);
    }

    public async Task<bool> AdjustStockAsync(int id, StockAdjustDto dto, CancellationToken ct = default)
    {
        var product = await _uow.Products.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy sản phẩm với ID {id}");

        var warehouse = string.IsNullOrWhiteSpace(dto.Warehouse) ? DomainConstants.Warehouses.Warehouse1 : dto.Warehouse;
        decimal beforeWhStock = warehouse switch
        {
            DomainConstants.Warehouses.Warehouse2 => product.StockWarehouse2,
            DomainConstants.Warehouses.Warehouse3 => product.StockWarehouse3,
            _ => product.StockWarehouse1
        };

        decimal delta;
        if (dto.Quantity.HasValue)
        {
            delta = dto.Quantity.Value - beforeWhStock;
        }
        else
        {
            delta = dto.Delta.GetValueOrDefault();
        }

        var afterWhStock = beforeWhStock + delta;
        var beforeTotal = product.TotalStock;
        var afterTotal = beforeTotal + delta;

        switch (warehouse)
        {
            case DomainConstants.Warehouses.Warehouse2:
                product.StockWarehouse2 = afterWhStock;
                break;
            case DomainConstants.Warehouses.Warehouse3:
                product.StockWarehouse3 = afterWhStock;
                break;
            default:
                product.StockWarehouse1 = afterWhStock;
                break;
        }

        product.TotalStock = product.StockWarehouse1 + product.StockWarehouse2 + product.StockWarehouse3;
        product.UpdatedAt = DateTime.UtcNow;

        var history = new StockHistory
        {
            ProductId = product.Id,
            Warehouse = warehouse,
            SourceType = DomainConstants.SourceTypes.ManualAdjustment,
            Reason = dto.Reason ?? "Điều chỉnh kiểm kê kho",
            Note = dto.Note,
            BeforeWarehouseStock = beforeWhStock,
            Delta = delta,
            AfterWarehouseStock = afterWhStock,
            BeforeTotalStock = beforeTotal,
            AfterTotalStock = afterTotal,
            ChangeDate = dto.ChangeDate ?? DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow
        };

        _uow.Products.Update(product);
        await _uow.StockHistories.AddAsync(history, ct);
        await _uow.SaveChangesAsync(ct);

        return true;
    }

    public async Task<List<StockHistoryDto>> GetStockHistoryAsync(int productId, string? month = null, CancellationToken ct = default)
    {
        var productExists = await _uow.Products.Query().AnyAsync(p => p.Id == productId, ct);
        if (!productExists)
        {
            throw new NotFoundException($"Không tìm thấy sản phẩm với ID {productId}");
        }

        var query = _uow.StockHistories.Query().Where(h => h.ProductId == productId);

        if (!string.IsNullOrWhiteSpace(month) && DateTime.TryParseExact(month.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsedMonth))
        {
            var start = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
            var end = start.AddMonths(1);
            query = query.Where(h => h.ChangeDate >= start && h.ChangeDate < end);
        }

        var list = await query.OrderByDescending(h => h.ChangeDate)
                              .ThenByDescending(h => h.Id)
                              .ToListAsync(ct);

        return list.Select(h => new StockHistoryDto
        {
            Id = h.Id,
            ProductId = h.ProductId,
            Warehouse = h.Warehouse,
            SourceType = h.SourceType,
            ReferenceType = h.ReferenceType,
            ReferenceId = h.ReferenceId,
            Reason = h.Reason,
            Note = h.Note,
            BeforeWarehouseStock = h.BeforeWarehouseStock,
            Delta = h.Delta,
            AfterWarehouseStock = h.AfterWarehouseStock,
            BeforeTotalStock = h.BeforeTotalStock,
            AfterTotalStock = h.AfterTotalStock,
            ChangeDate = h.ChangeDate,
            CreatedAt = h.CreatedAt
        }).ToList();
    }

    private async Task RecordInitialStockAsync(int productId, string warehouse, decimal qty, CancellationToken ct)
    {
        var history = new StockHistory
        {
            ProductId = productId,
            Warehouse = warehouse,
            SourceType = "init",
            Reason = "Tồn kho ban đầu",
            BeforeWarehouseStock = 0,
            Delta = qty,
            AfterWarehouseStock = qty,
            BeforeTotalStock = 0,
            AfterTotalStock = qty,
            ChangeDate = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow
        };
        await _uow.StockHistories.AddAsync(history, ct);
    }

    private static ProductDto MapToDto(Product p) => new()
    {
        Id = p.Id,
        Sku = p.Sku,
        Name = p.Name,
        Category = p.Category,
        Uom = p.Uom,
        Barcode = p.Barcode,
        SupplierId = p.SupplierId,
        SupplierName = p.Supplier?.Name,
        UnitCost = p.UnitCost,
        WholesalePrice = p.WholesalePrice,
        RetailPrice = p.RetailPrice,
        StockWarehouse1 = p.StockWarehouse1,
        StockWarehouse2 = p.StockWarehouse2,
        StockWarehouse3 = p.StockWarehouse3,
        TotalStock = p.TotalStock,
        ReorderPoint = p.ReorderPoint,
        CreatedAt = p.CreatedAt,
        UpdatedAt = p.UpdatedAt
    };
}
