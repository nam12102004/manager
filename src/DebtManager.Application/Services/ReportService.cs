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
        var targetMonth = DateTime.UtcNow;
        if (!string.IsNullOrWhiteSpace(month) && DateTime.TryParseExact(month.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsed))
        {
            targetMonth = parsed;
        }

        var start = new DateTime(targetMonth.Year, targetMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var end = start.AddMonths(1);

        var products = await _uow.Products.Query().ToListAsync(ct);
        var productIds = products.Select(p => p.Id).ToList();

        // Get all histories after start to calculate delta_month and delta_after
        var histories = await _uow.StockHistories.Query()
            .Where(h => productIds.Contains(h.ProductId) && h.ChangeDate >= start)
            .ToListAsync(ct);

        var response = new StockReportResponseDto
        {
            Month = $"{start.Year:D4}-{start.Month:D2}",
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
        var targetMonth = DateTime.UtcNow;
        if (!string.IsNullOrWhiteSpace(month) && DateTime.TryParseExact(month.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsed))
        {
            targetMonth = parsed;
        }

        var start = new DateTime(targetMonth.Year, targetMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var end = start.AddMonths(1);

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
            Month = $"{start.Year:D4}-{start.Month:D2}",
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
}
