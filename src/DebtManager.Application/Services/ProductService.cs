using DebtManager.Application.Common;
using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.DTOs.Common;
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
            .Include(p => p.Units)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(p => p.Name.ToLower().Contains(s) ||
                                     p.Sku.ToLower().Contains(s) ||
                                     (p.Category != null && p.Category.ToLower().Contains(s)) ||
                                     (p.Barcode != null && p.Barcode.ToLower().Contains(s)) ||
                                     p.Units.Any(u => u.Barcode != null && u.Barcode.ToLower().Contains(s)) ||
                                     (p.Supplier != null && p.Supplier.Name.ToLower().Contains(s)));
        }

        if (supplierId.HasValue)
        {
            query = query.Where(p => p.SupplierId == supplierId.Value);
        }

        var products = await query.OrderByDescending(p => p.Id).ToListAsync(ct);

        return products.Select(MapToDto).ToList();
    }

    public async Task<ProductPagedResult> GetPagedProductsAsync(
        string? search = null,
        int? supplierId = null,
        string? warehouse = null,
        string? sortBy = null,
        int page = 1,
        int pageSize = 15,
        string? category = null,
        string? fromDate = null,
        string? toDate = null,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = pageSize > 0 ? pageSize : 15;

        var query = _uow.Products.Query()
            .Include(p => p.Supplier)
            .Include(p => p.Units)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(p => p.Name.ToLower().Contains(s) ||
                                     p.Sku.ToLower().Contains(s) ||
                                     (p.Category != null && p.Category.ToLower().Contains(s)) ||
                                     (p.Barcode != null && p.Barcode.ToLower().Contains(s)) ||
                                     p.Units.Any(u => u.Barcode != null && u.Barcode.ToLower().Contains(s)) ||
                                     (p.Supplier != null && p.Supplier.Name.ToLower().Contains(s)));
        }

        // Per-supplier counts (computed before supplierId filter, respecting search & category)
        var supplierQuery = query;
        if (!string.IsNullOrWhiteSpace(category) && category != "ALL")
        {
            if (category == "NONE")
            {
                supplierQuery = supplierQuery.Where(p => p.Category == null || p.Category.Trim() == "");
            }
            else
            {
                var c = category.Trim();
                supplierQuery = supplierQuery.Where(p => p.Category != null && p.Category.Trim() == c);
            }
        }
        var supplierGroups = await supplierQuery
            .GroupBy(p => p.SupplierId ?? -1)
            .Select(g => new { SupplierId = g.Key, Count = g.Count() })
            .ToListAsync(ct);
        var supplierCounts = new Dictionary<string, int>();
        foreach (var g in supplierGroups)
        {
            var key = g.SupplierId == -1 ? "NONE" : g.SupplierId.ToString();
            supplierCounts[key] = supplierCounts.GetValueOrDefault(key) + g.Count;
        }

        if (supplierId.HasValue)
        {
            if (supplierId.Value == -1)
            {
                query = query.Where(p => p.SupplierId == null);
            }
            else
            {
                query = query.Where(p => p.SupplierId == supplierId.Value);
            }
        }

        // Per-category counts (computed in DB before the category filter so every tab shows its own total)
        var categoryGroups = await query
            .GroupBy(p => p.Category ?? "")
            .Select(g => new { Category = g.Key, Count = g.Count() })
            .ToListAsync(ct);
        var categoryCounts = new Dictionary<string, int>();
        foreach (var g in categoryGroups)
        {
            var key = string.IsNullOrWhiteSpace(g.Category) ? "NONE" : g.Category.Trim();
            categoryCounts[key] = categoryCounts.GetValueOrDefault(key) + g.Count;
        }

        if (!string.IsNullOrWhiteSpace(category) && category != "ALL")
        {
            if (category == "NONE")
            {
                query = query.Where(p => p.Category == null || p.Category.Trim() == "");
            }
            else
            {
                var c = category.Trim();
                query = query.Where(p => p.Category != null && p.Category.Trim() == c);
            }
        }

        var wh = (warehouse ?? "overview").Trim().ToLower();

        var totalCount = await query.CountAsync(ct);

        decimal totalStockQty = 0;
        decimal totalCostVal = 0;
        decimal totalWholesaleVal = 0;
        decimal totalRetailVal = 0;

        if (wh == "warehouse1")
        {
            totalStockQty = await query.SumAsync(p => (decimal?)p.StockWarehouse1, ct) ?? 0;
            totalCostVal = await query.SumAsync(p => (decimal?)(p.StockWarehouse1 * p.UnitCost), ct) ?? 0;
            totalWholesaleVal = await query.SumAsync(p => (decimal?)(p.StockWarehouse1 * p.WholesalePrice), ct) ?? 0;
            totalRetailVal = await query.SumAsync(p => (decimal?)(p.StockWarehouse1 * p.RetailPrice), ct) ?? 0;
        }
        else if (wh == "warehouse2")
        {
            totalStockQty = await query.SumAsync(p => (decimal?)p.StockWarehouse2, ct) ?? 0;
            totalCostVal = await query.SumAsync(p => (decimal?)(p.StockWarehouse2 * p.UnitCost), ct) ?? 0;
            totalWholesaleVal = await query.SumAsync(p => (decimal?)(p.StockWarehouse2 * p.WholesalePrice), ct) ?? 0;
            totalRetailVal = await query.SumAsync(p => (decimal?)(p.StockWarehouse2 * p.RetailPrice), ct) ?? 0;
        }
        else if (wh == "warehouse3")
        {
            totalStockQty = await query.SumAsync(p => (decimal?)p.StockWarehouse3, ct) ?? 0;
            totalCostVal = await query.SumAsync(p => (decimal?)(p.StockWarehouse3 * p.UnitCost), ct) ?? 0;
            totalWholesaleVal = await query.SumAsync(p => (decimal?)(p.StockWarehouse3 * p.WholesalePrice), ct) ?? 0;
            totalRetailVal = await query.SumAsync(p => (decimal?)(p.StockWarehouse3 * p.RetailPrice), ct) ?? 0;
        }
        else
        {
            totalStockQty = await query.SumAsync(p => (decimal?)p.TotalStock, ct) ?? 0;
            totalCostVal = await query.SumAsync(p => (decimal?)(p.TotalStock * p.UnitCost), ct) ?? 0;
            totalWholesaleVal = await query.SumAsync(p => (decimal?)(p.TotalStock * p.WholesalePrice), ct) ?? 0;
            totalRetailVal = await query.SumAsync(p => (decimal?)(p.TotalStock * p.RetailPrice), ct) ?? 0;
        }

        // In-stock products (for the active warehouse) are always listed before out-of-stock ones,
        // except when the user explicitly sorts by stock quantity.
        var inStockFirst = wh switch
        {
            "warehouse1" => query.OrderByDescending(p => p.StockWarehouse1 > 0),
            "warehouse2" => query.OrderByDescending(p => p.StockWarehouse2 > 0),
            "warehouse3" => query.OrderByDescending(p => p.StockWarehouse3 > 0),
            _ => query.OrderByDescending(p => p.TotalStock > 0)
        };

        query = sortBy switch
        {
            "stock_desc" => wh switch
            {
                "warehouse1" => query.OrderByDescending(p => p.StockWarehouse1).ThenByDescending(p => p.Id),
                "warehouse2" => query.OrderByDescending(p => p.StockWarehouse2).ThenByDescending(p => p.Id),
                "warehouse3" => query.OrderByDescending(p => p.StockWarehouse3).ThenByDescending(p => p.Id),
                _ => query.OrderByDescending(p => p.TotalStock).ThenByDescending(p => p.Id)
            },
            "stock_asc" => wh switch
            {
                "warehouse1" => query.OrderBy(p => p.StockWarehouse1).ThenByDescending(p => p.Id),
                "warehouse2" => query.OrderBy(p => p.StockWarehouse2).ThenByDescending(p => p.Id),
                "warehouse3" => query.OrderBy(p => p.StockWarehouse3).ThenByDescending(p => p.Id),
                _ => query.OrderBy(p => p.TotalStock).ThenByDescending(p => p.Id)
            },
            "cost_desc" => inStockFirst.ThenByDescending(p => p.UnitCost).ThenByDescending(p => p.Id),
            "cost_asc" => inStockFirst.ThenBy(p => p.UnitCost).ThenByDescending(p => p.Id),
            "wholesale_desc" => inStockFirst.ThenByDescending(p => p.WholesalePrice).ThenByDescending(p => p.Id),
            "wholesale_asc" => inStockFirst.ThenBy(p => p.WholesalePrice).ThenByDescending(p => p.Id),
            "retail_desc" => inStockFirst.ThenByDescending(p => p.RetailPrice).ThenByDescending(p => p.Id),
            "retail_asc" => inStockFirst.ThenBy(p => p.RetailPrice).ThenByDescending(p => p.Id),
            _ => inStockFirst.ThenByDescending(p => p.Id)
        };

        var items = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync(ct);
        var productIds = items.Select(p => p.Id).ToList();

        DateTime? startDate = null;
        DateTime? endDate = null;
        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            startDate = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
        }
        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            endDate = new DateTime(pTo.Year, pTo.Month, pTo.Day, 23, 59, 59, 999, DateTimeKind.Utc);
        }

        var importItemsQuery = _uow.ImportVoucherItems.Query()
            .Where(i => productIds.Contains(i.ProductId) && i.ImportVoucher.Status != "cancelled");
        if (startDate.HasValue)
        {
            importItemsQuery = importItemsQuery.Where(i => i.ImportVoucher.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            importItemsQuery = importItemsQuery.Where(i => i.ImportVoucher.Date <= endDate.Value);
        }

        var importItemBreakdown = await importItemsQuery
            .GroupBy(i => new { i.ProductId, Warehouse = i.ImportVoucher.Warehouse.ToLower() })
            .Select(g => new { g.Key.ProductId, g.Key.Warehouse, Qty = g.Sum(x => x.Quantity), Amount = g.Sum(x => x.LineTotal) })
            .ToListAsync(ct);

        var exportItemsQuery = _uow.ExportVoucherItems.Query()
            .Where(i => productIds.Contains(i.ProductId) && i.ExportVoucher.Status != "cancelled");
        if (startDate.HasValue)
        {
            exportItemsQuery = exportItemsQuery.Where(i => i.ExportVoucher.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            exportItemsQuery = exportItemsQuery.Where(i => i.ExportVoucher.Date <= endDate.Value);
        }

        var exportItemBreakdown = await exportItemsQuery
            .GroupBy(i => new { i.ProductId, Warehouse = i.ExportVoucher.Warehouse.ToLower() })
            .Select(g => new { g.Key.ProductId, g.Key.Warehouse, Qty = g.Sum(x => x.Quantity), Amount = g.Sum(x => x.LineTotal) })
            .ToListAsync(ct);

        var dtos = items.Select(p =>
        {
            var dto = MapToDto(p);
            var pImports = importItemBreakdown.Where(x => x.ProductId == p.Id).ToList();
            var pExports = exportItemBreakdown.Where(x => x.ProductId == p.Id).ToList();

            var allWhs = pImports.Select(x => x.Warehouse).Union(pExports.Select(x => x.Warehouse)).Distinct();
            foreach (var w in allWhs)
            {
                var im = pImports.FirstOrDefault(x => x.Warehouse == w);
                var ex = pExports.FirstOrDefault(x => x.Warehouse == w);
                dto.WarehouseMetrics[w] = new ProductWarehouseMetricDto
                {
                    ImportQty = im?.Qty ?? 0,
                    ImportAmount = im?.Amount ?? 0,
                    ExportQty = ex?.Qty ?? 0,
                    ExportAmount = ex?.Amount ?? 0,
                    ReceiptAmount = ex?.Amount ?? 0,
                    PaymentAmount = im?.Amount ?? 0
                };
            }

            dto.TotalImportQty = pImports.Sum(x => x.Qty);
            dto.TotalImportAmount = pImports.Sum(x => x.Amount);
            dto.TotalExportQty = pExports.Sum(x => x.Qty);
            dto.TotalExportAmount = pExports.Sum(x => x.Amount);
            dto.TotalReceiptAmount = dto.TotalExportAmount;
            dto.TotalPaymentAmount = dto.TotalImportAmount;
            return dto;
        }).ToList();

        return new ProductPagedResult
        {
            Items = dtos,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalStockQty = totalStockQty,
            TotalCostVal = totalCostVal,
            TotalWholesaleVal = totalWholesaleVal,
            TotalRetailVal = totalRetailVal,
            TotalImportQty = dtos.Sum(d => d.TotalImportQty),
            TotalImportAmount = dtos.Sum(d => d.TotalImportAmount),
            TotalExportQty = dtos.Sum(d => d.TotalExportQty),
            TotalExportAmount = dtos.Sum(d => d.TotalExportAmount),
            TotalReceiptAmount = dtos.Sum(d => d.TotalReceiptAmount),
            TotalPaymentAmount = dtos.Sum(d => d.TotalPaymentAmount),
            CategoryCounts = categoryCounts,
            SupplierCounts = supplierCounts
        };
    }

    public async Task<ProductDto> GetByIdAsync(int id, CancellationToken ct = default)
    {
        var product = await _uow.Products.Query()
            .Include(p => p.Supplier)
            .Include(p => p.Units)
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

        if (dto.WarehouseStocks != null)
        {
            foreach (var kvp in dto.WarehouseStocks)
            {
                product.SetWarehouseStock(kvp.Key, kvp.Value);
            }
        }

        await _uow.Products.AddAsync(product, ct);
        await _uow.SaveChangesAsync(ct);

        // Multi-UOM setup
        var baseUomName = !string.IsNullOrWhiteSpace(product.Uom) ? product.Uom.Trim() : "Cái";
        if (dto.Units != null && dto.Units.Count > 0)
        {
            var validUnits = dto.Units
                .Where(u => !string.IsNullOrWhiteSpace(u.UnitName))
                .GroupBy(u => u.UnitName.Trim().ToLowerInvariant())
                .Select(g => g.First())
                .OrderBy(u => u.ConversionRate > 0 ? u.ConversionRate : 1m)
                .ToList();

            if (validUnits.Count > 0)
            {
                var minRate = validUnits[0].ConversionRate > 0 ? validUnits[0].ConversionRate : 1m;
                for (int idx = 0; idx < validUnits.Count; idx++)
                {
                    var u = validUnits[idx];
                    var unitName = u.UnitName.Trim();
                    var isBase = idx == 0;
                    var normalizedRate = isBase ? 1m : Math.Round((u.ConversionRate > 0 ? u.ConversionRate : 1m) / minRate, 4);

                    var pUnit = new ProductUnit
                    {
                        ProductId = product.Id,
                        UnitName = unitName,
                        ConversionRate = normalizedRate,
                        IsBaseUnit = isBase,
                        Barcode = u.Barcode?.Trim(),
                        RetailPrice = u.RetailPrice > 0 ? u.RetailPrice : (normalizedRate * product.RetailPrice),
                        WholesalePrice = u.WholesalePrice > 0 ? u.WholesalePrice : (normalizedRate * product.WholesalePrice),
                        CanSell = u.CanSell
                    };
                    await _uow.ProductUnits.AddAsync(pUnit, ct);
                }

                // If product.Uom is not among the defined units, default to the smallest base unit
                if (!validUnits.Any(u => u.UnitName.Trim().Equals(baseUomName, StringComparison.OrdinalIgnoreCase)))
                {
                    product.Uom = validUnits[0].UnitName.Trim();
                    _uow.Products.Update(product);
                }
            }
        }
        else
        {
            var pUnit = new ProductUnit
            {
                ProductId = product.Id,
                UnitName = baseUomName,
                ConversionRate = 1,
                IsBaseUnit = true,
                RetailPrice = product.RetailPrice,
                WholesalePrice = product.WholesalePrice,
                CanSell = true
            };
            await _uow.ProductUnits.AddAsync(pUnit, ct);
        }
        await _uow.SaveChangesAsync(ct);

        // Record initial stock if any
        var allStocks = product.GetAllWarehouseStocks();
        bool hasInitialStock = false;
        foreach (var kvp in allStocks)
        {
            if (kvp.Value != 0)
            {
                await RecordInitialStockAsync(product.Id, kvp.Key, kvp.Value, ct);
                hasInitialStock = true;
            }
        }

        if (hasInitialStock)
        {
            await _uow.SaveChangesAsync(ct);
        }

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

        var oldSku = product.Sku;
        var oldName = product.Name;

        if (!string.IsNullOrWhiteSpace(dto.Sku))
        {
            var newSku = dto.Sku.Trim();
            if (!string.Equals(product.Sku, newSku, StringComparison.OrdinalIgnoreCase))
            {
                var skuExists = await _uow.Products.Query()
                    .AnyAsync(p => p.Id != id && p.Sku.ToLower() == newSku.ToLower(), ct);
                if (skuExists)
                {
                    throw new ValidationException($"Mã SKU '{newSku}' đã tồn tại trong hệ thống");
                }
            }
            product.Sku = newSku;
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

        if (product.Sku != oldSku || product.Name != oldName)
        {
            var importItems = await _uow.ImportVoucherItems.Query()
                .Where(i => i.ProductId == id)
                .ToListAsync(ct);
            foreach (var item in importItems)
            {
                item.Sku = product.Sku;
                item.ProductName = product.Name;
                _uow.ImportVoucherItems.Update(item);
            }
        }

        // Multi-UOM sync
        if (dto.Units != null)
        {
            var existingUnits = await _uow.ProductUnits.Query()
                .Where(u => u.ProductId == id)
                .ToListAsync(ct);

            var validUnits = dto.Units
                .Where(u => !string.IsNullOrWhiteSpace(u.UnitName))
                .GroupBy(u => u.UnitName.Trim().ToLowerInvariant())
                .Select(g => g.First())
                .OrderBy(u => u.ConversionRate > 0 ? u.ConversionRate : 1m)
                .ToList();

            var keptNames = validUnits.Select(u => u.UnitName.Trim().ToLowerInvariant()).ToHashSet();
            var usedExistingIds = new HashSet<int>();

            if (validUnits.Count > 0)
            {
                var minRate = validUnits[0].ConversionRate > 0 ? validUnits[0].ConversionRate : 1m;
                for (int idx = 0; idx < validUnits.Count; idx++)
                {
                    var u = validUnits[idx];
                    var unitName = u.UnitName.Trim();
                    var isBase = idx == 0;
                    var normalizedRate = isBase ? 1m : Math.Round((u.ConversionRate > 0 ? u.ConversionRate : 1m) / minRate, 4);

                    // Match by UnitName first to prevent unique index conflicts on (ProductId, UnitName)
                    var existing = existingUnits.FirstOrDefault(x =>
                        !usedExistingIds.Contains(x.Id) &&
                        x.UnitName.Equals(unitName, StringComparison.OrdinalIgnoreCase));

                    // If not found by name, match by Id only if its old name is not being kept by another unit
                    if (existing == null && u.Id.HasValue && u.Id.Value > 0)
                    {
                        existing = existingUnits.FirstOrDefault(x =>
                            x.Id == u.Id.Value &&
                            !usedExistingIds.Contains(x.Id) &&
                            !keptNames.Contains(x.UnitName.ToLowerInvariant()));
                    }

                    if (existing != null)
                    {
                        usedExistingIds.Add(existing.Id);
                        existing.UnitName = unitName;
                        existing.ConversionRate = normalizedRate;
                        existing.IsBaseUnit = isBase;
                        existing.Barcode = u.Barcode?.Trim();
                        existing.RetailPrice = u.RetailPrice;
                        existing.WholesalePrice = u.WholesalePrice;
                        existing.CanSell = u.CanSell;
                        _uow.ProductUnits.Update(existing);
                    }
                    else
                    {
                        var newUnit = new ProductUnit
                        {
                            ProductId = id,
                            UnitName = unitName,
                            ConversionRate = normalizedRate,
                            IsBaseUnit = isBase,
                            Barcode = u.Barcode?.Trim(),
                            RetailPrice = u.RetailPrice,
                            WholesalePrice = u.WholesalePrice,
                            CanSell = u.CanSell
                        };
                        await _uow.ProductUnits.AddAsync(newUnit, ct);
                    }
                }

                // Ensure product.Uom matches one of the valid units (keeps primary display unit if valid, else defaults to smallest unit)
                var currentUom = product.Uom?.Trim() ?? string.Empty;
                if (string.IsNullOrWhiteSpace(currentUom) ||
                    !validUnits.Any(u => u.UnitName.Trim().Equals(currentUom, StringComparison.OrdinalIgnoreCase)))
                {
                    product.Uom = validUnits[0].UnitName.Trim();
                    _uow.Products.Update(product);
                }
            }

            var toRemove = existingUnits.Where(u => !usedExistingIds.Contains(u.Id) && !keptNames.Contains(u.UnitName.ToLowerInvariant())).ToList();
            if (toRemove.Count > 0)
            {
                _uow.ProductUnits.RemoveRange(toRemove);
            }
        }

        await _uow.SaveChangesAsync(ct);

        return await GetByIdAsync(product.Id, ct);
    }

    public async Task<bool> AdjustStockAsync(int id, StockAdjustDto dto, CancellationToken ct = default)
    {
        var product = await _uow.Products.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy sản phẩm với ID {id}");

        var warehouse = string.IsNullOrWhiteSpace(dto.Warehouse) ? DomainConstants.Warehouses.Warehouse1 : dto.Warehouse;
        decimal beforeWhStock = product.GetWarehouseStock(warehouse);

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

        product.SetWarehouseStock(warehouse, afterWhStock);
        var afterTotal = product.TotalStock;
        product.UpdatedAt = DateTime.UtcNow;

        var history = new StockHistory
        {
            ProductId = product.Id,
            Warehouse = warehouse,
            SourceType = DomainConstants.SourceTypes.ManualAdjustment,
            Reason = dto.Reason ?? "Điều chỉnh kho thủ công",
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

    public async Task<List<StockHistoryDto>> GetStockHistoryAsync(int productId, string? month = null, string? fromDate = null, string? toDate = null, CancellationToken ct = default)
    {
        var productExists = await _uow.Products.Query().AnyAsync(p => p.Id == productId, ct);
        if (!productExists)
        {
            throw new NotFoundException($"Không tìm thấy sản phẩm với ID {productId}");
        }

        var query = _uow.StockHistories.Query().Where(h => h.ProductId == productId);

        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            var start = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
            query = query.Where(h => h.ChangeDate >= start);
        }

        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            var end = new DateTime(pTo.Year, pTo.Month, pTo.Day, 23, 59, 59, 999, DateTimeKind.Utc);
            query = query.Where(h => h.ChangeDate <= end);
        }

        if (string.IsNullOrWhiteSpace(fromDate) && string.IsNullOrWhiteSpace(toDate) && !string.IsNullOrWhiteSpace(month))
        {
            if (DateTime.TryParseExact(month.Trim(), "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var parsedDate))
            {
                var start = new DateTime(parsedDate.Year, parsedDate.Month, parsedDate.Day, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddDays(1);
                query = query.Where(h => h.ChangeDate >= start && h.ChangeDate < end);
            }
            else if (DateTime.TryParseExact(month.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsedMonth))
            {
                var start = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddMonths(1);
                query = query.Where(h => h.ChangeDate >= start && h.ChangeDate < end);
            }
        }

        var list = await query.OrderByDescending(h => h.CreatedAt)
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
        WarehouseStocks = p.GetAllWarehouseStocks(),
        TotalStock = p.TotalStock,
        FormattedStock = FormatStockDisplay(p.TotalStock, p.Units, p.Uom),
        ReorderPoint = p.ReorderPoint,
        CreatedAt = p.CreatedAt,
        UpdatedAt = p.UpdatedAt,
        Units = p.Units != null && p.Units.Count > 0
            ? p.Units.OrderBy(u => u.ConversionRate).Select(u => new ProductUnitDto
            {
                Id = u.Id,
                ProductId = u.ProductId,
                UnitName = u.UnitName,
                ConversionRate = u.ConversionRate,
                IsBaseUnit = u.IsBaseUnit,
                Barcode = u.Barcode,
                RetailPrice = u.RetailPrice > 0 ? u.RetailPrice : (u.ConversionRate * p.RetailPrice),
                WholesalePrice = u.WholesalePrice > 0 ? u.WholesalePrice : (u.ConversionRate * p.WholesalePrice),
                CanSell = u.CanSell
            }).ToList()
            : new List<ProductUnitDto>
            {
                new()
                {
                    ProductId = p.Id,
                    UnitName = !string.IsNullOrWhiteSpace(p.Uom) ? p.Uom : "Cái",
                    ConversionRate = 1,
                    IsBaseUnit = true,
                    RetailPrice = p.RetailPrice,
                    WholesalePrice = p.WholesalePrice,
                    CanSell = true
                }
            }
    };

    private static string FormatStockDisplay(decimal totalStock, ICollection<ProductUnit>? units, string? baseUom)
    {
        var viCulture = System.Globalization.CultureInfo.GetCultureInfo("vi-VN");
        var baseName = !string.IsNullOrWhiteSpace(baseUom) ? baseUom : "Cái";
        if (units == null || units.Count <= 1)
        {
            return $"{Math.Round(totalStock, 2).ToString("#,##0.##", viCulture)} {baseName}";
        }

        var sortedUnits = units.OrderBy(u => u.ConversionRate).ToList();
        var parts = new List<string>();
        bool hasBase = sortedUnits.Any(u => u.IsBaseUnit || u.ConversionRate == 1);
        if (!hasBase)
        {
            parts.Add($"{Math.Round(totalStock, 2).ToString("#,##0.##", viCulture)} {baseName}");
        }

        foreach (var u in sortedUnits)
        {
            var rate = u.ConversionRate > 0 ? u.ConversionRate : 1m;
            if (u.IsBaseUnit || rate == 1m)
            {
                parts.Add($"{Math.Round(totalStock, 2).ToString("#,##0.##", viCulture)} {u.UnitName}");
            }
            else
            {
                decimal unitQty = Math.Round(totalStock / rate, 2);
                parts.Add($"{unitQty.ToString("#,##0.##", viCulture)} {u.UnitName}");
            }
        }

        return string.Join(" | ", parts);
    }

    public async Task<List<string>> GetCategoriesAsync(CancellationToken ct = default)
    {
        var categories = await _uow.Products.Query()
            .Where(p => !string.IsNullOrWhiteSpace(p.Category))
            .Select(p => p.Category!)
            .Distinct()
            .OrderBy(c => c)
            .ToListAsync(ct);

        return categories;
    }

    public async Task<EntityLedgerResponseDto> GetLedgerAsync(int productId, string? warehouse = null, string? month = null, string? fromDate = null, string? toDate = null, CancellationToken ct = default)
    {
        var product = await _uow.Products.GetByIdAsync(productId, ct)
            ?? throw new NotFoundException($"Không tìm thấy sản phẩm với ID {productId}");

        var wh = (warehouse ?? "").Trim().ToLower();
        var isAllWh = string.IsNullOrEmpty(wh) || wh == "all" || wh == "overview";

        DateTime? startDate = null;
        DateTime? endDate = null;

        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            startDate = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
        }
        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            endDate = new DateTime(pTo.Year, pTo.Month, pTo.Day, 0, 0, 0, DateTimeKind.Utc).AddDays(1);
        }

        if (string.IsNullOrWhiteSpace(fromDate) && string.IsNullOrWhiteSpace(toDate) && !string.IsNullOrWhiteSpace(month))
        {
            if (DateTime.TryParseExact(month.Trim(), "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var parsedDate))
            {
                startDate = new DateTime(parsedDate.Year, parsedDate.Month, parsedDate.Day, 0, 0, 0, DateTimeKind.Utc);
                endDate = startDate.Value.AddDays(1);
            }
            else if (DateTime.TryParseExact(month.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsedMonth))
            {
                startDate = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                endDate = startDate.Value.AddMonths(1);
            }
        }

        var ledgerItems = new List<EntityLedgerItemDto>();

        // 1. Import voucher items
        var importQuery = _uow.ImportVoucherItems.Query()
            .Include(i => i.ImportVoucher)
                .ThenInclude(v => v.Supplier)
            .Where(i => i.ProductId == productId && i.ImportVoucher.Status != "cancelled");
        if (!isAllWh)
        {
            importQuery = importQuery.Where(i => i.ImportVoucher.Warehouse.ToLower() == wh);
        }
        if (startDate.HasValue)
        {
            importQuery = importQuery.Where(i => i.ImportVoucher.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            importQuery = importQuery.Where(i => i.ImportVoucher.Date < endDate.Value);
        }
        var importItems = await importQuery.ToListAsync(ct);
        foreach (var im in importItems)
        {
            var uName = !string.IsNullOrWhiteSpace(im.UnitName) ? im.UnitName : (product.Uom ?? "cái");
            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = im.Id,
                Date = im.ImportVoucher.Date,
                VoucherNumber = im.ImportVoucher.VoucherNumber,
                VoucherType = "import",
                VoucherTypeLabel = "Phiếu nhập",
                Warehouse = im.ImportVoucher.Warehouse,
                Description = $"Nhập {im.Quantity} {uName} x {im.UnitPrice:N0}₫ từ {im.ImportVoucher.Supplier?.Name ?? "NCC"}",
                ImportQty = im.BaseQuantity > 0 ? im.BaseQuantity : im.Quantity,
                ImportAmount = im.LineTotal,
                ExportQty = 0,
                ExportAmount = 0,
                ReceiptAmount = 0,
                PaymentAmount = 0
            });
        }

        // 2. Export voucher items
        var exportQuery = _uow.ExportVoucherItems.Query()
            .Include(i => i.ExportVoucher)
                .ThenInclude(v => v.Customer)
            .Where(i => i.ProductId == productId && i.ExportVoucher.Status != "cancelled");
        if (!isAllWh)
        {
            exportQuery = exportQuery.Where(i => i.ExportVoucher.Warehouse.ToLower() == wh);
        }
        if (startDate.HasValue)
        {
            exportQuery = exportQuery.Where(i => i.ExportVoucher.Date >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            exportQuery = exportQuery.Where(i => i.ExportVoucher.Date < endDate.Value);
        }
        var exportItems = await exportQuery.ToListAsync(ct);
        foreach (var ex in exportItems)
        {
            var uName = !string.IsNullOrWhiteSpace(ex.UnitName) ? ex.UnitName : (product.Uom ?? "cái");
            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = ex.Id,
                Date = ex.ExportVoucher.Date,
                VoucherNumber = ex.ExportVoucher.VoucherNumber,
                VoucherType = "export",
                VoucherTypeLabel = "Phiếu xuất",
                Warehouse = ex.ExportVoucher.Warehouse,
                Description = $"Xuất {ex.Quantity} {uName} x {ex.SalePrice:N0}₫ cho {ex.ExportVoucher.Customer?.Name ?? "Khách lẻ"}",
                ImportQty = 0,
                ImportAmount = 0,
                ExportQty = ex.BaseQuantity > 0 ? ex.BaseQuantity : ex.Quantity,
                ExportAmount = ex.LineTotal,
                ReceiptAmount = 0,
                PaymentAmount = 0
            });
        }

        // 3. Manual adjustments
        var historyQuery = _uow.StockHistories.Query()
            .Where(h => h.ProductId == productId && h.SourceType == DomainConstants.SourceTypes.ManualAdjustment);
        if (!isAllWh)
        {
            historyQuery = historyQuery.Where(h => h.Warehouse.ToLower() == wh);
        }
        if (startDate.HasValue)
        {
            historyQuery = historyQuery.Where(h => h.ChangeDate >= startDate.Value);
        }
        if (endDate.HasValue)
        {
            historyQuery = historyQuery.Where(h => h.ChangeDate < endDate.Value);
        }
        var histories = await historyQuery.ToListAsync(ct);
        foreach (var h in histories)
        {
            var absQty = Math.Abs(h.Delta);
            var val = absQty * product.UnitCost;
            ledgerItems.Add(new EntityLedgerItemDto
            {
                Id = h.Id,
                Date = h.ChangeDate,
                VoucherNumber = h.ReferenceId ?? $"KK{h.Id:D5}",
                VoucherType = "adjust",
                VoucherTypeLabel = "Kiểm kê",
                Warehouse = h.Warehouse,
                Description = string.IsNullOrWhiteSpace(h.Note) ? (h.Reason ?? "Kiểm kê kho") : $"{h.Reason} - {h.Note}",
                ImportQty = h.Delta > 0 ? h.Delta : 0,
                ImportAmount = h.Delta > 0 ? val : 0,
                ExportQty = h.Delta < 0 ? -h.Delta : 0,
                ExportAmount = h.Delta < 0 ? val : 0,
                ReceiptAmount = 0,
                PaymentAmount = 0
            });
        }

        decimal currentBalance = isAllWh
            ? product.TotalStock
            : (wh == "warehouse1" ? product.StockWarehouse1
               : wh == "warehouse2" ? product.StockWarehouse2
               : wh == "warehouse3" ? product.StockWarehouse3
               : product.GetAllWarehouseStocks().GetValueOrDefault(wh, 0));

        // Tính biến động phát sinh sau kỳ (nếu có endDate)
        decimal netChangeAfterEnd = 0;
        if (endDate.HasValue)
        {
            var impAfterQuery = _uow.ImportVoucherItems.Query()
                .Where(i => i.ProductId == productId && i.ImportVoucher.Status != "cancelled" && i.ImportVoucher.Date >= endDate.Value);
            if (!isAllWh) impAfterQuery = impAfterQuery.Where(i => i.ImportVoucher.Warehouse.ToLower() == wh);
            var impAfter = await impAfterQuery.SumAsync(i => (decimal?)i.Quantity, ct) ?? 0;

            var expAfterQuery = _uow.ExportVoucherItems.Query()
                .Where(i => i.ProductId == productId && i.ExportVoucher.Status != "cancelled" && i.ExportVoucher.Date >= endDate.Value);
            if (!isAllWh) expAfterQuery = expAfterQuery.Where(i => i.ExportVoucher.Warehouse.ToLower() == wh);
            var expAfter = await expAfterQuery.SumAsync(i => (decimal?)i.Quantity, ct) ?? 0;

            var adjAfterQuery = _uow.StockHistories.Query()
                .Where(h => h.ProductId == productId && h.SourceType == DomainConstants.SourceTypes.ManualAdjustment && h.ChangeDate >= endDate.Value);
            if (!isAllWh) adjAfterQuery = adjAfterQuery.Where(h => h.Warehouse.ToLower() == wh);
            var adjAfter = await adjAfterQuery.SumAsync(h => (decimal?)h.Delta, ct) ?? 0;

            netChangeAfterEnd = impAfter - expAfter + adjAfter;
        }

        var closingStock = currentBalance - netChangeAfterEnd;
        var periodNetChange = ledgerItems.Sum(i => i.ImportQty - i.ExportQty);
        var openingStock = closingStock - periodNetChange;

        var sorted = ledgerItems.OrderBy(i => i.Date).ThenBy(i => i.Id).ToList();

        // Nếu có số dư tồn đầu kỳ, thêm bản ghi đầu kỳ vào Thẻ kho
        if (openingStock != 0)
        {
            var earliestDate = sorted.Count > 0 ? sorted[0].Date.AddSeconds(-1) : (startDate ?? DateTime.UtcNow);
            sorted.Insert(0, new EntityLedgerItemDto
            {
                Id = 0,
                Date = earliestDate,
                VoucherNumber = "DUDAY",
                VoucherType = "init",
                VoucherTypeLabel = "Tồn đầu",
                Warehouse = isAllWh ? "Tất cả kho" : wh,
                Description = startDate.HasValue ? "Số lượng tồn đầu kỳ" : "Số lượng tồn ban đầu",
                ImportQty = openingStock > 0 ? openingStock : 0,
                ImportAmount = (openingStock > 0 ? openingStock : 0) * product.UnitCost,
                ExportQty = openingStock < 0 ? -openingStock : 0,
                ExportAmount = (openingStock < 0 ? -openingStock : 0) * product.UnitCost,
                ReceiptAmount = 0,
                PaymentAmount = 0,
                Balance = openingStock
            });
        }

        decimal runningStock = openingStock;
        int startIndex = openingStock != 0 ? 1 : 0;
        for (int i = startIndex; i < sorted.Count; i++)
        {
            var item = sorted[i];
            runningStock += (item.ImportQty - item.ExportQty);
            item.Balance = runningStock;
        }

        var resultList = sorted.OrderByDescending(i => i.Date).ThenByDescending(i => i.Id).ToList();

        return new EntityLedgerResponseDto
        {
            EntityId = product.Id,
            EntityCode = product.Sku,
            EntityName = product.Name,
            Warehouse = isAllWh ? "Tất cả kho" : wh,
            TotalImport = resultList.Sum(i => i.ImportAmount),
            TotalExport = resultList.Sum(i => i.ExportAmount),
            TotalReceipt = resultList.Sum(i => i.ReceiptAmount),
            TotalPayment = resultList.Sum(i => i.PaymentAmount),
            TotalImportQty = resultList.Sum(i => i.ImportQty),
            TotalExportQty = resultList.Sum(i => i.ExportQty),
            CurrentBalance = currentBalance,
            Items = resultList
        };
    }
}
