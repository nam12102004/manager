using DebtManager.Application.Common;
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

    public async Task<List<ImportVoucherDto>> GetImportsAsync(int? supplierId = null, string? month = null, string? fromDate = null, string? toDate = null, string? warehouse = null, string? search = null, CancellationToken ct = default)
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

        if (!string.IsNullOrWhiteSpace(warehouse) && warehouse != "all" && warehouse != "overview")
        {
            query = query.Where(v => v.Warehouse == warehouse.Trim());
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(v => v.VoucherNumber.ToLower().Contains(s) ||
                                     (v.Supplier != null && v.Supplier.Name.ToLower().Contains(s)) ||
                                     (v.Notes != null && v.Notes.ToLower().Contains(s)) ||
                                     v.Items.Any(i =>
                                         (i.Sku != null && i.Sku.ToLower().Contains(s)) ||
                                         (i.ProductName != null && i.ProductName.ToLower().Contains(s)) ||
                                         (i.Product != null && (
                                             (i.Product.Sku != null && i.Product.Sku.ToLower().Contains(s)) ||
                                             (i.Product.Name != null && i.Product.Name.ToLower().Contains(s)) ||
                                             (i.Product.Barcode != null && i.Product.Barcode.ToLower().Contains(s))
                                         ))
                                     ));
        }

        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            var start = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
            query = query.Where(v => v.Date >= start);
        }

        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            var end = new DateTime(pTo.Year, pTo.Month, pTo.Day, 23, 59, 59, 999, DateTimeKind.Utc);
            query = query.Where(v => v.Date <= end);
        }

        if (string.IsNullOrWhiteSpace(fromDate) && string.IsNullOrWhiteSpace(toDate) && !string.IsNullOrWhiteSpace(month))
        {
            if (DateTime.TryParseExact(month.Trim(), "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var parsedDate))
            {
                var start = new DateTime(parsedDate.Year, parsedDate.Month, parsedDate.Day, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddDays(1);
                query = query.Where(v => v.Date >= start && v.Date < end);
            }
            else if (DateTime.TryParseExact(month.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsedMonth))
            {
                var start = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddMonths(1);
                query = query.Where(v => v.Date >= start && v.Date < end);
            }
        }

        var list = await query.OrderByDescending(v => v.Date)
                               .ThenByDescending(v => v.Id)
                               .ToListAsync(ct);

        return list.Select(MapToDto).ToList();
    }

    public async Task<ImportPagedResult> GetPagedImportsAsync(
        int? supplierId = null,
        string? month = null,
        string? date = null,
        string? fromDate = null,
        string? toDate = null,
        string? search = null,
        string? warehouse = null,
        int page = 1,
        int pageSize = 15,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = pageSize > 0 ? pageSize : 15;

        var query = _uow.ImportVouchers.Query()
            .Include(v => v.Supplier)
            .Include(v => v.Items)
                .ThenInclude(i => i.Product)
            .AsQueryable();

        if (supplierId.HasValue)
        {
            query = query.Where(v => v.SupplierId == supplierId.Value);
        }

        if (!string.IsNullOrWhiteSpace(warehouse) && warehouse != "all" && warehouse != "overview")
        {
            query = query.Where(v => v.Warehouse == warehouse.Trim());
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(v => v.VoucherNumber.ToLower().Contains(s) ||
                                     (v.Supplier != null && v.Supplier.Name.ToLower().Contains(s)) ||
                                     (v.Notes != null && v.Notes.ToLower().Contains(s)) ||
                                     v.Items.Any(i =>
                                         (i.Sku != null && i.Sku.ToLower().Contains(s)) ||
                                         (i.ProductName != null && i.ProductName.ToLower().Contains(s)) ||
                                         (i.Product != null && (
                                             (i.Product.Sku != null && i.Product.Sku.ToLower().Contains(s)) ||
                                             (i.Product.Name != null && i.Product.Name.ToLower().Contains(s)) ||
                                             (i.Product.Barcode != null && i.Product.Barcode.ToLower().Contains(s))
                                         ))
                                     ));
        }

        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            var start = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
            query = query.Where(v => v.Date >= start);
        }

        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            var end = new DateTime(pTo.Year, pTo.Month, pTo.Day, 23, 59, 59, 999, DateTimeKind.Utc);
            query = query.Where(v => v.Date <= end);
        }

        if (string.IsNullOrWhiteSpace(fromDate) && string.IsNullOrWhiteSpace(toDate) && !string.IsNullOrWhiteSpace(date) && DateTime.TryParseExact(date.Trim(), "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var pDate))
        {
            var start = new DateTime(pDate.Year, pDate.Month, pDate.Day, 0, 0, 0, DateTimeKind.Utc);
            var end = start.AddDays(1);
            query = query.Where(v => v.Date >= start && v.Date < end);
        }

        if (string.IsNullOrWhiteSpace(fromDate) && string.IsNullOrWhiteSpace(toDate) && string.IsNullOrWhiteSpace(date) && !string.IsNullOrWhiteSpace(month))
        {
            if (DateTime.TryParseExact(month.Trim(), "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out var parsedDate))
            {
                var start = new DateTime(parsedDate.Year, parsedDate.Month, parsedDate.Day, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddDays(1);
                query = query.Where(v => v.Date >= start && v.Date < end);
            }
            else if (DateTime.TryParseExact(month.Trim(), "yyyy-MM", null, System.Globalization.DateTimeStyles.None, out var parsedMonth))
            {
                var start = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddMonths(1);
                query = query.Where(v => v.Date >= start && v.Date < end);
            }
        }

        var totalCount = await query.CountAsync(ct);

        var activeQuery = query.Where(v => v.Status != DomainConstants.VoucherStatuses.Cancelled);
        var totalAmount = await activeQuery.SumAsync(v => (decimal?)v.TotalAmount, ct) ?? 0;
        var totalPaid = await activeQuery.SumAsync(v => (decimal?)v.PaidAmount, ct) ?? 0;
        var totalDebt = await activeQuery.SumAsync(v => (decimal?)v.UnpaidAmount, ct) ?? 0;

        var items = await query.OrderByDescending(v => v.Date)
                               .ThenByDescending(v => v.Id)
                               .Skip((page - 1) * pageSize)
                               .Take(pageSize)
                               .ToListAsync(ct);

        return new ImportPagedResult
        {
            Items = items.Select(MapToDto).ToList(),
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalAmount = totalAmount,
            TotalPaid = totalPaid,
            TotalDebt = totalDebt
        };
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
        var voucherDate = DateTime.UtcNow;
        try
        {
            var supplier = await _uow.Suppliers.GetByIdAsync(dto.SupplierId, ct)
                ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {dto.SupplierId}");

            var warehouse = string.IsNullOrWhiteSpace(dto.Warehouse) ? DomainConstants.Warehouses.Warehouse1 : dto.Warehouse;
            voucherDate = dto.Date.HasValue
                ? (dto.Date.Value.TimeOfDay == TimeSpan.Zero ? dto.Date.Value.Date.Add(DateTime.UtcNow.TimeOfDay) : dto.Date.Value)
                : DateTime.UtcNow;
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

                var convRate = itemDto.ConversionRate.HasValue && itemDto.ConversionRate.Value > 0 ? itemDto.ConversionRate.Value : 1m;
                var baseQty = itemDto.Quantity * convRate;

                var lineTotal = itemDto.Quantity * itemDto.UnitPrice;
                subtotal += lineTotal;

                var voucherItem = new ImportVoucherItem
                {
                    ImportVoucher = voucher,
                    ProductId = product.Id,
                    ProductName = product.Name,
                    Sku = product.Sku,
                    Quantity = itemDto.Quantity,
                    UnitName = itemDto.UnitName ?? product.Uom,
                    ConversionRate = convRate,
                    BaseQuantity = baseQty,
                    UnitPrice = itemDto.UnitPrice,
                    LineTotal = lineTotal
                };
                voucher.Items.Add(voucherItem);

                // Add stock in base unit
                decimal beforeWhStock = product.GetWarehouseStock(warehouse);
                var delta = baseQty; // Positive for import
                var afterWhStock = beforeWhStock + delta;
                var beforeTotal = product.TotalStock;

                product.SetWarehouseStock(warehouse, afterWhStock);
                var afterTotal = product.TotalStock;
                product.UpdatedAt = DateTime.UtcNow;
                _uow.Products.Update(product);

                // Stock history
                var reasonDesc = convRate > 1
                    ? $"Nhập hàng theo phiếu {voucherNumber} ({itemDto.Quantity} {itemDto.UnitName} = {baseQty} {product.Uom ?? "đv"})"
                    : $"Nhập hàng theo phiếu {voucherNumber}";

                await _uow.StockHistories.AddAsync(new StockHistory
                {
                    ProductId = product.Id,
                    Warehouse = warehouse,
                    SourceType = DomainConstants.SourceTypes.Import,
                    ReferenceType = DomainConstants.ReferenceTypes.ImportVoucher,
                    ReferenceId = voucherNumber,
                    Reason = reasonDesc,
                    BeforeWarehouseStock = beforeWhStock,
                    Delta = delta,
                    AfterWarehouseStock = afterWhStock,
                    BeforeTotalStock = beforeTotal,
                    AfterTotalStock = afterTotal,
                    ChangeDate = voucherDate,
                    CreatedAt = voucherDate
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

            // 1. Ghi nhận toàn bộ giá trị hàng nhập vào công nợ NCC (Nợ phải trả tăng, debt âm hơn: -TotalAmount)
            if (totalAmount > 0)
            {
                var delta = -totalAmount; // Negative debt = we owe supplier
                var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                    await DebtHelper.ApplySupplierDebtAsync(_uow, supplier.Id, warehouse, delta, ct);

                await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                {
                    SupplierId = supplier.Id,
                    Warehouse = warehouse,
                    SourceType = DomainConstants.SourceTypes.Import,
                    ReferenceType = DomainConstants.ReferenceTypes.ImportVoucher,
                    ReferenceId = voucherNumber,
                    Reason = $"Ghi nhận nợ phải trả theo phiếu nhập {voucherNumber}",
                    BeforeDebt = beforeTotalDebt,
                    Delta = delta,
                    AfterDebt = afterTotalDebt,
                    CreatedAt = voucherDate
                }, ct);
            }

            // 2. Tự động ghi nhận Phiếu chi (Payment) và giảm nợ phải trả NCC cho khoản thanh toán ngay (Nợ phải trả giảm, debt dương lên về 0: +PaidAmount)
            if (paidAmount > 0)
            {
                var paymentNumber = $"PC{voucherDate:yyyyMMdd}-{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000000):D6}";
                var payment = new Payment
                {
                    PaymentNumber = paymentNumber,
                    Date = voucherDate,
                    Warehouse = warehouse,
                    SupplierId = supplier.Id,
                    Supplier = supplier,
                    Amount = paidAmount,
                    Method = "bank_transfer",
                    Status = DomainConstants.VoucherStatuses.Confirmed,
                    RelatedVoucherType = "import_voucher",
                    RelatedVoucherId = voucherNumber,
                    Notes = $"Thanh toán tiền nhập hàng theo phiếu {voucherNumber}",
                    CreatedAt = voucherDate
                };
                await _uow.Payments.AddAsync(payment, ct);

                var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                    await DebtHelper.ApplySupplierDebtAsync(_uow, supplier.Id, warehouse, paidAmount, ct);

                await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                {
                    SupplierId = supplier.Id,
                    Warehouse = warehouse,
                    SourceType = DomainConstants.SourceTypes.Payment,
                    ReferenceType = DomainConstants.ReferenceTypes.Payment,
                    ReferenceId = paymentNumber,
                    Reason = $"Thanh toán tiền nhập hàng theo phiếu {voucherNumber}",
                    BeforeDebt = beforeTotalDebt,
                    Delta = paidAmount,
                    AfterDebt = afterTotalDebt,
                    CreatedAt = voucherDate.AddMilliseconds(1)
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
        var voucherDate = DateTime.UtcNow;
        try
        {
            if (action.Equals("cancel", StringComparison.OrdinalIgnoreCase))
            {
                if (voucher.Status == DomainConstants.VoucherStatuses.Cancelled) return true;

                // Deduct stock using base quantity
                foreach (var item in voucher.Items)
                {
                    var product = await _uow.Products.GetByIdAsync(item.ProductId, ct);
                    if (product == null) continue;

                    var rate = item.ConversionRate > 0 ? item.ConversionRate : 1m;
                    var baseQty = item.BaseQuantity > 0 ? item.BaseQuantity : (item.Quantity * rate);

                    decimal beforeWhStock = product.GetWarehouseStock(voucher.Warehouse);
                    var delta = -baseQty;
                    var afterWhStock = beforeWhStock + delta;
                    var beforeTotal = product.TotalStock;

                    product.SetWarehouseStock(voucher.Warehouse, afterWhStock);
                    var afterTotal = product.TotalStock;
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
                        CreatedAt = voucherDate
                    }, ct);
                }

                // Reverse Supplier Debt
                if (voucher.SupplierId > 0)
                {
                    // Hoàn lại tiền hàng: giảm nợ phải trả (+TotalAmount)
                    if (voucher.TotalAmount > 0)
                    {
                        var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                            await DebtHelper.ApplySupplierDebtAsync(_uow, voucher.SupplierId, voucher.Warehouse, voucher.TotalAmount, ct);

                        await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                        {
                            SupplierId = voucher.SupplierId,
                            Warehouse = voucher.Warehouse,
                            SourceType = "import_cancelled",
                            ReferenceType = DomainConstants.ReferenceTypes.ImportVoucher,
                            ReferenceId = voucher.VoucherNumber,
                            Reason = $"Hủy nợ phải trả do hủy phiếu nhập {voucher.VoucherNumber}",
                            BeforeDebt = beforeTotalDebt,
                            Delta = voucher.TotalAmount,
                            AfterDebt = afterTotalDebt,
                            CreatedAt = voucherDate
                        }, ct);
                    }

                    // Hoàn lại khoản chi trả ngay: tăng lại nợ phải trả (-PaidAmount)
                    if (voucher.PaidAmount > 0)
                    {
                        var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                            await DebtHelper.ApplySupplierDebtAsync(_uow, voucher.SupplierId, voucher.Warehouse, -voucher.PaidAmount, ct);

                        await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                        {
                            SupplierId = voucher.SupplierId,
                            Warehouse = voucher.Warehouse,
                            SourceType = "payment_cancelled",
                            ReferenceType = DomainConstants.ReferenceTypes.Payment,
                            ReferenceId = voucher.VoucherNumber,
                            Reason = $"Hủy chi tiền trả ngay do hủy phiếu nhập {voucher.VoucherNumber}",
                            BeforeDebt = beforeTotalDebt,
                            Delta = -voucher.PaidAmount,
                            AfterDebt = afterTotalDebt,
                            CreatedAt = voucherDate.AddMilliseconds(1)
                        }, ct);
                    }
                }

                voucher.Status = DomainConstants.VoucherStatuses.Cancelled;
                voucher.CancelledAt = DateTime.UtcNow;

                // Hủy phiếu chi gắn với phiếu nhập nếu có
                var linkedPayments = await _uow.Payments.Query()
                    .Where(p => p.RelatedVoucherId == voucher.VoucherNumber && p.RelatedVoucherType == "import_voucher")
                    .ToListAsync(ct);
                foreach (var p in linkedPayments)
                {
                    p.Status = DomainConstants.VoucherStatuses.Cancelled;
                    p.CancelledAt = DateTime.UtcNow;
                    _uow.Payments.Update(p);
                }
            }
            else if (action.Equals("restore", StringComparison.OrdinalIgnoreCase))
            {
                if (voucher.Status == DomainConstants.VoucherStatuses.Confirmed) return true;

                // Re-add stock
                foreach (var item in voucher.Items)
                {
                    var product = await _uow.Products.GetByIdAsync(item.ProductId, ct);
                    if (product == null) continue;

                    var rate = item.ConversionRate > 0 ? item.ConversionRate : 1m;
                    var baseQty = item.BaseQuantity > 0 ? item.BaseQuantity : (item.Quantity * rate);

                    decimal beforeWhStock = product.GetWarehouseStock(voucher.Warehouse);
                    var delta = baseQty;
                    var afterWhStock = beforeWhStock + delta;
                    var beforeTotal = product.TotalStock;

                    product.SetWarehouseStock(voucher.Warehouse, afterWhStock);
                    var afterTotal = product.TotalStock;
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
                        CreatedAt = voucherDate
                    }, ct);
                }

                // Re-add Supplier Debt
                if (voucher.SupplierId > 0)
                {
                    if (voucher.TotalAmount > 0)
                    {
                        var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                            await DebtHelper.ApplySupplierDebtAsync(_uow, voucher.SupplierId, voucher.Warehouse, -voucher.TotalAmount, ct);

                        await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                        {
                            SupplierId = voucher.SupplierId,
                            Warehouse = voucher.Warehouse,
                            SourceType = "import_restored",
                            ReferenceType = DomainConstants.ReferenceTypes.ImportVoucher,
                            ReferenceId = voucher.VoucherNumber,
                            Reason = $"Tăng lại nợ phải trả do khôi phục phiếu nhập {voucher.VoucherNumber}",
                            BeforeDebt = beforeTotalDebt,
                            Delta = -voucher.TotalAmount,
                            AfterDebt = afterTotalDebt,
                            CreatedAt = voucherDate
                        }, ct);
                    }

                    if (voucher.PaidAmount > 0)
                    {
                        var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                            await DebtHelper.ApplySupplierDebtAsync(_uow, voucher.SupplierId, voucher.Warehouse, voucher.PaidAmount, ct);

                        var paymentNumber = $"PC{voucher.Date:yyyyMMdd}-{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000000):D6}";
                        var existingPayment = await _uow.Payments.Query()
                            .FirstOrDefaultAsync(p => p.RelatedVoucherId == voucher.VoucherNumber && p.RelatedVoucherType == "import_voucher", ct);
                        if (existingPayment != null)
                        {
                            paymentNumber = existingPayment.PaymentNumber;
                        }

                        await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                        {
                            SupplierId = voucher.SupplierId,
                            Warehouse = voucher.Warehouse,
                            SourceType = DomainConstants.SourceTypes.Payment,
                            ReferenceType = DomainConstants.ReferenceTypes.Payment,
                            ReferenceId = paymentNumber,
                            Reason = $"Chi tiền thanh toán do khôi phục phiếu nhập {voucher.VoucherNumber}",
                            BeforeDebt = beforeTotalDebt,
                            Delta = voucher.PaidAmount,
                            AfterDebt = afterTotalDebt,
                            CreatedAt = voucherDate.AddMilliseconds(1)
                        }, ct);
                    }
                }

                voucher.Status = DomainConstants.VoucherStatuses.Confirmed;
                voucher.CancelledAt = null;

                // Khôi phục phiếu chi gắn với phiếu nhập nếu có
                var linkedPayments = await _uow.Payments.Query()
                    .Where(p => p.RelatedVoucherId == voucher.VoucherNumber && p.RelatedVoucherType == "import_voucher")
                    .ToListAsync(ct);
                foreach (var p in linkedPayments)
                {
                    p.Status = DomainConstants.VoucherStatuses.Confirmed;
                    p.CancelledAt = null;
                    _uow.Payments.Update(p);
                }
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

            var linkedPayments = await _uow.Payments.Query()
                .Where(p => p.RelatedVoucherId == voucher.VoucherNumber && p.RelatedVoucherType == "import_voucher")
                .ToListAsync(ct);
            if (linkedPayments.Count > 0)
            {
                _uow.Payments.RemoveRange(linkedPayments);
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
            UnitName = i.UnitName,
            ConversionRate = i.ConversionRate,
            BaseQuantity = i.BaseQuantity,
            UnitPrice = i.UnitPrice,
            LineTotal = i.LineTotal,
            Uom = i.Product?.Uom ?? string.Empty
        }).ToList()
    };
}
