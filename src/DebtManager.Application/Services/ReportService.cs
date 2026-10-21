using DebtManager.Application.DTOs.Reports;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Common;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services;

public class ReportService : IReportService
{
    private readonly IUnitOfWork _uow;

    public ReportService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<StockReportResponseDto> GetStockReportAsync(string? month = null, CancellationToken ct = default)
    {
        DateTime start;
        DateTime end;
        string periodLabel;

        if (!string.IsNullOrWhiteSpace(month) && DateTime.TryParseExact(month.Trim(), "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var parsedDate))
        {
            start = new DateTime(parsedDate.Year, parsedDate.Month, parsedDate.Day, 0, 0, 0, DateTimeKind.Utc);
            end = start.AddDays(1);
            periodLabel = $"{start.Year:D4}-{start.Month:D2}-{start.Day:D2}";
        }
        else if (!string.IsNullOrWhiteSpace(month) && DateTime.TryParseExact(month.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsedMonth))
        {
            start = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
            end = start.AddMonths(1);
            periodLabel = $"{start.Year:D4}-{start.Month:D2}";
        }
        else
        {
            var now = DateTime.UtcNow;
            start = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
            end = start.AddMonths(1);
            periodLabel = $"{start.Year:D4}-{start.Month:D2}";
        }

        var products = await _uow.Products.Query().ToListAsync(ct);
        var productIds = products.Select(p => p.Id).ToList();

        // Get all histories after start to calculate delta_month and delta_after
        var histories = await _uow.StockHistories.Query()
            .Where(h => productIds.Contains(h.ProductId) && h.ChangeDate >= start)
            .ToListAsync(ct);

        var response = new StockReportResponseDto
        {
            Month = periodLabel,
            FromDate = start,
            ToDate = end
        };

        foreach (var p in products)
        {
            var pHistories = histories.Where(h => h.ProductId == p.Id).ToList();

            // Total
            var deltaAfter = pHistories.Where(h => h.ChangeDate >= end).Sum(h => h.Delta);
            var monthHistories = pHistories.Where(h => h.ChangeDate >= start && h.ChangeDate < end).ToList();
            var deltaMonth = monthHistories.Sum(h => h.Delta);
            var importStock = monthHistories.Where(h => h.Delta > 0).Sum(h => h.Delta);
            var exportStock = monthHistories.Where(h => h.Delta < 0).Sum(h => -h.Delta);

            var closingStock = p.TotalStock - deltaAfter;
            var openingStock = closingStock - deltaMonth;

            // Warehouse 1
            var wh1After = pHistories.Where(h => h.ChangeDate >= end && h.Warehouse == DomainConstants.Warehouses.Warehouse1).Sum(h => h.Delta);
            var wh1Month = monthHistories.Where(h => h.Warehouse == DomainConstants.Warehouses.Warehouse1).ToList();
            var wh1Closing = p.StockWarehouse1 - wh1After;
            var wh1Opening = wh1Closing - wh1Month.Sum(h => h.Delta);

            // Warehouse 2
            var wh2After = pHistories.Where(h => h.ChangeDate >= end && h.Warehouse == DomainConstants.Warehouses.Warehouse2).Sum(h => h.Delta);
            var wh2Month = monthHistories.Where(h => h.Warehouse == DomainConstants.Warehouses.Warehouse2).ToList();
            var wh2Closing = p.StockWarehouse2 - wh2After;
            var wh2Opening = wh2Closing - wh2Month.Sum(h => h.Delta);

            // Warehouse 3
            var wh3After = pHistories.Where(h => h.ChangeDate >= end && h.Warehouse == DomainConstants.Warehouses.Warehouse3).Sum(h => h.Delta);
            var wh3Month = monthHistories.Where(h => h.Warehouse == DomainConstants.Warehouses.Warehouse3).ToList();
            var wh3Closing = p.StockWarehouse3 - wh3After;
            var wh3Opening = wh3Closing - wh3Month.Sum(h => h.Delta);

            var item = new StockReportItemDto
            {
                ProductId = p.Id,
                Sku = p.Sku,
                Name = p.Name,
                Category = p.Category,
                Uom = p.Uom,
                UnitCost = p.UnitCost,
                WholesalePrice = p.WholesalePrice,
                RetailPrice = p.RetailPrice,
                OpeningStock = openingStock,
                ImportStock = importStock,
                ExportStock = exportStock,
                ClosingStock = closingStock,
                Warehouse1 = new StockReportWarehouseDetailDto
                {
                    OpeningStock = wh1Opening,
                    ImportStock = wh1Month.Where(h => h.Delta > 0).Sum(h => h.Delta),
                    ExportStock = wh1Month.Where(h => h.Delta < 0).Sum(h => -h.Delta),
                    ClosingStock = wh1Closing
                },
                Warehouse2 = new StockReportWarehouseDetailDto
                {
                    OpeningStock = wh2Opening,
                    ImportStock = wh2Month.Where(h => h.Delta > 0).Sum(h => h.Delta),
                    ExportStock = wh2Month.Where(h => h.Delta < 0).Sum(h => -h.Delta),
                    ClosingStock = wh2Closing
                },
                Warehouse3 = new StockReportWarehouseDetailDto
                {
                    OpeningStock = wh3Opening,
                    ImportStock = wh3Month.Where(h => h.Delta > 0).Sum(h => h.Delta),
                    ExportStock = wh3Month.Where(h => h.Delta < 0).Sum(h => -h.Delta),
                    ClosingStock = wh3Closing
                }
            };

            response.Items.Add(item);
            response.TotalCostValue += item.TotalCostValue;
            response.TotalWholesaleValue += item.TotalWholesaleValue;
            response.TotalRetailValue += item.TotalRetailValue;
        }

        return response;
    }

    public async Task<DebtReportResponseDto> GetDebtReportAsync(string? month = null, CancellationToken ct = default)
    {
        DateTime start;
        DateTime end;
        string periodLabel;

        if (!string.IsNullOrWhiteSpace(month) && DateTime.TryParseExact(month.Trim(), "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var parsedDate))
        {
            start = new DateTime(parsedDate.Year, parsedDate.Month, parsedDate.Day, 0, 0, 0, DateTimeKind.Utc);
            end = start.AddDays(1);
            periodLabel = $"{start.Year:D4}-{start.Month:D2}-{start.Day:D2}";
        }
        else if (!string.IsNullOrWhiteSpace(month) && DateTime.TryParseExact(month.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsedMonth))
        {
            start = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
            end = start.AddMonths(1);
            periodLabel = $"{start.Year:D4}-{start.Month:D2}";
        }
        else
        {
            var now = DateTime.UtcNow;
            start = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
            end = start.AddMonths(1);
            periodLabel = $"{start.Year:D4}-{start.Month:D2}";
        }

        var customers = await _uow.Customers.Query().ToListAsync(ct);
        var suppliers = await _uow.Suppliers.Query().ToListAsync(ct);

        var customerHistories = await _uow.CustomerDebtHistories.Query()
            .Where(h => h.CreatedAt >= start)
            .ToListAsync(ct);

        var supplierHistories = await _uow.SupplierDebtHistories.Query()
            .Where(h => h.CreatedAt >= start)
            .ToListAsync(ct);

        var response = new DebtReportResponseDto
        {
            Month = periodLabel,
            FromDate = start,
            ToDate = end
        };

        // Customers
        foreach (var c in customers)
        {
            var cHistories = customerHistories.Where(h => h.CustomerId == c.Id).ToList();
            var deltaAfter = cHistories.Where(h => h.CreatedAt >= end).Sum(h => h.Delta);
            var mHistories = cHistories.Where(h => h.CreatedAt >= start && h.CreatedAt < end).ToList();
            var deltaMonth = mHistories.Sum(h => h.Delta);

            var closingDebt = c.Debt - deltaAfter;
            var openingDebt = closingDebt - deltaMonth;

            var increase = mHistories.Where(h => h.Delta > 0).Sum(h => h.Delta);
            var decrease = mHistories.Where(h => h.Delta < 0).Sum(h => -h.Delta);

            var item = new DebtReportItemDto
            {
                PartnerId = c.Id,
                Code = c.Code,
                Name = c.Name,
                PartnerType = "customer",
                OpeningDebt = openingDebt,
                IncreaseDebt = increase,
                DecreaseDebt = decrease,
                ClosingDebt = closingDebt
            };
            response.Items.Add(item);

            if (openingDebt > 0) response.TotalOpeningReceivable += openingDebt;
            else response.TotalOpeningPayable += -openingDebt;

            if (closingDebt > 0) response.TotalClosingReceivable += closingDebt;
            else response.TotalClosingPayable += -closingDebt;
        }

        // Suppliers
        foreach (var s in suppliers)
        {
            var sHistories = supplierHistories.Where(h => h.SupplierId == s.Id).ToList();
            var deltaAfter = sHistories.Where(h => h.CreatedAt >= end).Sum(h => h.Delta);
            var mHistories = sHistories.Where(h => h.CreatedAt >= start && h.CreatedAt < end).ToList();
            var deltaMonth = mHistories.Sum(h => h.Delta);

            var closingDebt = s.Debt - deltaAfter;
            var openingDebt = closingDebt - deltaMonth;

            var increase = mHistories.Where(h => h.Delta > 0).Sum(h => h.Delta);
            var decrease = mHistories.Where(h => h.Delta < 0).Sum(h => -h.Delta);

            var item = new DebtReportItemDto
            {
                PartnerId = s.Id,
                Code = s.Code,
                Name = s.Name,
                PartnerType = "supplier",
                OpeningDebt = openingDebt,
                IncreaseDebt = increase,
                DecreaseDebt = decrease,
                ClosingDebt = closingDebt
            };
            response.Items.Add(item);

            if (openingDebt > 0) response.TotalOpeningReceivable += openingDebt;
            else response.TotalOpeningPayable += -openingDebt;

            if (closingDebt > 0) response.TotalClosingReceivable += closingDebt;
            else response.TotalClosingPayable += -closingDebt;
        }

        return response;
    }

    public async Task<WarehouseSalesResponseDto> GetWarehouseSalesAsync(
        string? warehouse = null,
        string? month = null,
        string? type = null,
        string? sortBy = null,
        CancellationToken ct = default)
    {
        DateTime? startDate = null;
        DateTime? endDate = null;
        if (!string.IsNullOrWhiteSpace(month) && month != "ALL")
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

        var wh = (warehouse ?? "").Trim().ToLower();
        var isAllWh = string.IsNullOrEmpty(wh) || wh == "all" || wh == "overview";

        // Query active export vouchers with items
        var exportQuery = _uow.ExportVouchers.Query()
            .Include(v => v.Customer)
            .Include(v => v.Items)
                .ThenInclude(i => i.Product)
            .Where(v => v.Status != "cancelled");

        if (!isAllWh)
        {
            exportQuery = exportQuery.Where(v => v.Warehouse.ToLower() == wh);
        }
        if (startDate.HasValue)
        {
            exportQuery = exportQuery.Where(v => v.Date >= startDate.Value.AddDays(-1) && v.Date <= endDate!.Value.AddDays(1));
        }
        var exports = await exportQuery.ToListAsync(ct);

        // Query active import vouchers with items
        var importQuery = _uow.ImportVouchers.Query()
            .Include(v => v.Supplier)
            .Include(v => v.Items)
                .ThenInclude(i => i.Product)
            .Where(v => v.Status != "cancelled");

        if (!isAllWh)
        {
            importQuery = importQuery.Where(v => v.Warehouse.ToLower() == wh);
        }
        if (startDate.HasValue)
        {
            importQuery = importQuery.Where(v => v.Date >= startDate.Value.AddDays(-1) && v.Date <= endDate!.Value.AddDays(1));
        }
        var imports = await importQuery.ToListAsync(ct);

        // 1. Product Sales
        var allProducts = await _uow.Products.Query().ToListAsync(ct);
        var importItemsByProduct = imports
            .SelectMany(v => v.Items)
            .GroupBy(i => i.ProductId)
            .ToDictionary(g => g.Key, g => new { Qty = g.Sum(x => x.Quantity), Amount = g.Sum(x => x.LineTotal) });

        var exportItemsByProduct = exports
            .SelectMany(v => v.Items)
            .GroupBy(i => i.ProductId)
            .ToDictionary(g => g.Key, g => new { Qty = g.Sum(x => x.Quantity), Amount = g.Sum(x => x.LineTotal) });

        var productSales = allProducts.Select(p =>
        {
            var im = importItemsByProduct.GetValueOrDefault(p.Id);
            var ex = exportItemsByProduct.GetValueOrDefault(p.Id);
            decimal stock = isAllWh ? p.TotalStock : (wh == "warehouse1" ? p.StockWarehouse1 : wh == "warehouse2" ? p.StockWarehouse2 : wh == "warehouse3" ? p.StockWarehouse3 : p.GetAllWarehouseStocks().GetValueOrDefault(wh, 0));
            return new WarehouseProductSalesDto
            {
                ProductId = p.Id,
                Sku = p.Sku,
                Name = p.Name,
                Category = p.Category,
                Uom = p.Uom,
                UnitCost = p.UnitCost,
                WholesalePrice = p.WholesalePrice,
                RetailPrice = p.RetailPrice,
                ImportQty = im?.Qty ?? 0,
                ImportAmount = im?.Amount ?? 0,
                ExportQty = ex?.Qty ?? 0,
                ExportAmount = ex?.Amount ?? 0,
                CurrentStock = stock
            };
        }).Where(p => p.ImportQty > 0 || p.ExportQty > 0 || p.CurrentStock != 0).ToList();

        productSales = (sortBy?.ToLower()) switch
        {
            "export_amount_desc" => productSales.OrderByDescending(p => p.ExportAmount).ThenBy(p => p.Name).ToList(),
            "export_amount_asc" => productSales.OrderBy(p => p.ExportAmount).ThenBy(p => p.Name).ToList(),
            "import_amount_desc" => productSales.OrderByDescending(p => p.ImportAmount).ThenBy(p => p.Name).ToList(),
            "import_amount_asc" => productSales.OrderBy(p => p.ImportAmount).ThenBy(p => p.Name).ToList(),
            "export_qty_desc" => productSales.OrderByDescending(p => p.ExportQty).ThenBy(p => p.Name).ToList(),
            "export_qty_asc" => productSales.OrderBy(p => p.ExportQty).ThenBy(p => p.Name).ToList(),
            "import_qty_desc" => productSales.OrderByDescending(p => p.ImportQty).ThenBy(p => p.Name).ToList(),
            "import_qty_asc" => productSales.OrderBy(p => p.ImportQty).ThenBy(p => p.Name).ToList(),
            "name_asc" => productSales.OrderBy(p => p.Name).ToList(),
            "name_desc" => productSales.OrderByDescending(p => p.Name).ToList(),
            _ => productSales.OrderByDescending(p => p.ExportAmount).ThenByDescending(p => p.ImportAmount).ToList()
        };

        // 2. Customer Sales
        var allCustomers = await _uow.Customers.Query().ToListAsync(ct);
        var exportsByCustomer = exports
            .GroupBy(v => v.CustomerId)
            .ToDictionary(g => g.Key, g => new
            {
                Count = g.Count(),
                Amount = g.Sum(x => x.TotalSale),
                Qty = g.SelectMany(x => x.Items).Sum(i => i.Quantity)
            });

        var customerSales = allCustomers.Select(c =>
        {
            var ex = exportsByCustomer.GetValueOrDefault(c.Id);
            return new WarehouseCustomerSalesDto
            {
                CustomerId = c.Id,
                Code = c.Code,
                Name = c.Name,
                Region = c.Region,
                Phone = c.PhonesJson,
                ExportCount = ex?.Count ?? 0,
                ExportAmount = ex?.Amount ?? 0,
                ExportQty = ex?.Qty ?? 0,
                ImportQty = 0,
                ImportAmount = 0
            };
        }).Where(c => c.ExportCount > 0).ToList();

        customerSales = (sortBy?.ToLower()) switch
        {
            "export_amount_desc" => customerSales.OrderByDescending(c => c.ExportAmount).ToList(),
            "export_amount_asc" => customerSales.OrderBy(c => c.ExportAmount).ToList(),
            "export_qty_desc" => customerSales.OrderByDescending(c => c.ExportQty).ToList(),
            "export_qty_asc" => customerSales.OrderBy(c => c.ExportQty).ToList(),
            "count_desc" => customerSales.OrderByDescending(c => c.ExportCount).ToList(),
            "name_asc" => customerSales.OrderBy(c => c.Name).ToList(),
            _ => customerSales.OrderByDescending(c => c.ExportAmount).ToList()
        };

        // 3. Supplier Sales
        var allSuppliers = await _uow.Suppliers.Query().ToListAsync(ct);
        var importsBySupplier = imports
            .GroupBy(v => v.SupplierId)
            .ToDictionary(g => g.Key, g => new
            {
                Count = g.Count(),
                Amount = g.Sum(x => x.TotalAmount),
                Qty = g.SelectMany(x => x.Items).Sum(i => i.Quantity)
            });

        var supplierSales = allSuppliers.Select(s =>
        {
            var im = importsBySupplier.GetValueOrDefault(s.Id);
            return new WarehouseSupplierSalesDto
            {
                SupplierId = s.Id,
                Code = s.Code,
                Name = s.Name,
                Region = s.Region,
                Phone = s.PhonesJson,
                ImportCount = im?.Count ?? 0,
                ImportAmount = im?.Amount ?? 0,
                ImportQty = im?.Qty ?? 0,
                ExportQty = 0,
                ExportAmount = 0
            };
        }).Where(s => s.ImportCount > 0).ToList();

        supplierSales = (sortBy?.ToLower()) switch
        {
            "import_amount_desc" => supplierSales.OrderByDescending(s => s.ImportAmount).ToList(),
            "import_amount_asc" => supplierSales.OrderBy(s => s.ImportAmount).ToList(),
            "import_qty_desc" => supplierSales.OrderByDescending(s => s.ImportQty).ToList(),
            "import_qty_asc" => supplierSales.OrderBy(s => s.ImportQty).ToList(),
            "count_desc" => supplierSales.OrderByDescending(s => s.ImportCount).ToList(),
            "name_asc" => supplierSales.OrderBy(s => s.Name).ToList(),
            _ => supplierSales.OrderByDescending(s => s.ImportAmount).ToList()
        };

        return new WarehouseSalesResponseDto
        {
            Warehouse = isAllWh ? "Tất cả kho" : wh,
            Period = month ?? "Tất cả",
            TotalImportAmount = imports.Sum(v => v.TotalAmount),
            TotalExportAmount = exports.Sum(v => v.TotalSale),
            TotalImportQty = imports.SelectMany(v => v.Items).Sum(i => i.Quantity),
            TotalExportQty = exports.SelectMany(v => v.Items).Sum(i => i.Quantity),
            ProductSales = productSales,
            CustomerSales = customerSales,
            SupplierSales = supplierSales
        };
    }
}
