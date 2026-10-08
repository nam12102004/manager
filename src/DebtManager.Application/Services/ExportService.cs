using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.DTOs.ExportVouchers;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Common;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services;

public class ExportService : IExportService
{
    private readonly IUnitOfWork _uow;

    public ExportService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<List<ExportVoucherDto>> GetExportsAsync(int? customerId = null, string? month = null, CancellationToken ct = default)
    {
        var query = _uow.ExportVouchers.Query()
            .Include(v => v.Customer)
            .Include(v => v.Items)
                .ThenInclude(i => i.Product)
            .AsQueryable();

        if (customerId.HasValue)
        {
            query = query.Where(v => v.CustomerId == customerId.Value);
        }

        if (!string.IsNullOrWhiteSpace(month) && DateTime.TryParseExact(month.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsedMonth))
        {
            var start = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
            var end = start.AddMonths(1);
            query = query.Where(v => v.Date >= start && v.Date < end);
        }

        var list = await query.OrderByDescending(v => v.Date)
                              .ThenByDescending(v => v.Id)
                              .ToListAsync(ct);

        return list.Select(MapToDto).ToList();
    }

    public async Task<ExportVoucherDto> GetByIdAsync(long id, CancellationToken ct = default)
    {
        var voucher = await _uow.ExportVouchers.Query()
            .Include(v => v.Customer)
            .Include(v => v.Items)
                .ThenInclude(i => i.Product)
            .FirstOrDefaultAsync(v => v.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu xuất có ID {id}");

        return MapToDto(voucher);
    }

    public async Task<ExportVoucherDto> CreateExportAsync(CreateExportDto dto, CancellationToken ct = default)
    {
        if (dto.Items == null || dto.Items.Count == 0)
        {
            throw new ValidationException("Phiếu xuất phải có ít nhất 1 sản phẩm");
        }

        await _uow.BeginTransactionAsync(ct);
        try
        {
            var customer = await _uow.Customers.GetByIdAsync(dto.CustomerId, ct)
                ?? throw new NotFoundException($"Không tìm thấy khách hàng với ID {dto.CustomerId}");

            var warehouse = string.IsNullOrWhiteSpace(dto.Warehouse) ? DomainConstants.Warehouses.Warehouse1 : dto.Warehouse;
            var voucherDate = dto.Date ?? DateTime.UtcNow;
            var voucherNumber = $"PX{DateTime.UtcNow:yyyyMMdd}-{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000):D3}";

            var voucher = new ExportVoucher
            {
                VoucherNumber = voucherNumber,
                Date = voucherDate,
                Warehouse = warehouse,
                CustomerId = customer.Id,
                Status = DomainConstants.VoucherStatuses.Active,
                Notes = dto.Notes?.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            decimal subtotalSale = 0;
            decimal totalCost = 0;

            foreach (var itemDto in dto.Items)
            {
                var product = await _uow.Products.GetByIdAsync(itemDto.ProductId, ct)
                    ?? throw new InvalidOperationException($"Không tìm thấy sản phẩm với ID {itemDto.ProductId}");

                var salePrice = itemDto.SalePrice ?? product.RetailPrice;
                var unitCost = product.UnitCost;
                var lineTotal = itemDto.Quantity * salePrice;

                subtotalSale += lineTotal;
                totalCost += itemDto.Quantity * unitCost;

                var voucherItem = new ExportVoucherItem
                {
                    ExportVoucher = voucher,
                    ProductId = product.Id,
                    Quantity = itemDto.Quantity,
                    UnitCost = unitCost,
                    SalePrice = salePrice,
                    LineTotal = lineTotal
                };
                voucher.Items.Add(voucherItem);

                // Deduct stock
                decimal beforeWhStock = warehouse switch
                {
                    DomainConstants.Warehouses.Warehouse2 => product.StockWarehouse2,
                    DomainConstants.Warehouses.Warehouse3 => product.StockWarehouse3,
                    _ => product.StockWarehouse1
                };

                var delta = -itemDto.Quantity;
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
                _uow.Products.Update(product);

                // Log StockHistory
                var stockHistory = new StockHistory
                {
                    ProductId = product.Id,
                    Warehouse = warehouse,
                    SourceType = DomainConstants.SourceTypes.Export,
                    ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                    ReferenceId = voucherNumber,
                    Reason = $"Xuất bán hàng {voucherNumber}",
                    BeforeWarehouseStock = beforeWhStock,
                    Delta = delta,
                    AfterWarehouseStock = afterWhStock,
                    BeforeTotalStock = beforeTotal,
                    AfterTotalStock = afterTotal,
                    ChangeDate = voucherDate,
                    CreatedAt = DateTime.UtcNow
                };
                await _uow.StockHistories.AddAsync(stockHistory, ct);
            }

            // Calculate discounts
            decimal discountAmount = 0;
            if (dto.DiscountPercent.HasValue && dto.DiscountPercent.Value > 0)
            {
                discountAmount = subtotalSale * (dto.DiscountPercent.Value / 100m);
            }
            else if (dto.DiscountValue.HasValue && dto.DiscountValue.Value > 0)
            {
                discountAmount = dto.DiscountValue.Value;
            }
            discountAmount = Math.Clamp(discountAmount, 0, subtotalSale);

            var totalSale = subtotalSale - discountAmount;
            var paidAmount = Math.Min(totalSale, Math.Max(0, dto.PaidAmount));
            var unpaidAmount = Math.Max(0, totalSale - paidAmount);

            voucher.SubtotalSale = subtotalSale;
            voucher.DiscountAmount = discountAmount;
            voucher.TotalCost = totalCost;
            voucher.TotalSale = totalSale;
            voucher.PaidAmount = paidAmount;
            voucher.UnpaidAmount = unpaidAmount;

            // Customer Debt update if unpaid
            if (unpaidAmount > 0)
            {
                var beforeDebt = customer.Debt;
                var afterDebt = beforeDebt + unpaidAmount;
                customer.Debt = afterDebt;
                customer.UpdatedAt = DateTime.UtcNow;
                _uow.Customers.Update(customer);

                var debtHistory = new CustomerDebtHistory
                {
                    CustomerId = customer.Id,
                    SourceType = DomainConstants.SourceTypes.Export,
                    ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                    ReferenceId = voucherNumber,
                    Reason = $"Xuất bán nợ theo phiếu {voucherNumber}",
                    BeforeDebt = beforeDebt,
                    Delta = unpaidAmount,
                    AfterDebt = afterDebt,
                    CreatedAt = DateTime.UtcNow
                };
                await _uow.CustomerDebtHistories.AddAsync(debtHistory, ct);
            }

            await _uow.ExportVouchers.AddAsync(voucher, ct);
            await _uow.SaveChangesAsync(ct);
            await _uow.CommitAsync(ct);

            return MapToDto(voucher);
        }
        catch
        {
            await _uow.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<bool> UpdateStatusAsync(long id, string action, CancellationToken ct = default)
    {
        var voucher = await _uow.ExportVouchers.Query()
            .Include(v => v.Customer)
            .Include(v => v.Items)
            .FirstOrDefaultAsync(v => v.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu xuất có ID {id}");

        if (!action.Equals("cancel", StringComparison.OrdinalIgnoreCase) && !action.Equals("restore", StringComparison.OrdinalIgnoreCase))
        {
            throw new BusinessRuleException($"Hành động '{action}' không được hỗ trợ");
        }

        await _uow.BeginTransactionAsync(ct);
        try
        {
            if (action.Equals("cancel", StringComparison.OrdinalIgnoreCase))
            {
                if (voucher.Status == DomainConstants.VoucherStatuses.Cancelled) return true;

                // Return items to warehouse
                foreach (var item in voucher.Items)
                {
                    var product = await _uow.Products.GetByIdAsync(item.ProductId, ct);
                    if (product == null) continue;

                    decimal beforeWhStock = voucher.Warehouse switch
                    {
                        DomainConstants.Warehouses.Warehouse2 => product.StockWarehouse2,
                        DomainConstants.Warehouses.Warehouse3 => product.StockWarehouse3,
                        _ => product.StockWarehouse1
                    };
                    var delta = item.Quantity; // Restore stock
                    var afterWhStock = beforeWhStock + delta;
                    var beforeTotal = product.TotalStock;
                    var afterTotal = beforeTotal + delta;

                    switch (voucher.Warehouse)
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
                    _uow.Products.Update(product);

                    await _uow.StockHistories.AddAsync(new StockHistory
                    {
                        ProductId = product.Id,
                        Warehouse = voucher.Warehouse,
                        SourceType = "export_cancelled",
                        ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                        ReferenceId = voucher.VoucherNumber,
                        Reason = $"Hoàn kho do hủy phiếu {voucher.VoucherNumber}",
                        BeforeWarehouseStock = beforeWhStock,
                        Delta = delta,
                        AfterWarehouseStock = afterWhStock,
                        BeforeTotalStock = beforeTotal,
                        AfterTotalStock = afterTotal,
                        ChangeDate = DateTime.UtcNow,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }

                // Reverse Customer Debt
                if (voucher.UnpaidAmount > 0 && voucher.Customer != null)
                {
                    var beforeDebt = voucher.Customer.Debt;
                    var delta = -voucher.UnpaidAmount;
                    var afterDebt = beforeDebt + delta;
                    voucher.Customer.Debt = afterDebt;
                    voucher.Customer.UpdatedAt = DateTime.UtcNow;
                    _uow.Customers.Update(voucher.Customer);

                    await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                    {
                        CustomerId = voucher.Customer.Id,
                        SourceType = "export_cancelled",
                        ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                        ReferenceId = voucher.VoucherNumber,
                        Reason = $"Giảm nợ do hủy phiếu {voucher.VoucherNumber}",
                        BeforeDebt = beforeDebt,
                        Delta = delta,
                        AfterDebt = afterDebt,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }

                voucher.Status = DomainConstants.VoucherStatuses.Cancelled;
                voucher.CancelledAt = DateTime.UtcNow;
            }
            else if (action.Equals("restore", StringComparison.OrdinalIgnoreCase))
            {
                if (voucher.Status == DomainConstants.VoucherStatuses.Active) return true;

                // Re-deduct stock
                foreach (var item in voucher.Items)
                {
                    var product = await _uow.Products.GetByIdAsync(item.ProductId, ct);
                    if (product == null) continue;

                    decimal beforeWhStock = voucher.Warehouse switch
                    {
                        DomainConstants.Warehouses.Warehouse2 => product.StockWarehouse2,
                        DomainConstants.Warehouses.Warehouse3 => product.StockWarehouse3,
                        _ => product.StockWarehouse1
                    };
                    var delta = -item.Quantity;
                    var afterWhStock = beforeWhStock + delta;
                    var beforeTotal = product.TotalStock;
                    var afterTotal = beforeTotal + delta;

                    switch (voucher.Warehouse)
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
                    _uow.Products.Update(product);

                    await _uow.StockHistories.AddAsync(new StockHistory
                    {
                        ProductId = product.Id,
                        Warehouse = voucher.Warehouse,
                        SourceType = "export_restored",
                        ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                        ReferenceId = voucher.VoucherNumber,
                        Reason = $"Trừ kho do khôi phục phiếu {voucher.VoucherNumber}",
                        BeforeWarehouseStock = beforeWhStock,
                        Delta = delta,
                        AfterWarehouseStock = afterWhStock,
                        BeforeTotalStock = beforeTotal,
                        AfterTotalStock = afterTotal,
                        ChangeDate = DateTime.UtcNow,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }

                // Re-add Customer Debt
                if (voucher.UnpaidAmount > 0 && voucher.Customer != null)
                {
                    var beforeDebt = voucher.Customer.Debt;
                    var delta = voucher.UnpaidAmount;
                    var afterDebt = beforeDebt + delta;
                    voucher.Customer.Debt = afterDebt;
                    voucher.Customer.UpdatedAt = DateTime.UtcNow;
                    _uow.Customers.Update(voucher.Customer);

                    await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                    {
                        CustomerId = voucher.Customer.Id,
                        SourceType = "export_restored",
                        ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                        ReferenceId = voucher.VoucherNumber,
                        Reason = $"Tăng lại nợ do khôi phục phiếu {voucher.VoucherNumber}",
                        BeforeDebt = beforeDebt,
                        Delta = delta,
                        AfterDebt = afterDebt,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }

                voucher.Status = DomainConstants.VoucherStatuses.Active;
                voucher.CancelledAt = null;
            }

            _uow.ExportVouchers.Update(voucher);
            await _uow.SaveChangesAsync(ct);
            await _uow.CommitAsync(ct);
            return true;
        }
        catch
        {
            await _uow.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<bool> DeleteExportAsync(long id, CancellationToken ct = default)
    {
        var voucher = await _uow.ExportVouchers.Query()
            .Include(v => v.Customer)
            .Include(v => v.Items)
            .FirstOrDefaultAsync(v => v.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu xuất có ID {id}");

        await _uow.BeginTransactionAsync(ct);
        try
        {
            // If still active, cancel/restore stock and debt first
            if (voucher.Status == DomainConstants.VoucherStatuses.Active)
            {
                await UpdateStatusAsync(id, "cancel", ct);
            }

            _uow.ExportVoucherItems.RemoveRange(voucher.Items);
            _uow.ExportVouchers.Remove(voucher);
            await _uow.SaveChangesAsync(ct);
            await _uow.CommitAsync(ct);
            return true;
        }
        catch
        {
            await _uow.RollbackAsync(ct);
            throw;
        }
    }

    private static ExportVoucherDto MapToDto(ExportVoucher v) => new()
    {
        Id = v.Id,
        VoucherNumber = v.VoucherNumber,
        Date = v.Date,
        Warehouse = v.Warehouse,
        CustomerId = v.CustomerId,
        CustomerName = v.Customer?.Name ?? string.Empty,
        SubtotalSale = v.SubtotalSale,
        DiscountAmount = v.DiscountAmount,
        TotalSale = v.TotalSale,
        PaidAmount = v.PaidAmount,
        UnpaidAmount = v.UnpaidAmount,
        TotalCost = v.TotalCost,
        Status = v.Status,
        CancelledAt = v.CancelledAt,
        Notes = v.Notes,
        CreatedAt = v.CreatedAt,
        Items = v.Items.Select(i => new ExportVoucherItemDto
        {
            Id = i.Id,
            ProductId = i.ProductId,
            ProductName = i.Product?.Name ?? string.Empty,
            Sku = i.Product?.Sku ?? string.Empty,
            Quantity = i.Quantity,
            UnitCost = i.UnitCost,
            SalePrice = i.SalePrice,
            LineTotal = i.LineTotal
        }).ToList()
    };
}
