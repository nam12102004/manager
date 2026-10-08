using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.DTOs.ImportVouchers;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Common;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Services;

public class ImportService : IImportService
{
    private readonly IUnitOfWork _uow;

    public ImportService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<List<ImportVoucherDto>> GetImportsAsync(int? supplierId = null, string? month = null, CancellationToken ct = default)
    {
        var query = _uow.ImportVouchers.Query()
            .Include(v => v.Supplier)
            .Include(v => v.Items)
                .ThenInclude(i => i.Product)
            .AsQueryable();

        if (supplierId.HasValue)
        {
            query = query.Where(v => v.SupplierId == supplierId.Value);
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

    public async Task<ImportVoucherDto> GetByIdAsync(long id, CancellationToken ct = default)
    {
        var voucher = await _uow.ImportVouchers.Query()
            .Include(v => v.Supplier)
            .Include(v => v.Items)
                .ThenInclude(i => i.Product)
            .FirstOrDefaultAsync(v => v.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu nhập có ID {id}");

        return MapToDto(voucher);
    }

    public async Task<ImportVoucherDto> CreateImportAsync(CreateImportDto dto, CancellationToken ct = default)
    {
        if (dto.Items == null || dto.Items.Count == 0)
        {
            throw new ValidationException("Phiếu nhập phải có ít nhất 1 sản phẩm");
        }

        await _uow.BeginTransactionAsync(ct);
        try
        {
            var supplier = await _uow.Suppliers.GetByIdAsync(dto.SupplierId, ct)
                ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {dto.SupplierId}");

            var warehouse = string.IsNullOrWhiteSpace(dto.Warehouse) ? DomainConstants.Warehouses.Warehouse1 : dto.Warehouse;
            var voucherDate = dto.Date ?? DateTime.UtcNow;
            var voucherNumber = $"PN{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000000):D6}";

            var voucher = new ImportVoucher
            {
                VoucherNumber = voucherNumber,
                Date = voucherDate,
                Warehouse = warehouse,
                SupplierId = supplier.Id,
                Status = DomainConstants.VoucherStatuses.Confirmed,
                Notes = dto.Notes?.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            decimal subtotal = 0;

            foreach (var itemDto in dto.Items)
            {
                var product = await _uow.Products.GetByIdAsync(itemDto.ProductId, ct)
                    ?? throw new InvalidOperationException($"Không tìm thấy sản phẩm với ID {itemDto.ProductId}");

                var lineTotal = itemDto.Quantity * itemDto.UnitPrice;
                subtotal += lineTotal;

                var voucherItem = new ImportVoucherItem
                {
                    ImportVoucher = voucher,
                    ProductId = product.Id,
                    ProductName = product.Name,
                    Sku = product.Sku,
                    Quantity = itemDto.Quantity,
                    UnitPrice = itemDto.UnitPrice,
                    LineTotal = lineTotal
                };
                voucher.Items.Add(voucherItem);

                // Add stock
                decimal beforeWhStock = warehouse switch
                {
                    DomainConstants.Warehouses.Warehouse2 => product.StockWarehouse2,
                    DomainConstants.Warehouses.Warehouse3 => product.StockWarehouse3,
                    _ => product.StockWarehouse1
                };

                var delta = itemDto.Quantity; // Positive for import
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

                // Stock history
                await _uow.StockHistories.AddAsync(new StockHistory
                {
                    ProductId = product.Id,
                    Warehouse = warehouse,
                    SourceType = DomainConstants.SourceTypes.Import,
                    ReferenceType = DomainConstants.ReferenceTypes.ImportVoucher,
                    ReferenceId = voucherNumber,
                    Reason = $"Nhập hàng theo phiếu {voucherNumber}",
                    BeforeWarehouseStock = beforeWhStock,
                    Delta = delta,
                    AfterWarehouseStock = afterWhStock,
                    BeforeTotalStock = beforeTotal,
                    AfterTotalStock = afterTotal,
                    ChangeDate = voucherDate,
                    CreatedAt = DateTime.UtcNow
                }, ct);
            }

            var discountAmount = Math.Clamp(dto.DiscountAmount, 0, subtotal);
            var totalAmount = Math.Max(0, subtotal - discountAmount);
            var paidAmount = Math.Min(totalAmount, Math.Max(0, dto.PaidAmount));
            var unpaidAmount = Math.Max(0, totalAmount - paidAmount);

            voucher.SubtotalAmount = subtotal;
            voucher.DiscountAmount = discountAmount;
            voucher.TotalAmount = totalAmount;
            voucher.PaidAmount = paidAmount;
            voucher.UnpaidAmount = unpaidAmount;

            // Supplier debt: -unpaidAmount
            if (unpaidAmount > 0)
            {
                var beforeDebt = supplier.Debt;
                var delta = -unpaidAmount; // Negative debt = we owe supplier
                var afterDebt = beforeDebt + delta;
                supplier.Debt = afterDebt;
                supplier.UpdatedAt = DateTime.UtcNow;
                _uow.Suppliers.Update(supplier);

                await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                {
                    SupplierId = supplier.Id,
                    SourceType = DomainConstants.SourceTypes.Import,
                    ReferenceType = DomainConstants.ReferenceTypes.ImportVoucher,
                    ReferenceId = voucherNumber,
                    Reason = $"Ghi nhận nợ phải trả theo phiếu nhập {voucherNumber}",
                    BeforeDebt = beforeDebt,
                    Delta = delta,
                    AfterDebt = afterDebt,
                    CreatedAt = DateTime.UtcNow
                }, ct);
            }

            await _uow.ImportVouchers.AddAsync(voucher, ct);
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
        var voucher = await _uow.ImportVouchers.Query()
            .Include(v => v.Supplier)
            .Include(v => v.Items)
            .FirstOrDefaultAsync(v => v.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu nhập có ID {id}");

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

                // Deduct stock
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
                        SourceType = "import_cancelled",
                        ReferenceType = DomainConstants.ReferenceTypes.ImportVoucher,
                        ReferenceId = voucher.VoucherNumber,
                        Reason = $"Trừ kho do hủy phiếu nhập {voucher.VoucherNumber}",
                        BeforeWarehouseStock = beforeWhStock,
                        Delta = delta,
                        AfterWarehouseStock = afterWhStock,
                        BeforeTotalStock = beforeTotal,
                        AfterTotalStock = afterTotal,
                        ChangeDate = DateTime.UtcNow,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }

                // Reverse Supplier Debt
                if (voucher.UnpaidAmount > 0 && voucher.Supplier != null)
                {
                    var beforeDebt = voucher.Supplier.Debt;
                    var delta = voucher.UnpaidAmount; // Positive to reduce negative debt
                    var afterDebt = beforeDebt + delta;
                    voucher.Supplier.Debt = afterDebt;
                    voucher.Supplier.UpdatedAt = DateTime.UtcNow;
                    _uow.Suppliers.Update(voucher.Supplier);

                    await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                    {
                        SupplierId = voucher.Supplier.Id,
                        SourceType = "import_cancelled",
                        ReferenceType = DomainConstants.ReferenceTypes.ImportVoucher,
                        ReferenceId = voucher.VoucherNumber,
                        Reason = $"Giảm nợ phải trả do hủy phiếu nhập {voucher.VoucherNumber}",
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
                if (voucher.Status == DomainConstants.VoucherStatuses.Confirmed) return true;

                // Re-add stock
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
                    var delta = item.Quantity;
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
                        SourceType = "import_restored",
                        ReferenceType = DomainConstants.ReferenceTypes.ImportVoucher,
                        ReferenceId = voucher.VoucherNumber,
                        Reason = $"Cộng lại kho do khôi phục phiếu nhập {voucher.VoucherNumber}",
                        BeforeWarehouseStock = beforeWhStock,
                        Delta = delta,
                        AfterWarehouseStock = afterWhStock,
                        BeforeTotalStock = beforeTotal,
                        AfterTotalStock = afterTotal,
                        ChangeDate = DateTime.UtcNow,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }

                // Re-add Supplier Debt
                if (voucher.UnpaidAmount > 0 && voucher.Supplier != null)
                {
                    var beforeDebt = voucher.Supplier.Debt;
                    var delta = -voucher.UnpaidAmount;
                    var afterDebt = beforeDebt + delta;
                    voucher.Supplier.Debt = afterDebt;
                    voucher.Supplier.UpdatedAt = DateTime.UtcNow;
                    _uow.Suppliers.Update(voucher.Supplier);

                    await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                    {
                        SupplierId = voucher.Supplier.Id,
                        SourceType = "import_restored",
                        ReferenceType = DomainConstants.ReferenceTypes.ImportVoucher,
                        ReferenceId = voucher.VoucherNumber,
                        Reason = $"Tăng lại nợ phải trả do khôi phục phiếu nhập {voucher.VoucherNumber}",
                        BeforeDebt = beforeDebt,
                        Delta = delta,
                        AfterDebt = afterDebt,
                        CreatedAt = DateTime.UtcNow
                    }, ct);
                }

                voucher.Status = DomainConstants.VoucherStatuses.Confirmed;
                voucher.CancelledAt = null;
            }

            _uow.ImportVouchers.Update(voucher);
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

    public async Task<bool> DeleteImportAsync(long id, CancellationToken ct = default)
    {
        var voucher = await _uow.ImportVouchers.Query()
            .Include(v => v.Supplier)
            .Include(v => v.Items)
            .FirstOrDefaultAsync(v => v.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu nhập có ID {id}");

        await _uow.BeginTransactionAsync(ct);
        try
        {
            if (voucher.Status == DomainConstants.VoucherStatuses.Confirmed)
            {
                await UpdateStatusAsync(id, "cancel", ct);
            }

            _uow.ImportVoucherItems.RemoveRange(voucher.Items);
            _uow.ImportVouchers.Remove(voucher);
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

    private static ImportVoucherDto MapToDto(ImportVoucher v) => new()
    {
        Id = v.Id,
        VoucherNumber = v.VoucherNumber,
        Date = v.Date,
        Warehouse = v.Warehouse,
        SupplierId = v.SupplierId,
        SupplierName = v.Supplier?.Name ?? string.Empty,
        SubtotalAmount = v.SubtotalAmount,
        DiscountAmount = v.DiscountAmount,
        TotalAmount = v.TotalAmount,
        PaidAmount = v.PaidAmount,
        UnpaidAmount = v.UnpaidAmount,
        Status = v.Status,
        CancelledAt = v.CancelledAt,
        Notes = v.Notes,
        CreatedAt = v.CreatedAt,
        Items = v.Items.Select(i => new ImportVoucherItemDto
        {
            Id = i.Id,
            ProductId = i.ProductId,
            ProductName = i.ProductName,
            Sku = i.Sku,
            Quantity = i.Quantity,
            UnitPrice = i.UnitPrice,
            LineTotal = i.LineTotal
        }).ToList()
    };
}
