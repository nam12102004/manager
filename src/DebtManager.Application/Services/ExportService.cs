using DebtManager.Application.Common;
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

    public async Task<List<ExportVoucherDto>> GetExportsAsync(int? customerId = null, string? month = null, string? fromDate = null, string? toDate = null, string? warehouse = null, int? employeeId = null, string? search = null, int? supplierId = null, CancellationToken ct = default)
    {
        var query = _uow.ExportVouchers.Query()
            .Include(v => v.Customer)
            .Include(v => v.Supplier)
            .Include(v => v.Employee)
            .Include(v => v.Items)
                .ThenInclude(i => i.Product)
            .AsQueryable();

        if (customerId.HasValue)
        {
            query = query.Where(v => v.CustomerId == customerId.Value);
        }

        if (supplierId.HasValue)
        {
            query = query.Where(v => v.SupplierId == supplierId.Value);
        }

        if (employeeId.HasValue)
        {
            query = query.Where(v => v.EmployeeId == employeeId.Value);
        }

        if (!string.IsNullOrWhiteSpace(warehouse) && warehouse != "all" && warehouse != "overview")
        {
            query = query.Where(v => v.Warehouse == warehouse.Trim());
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(v => v.VoucherNumber.ToLower().Contains(s) ||
                                     (v.Customer != null && v.Customer.Name.ToLower().Contains(s)) ||
                                     (v.Supplier != null && v.Supplier.Name.ToLower().Contains(s)) ||
                                     (v.EmployeeName != null && v.EmployeeName.ToLower().Contains(s)) ||
                                     (v.Employee != null && v.Employee.Name.ToLower().Contains(s)) ||
                                     (v.Notes != null && v.Notes.ToLower().Contains(s)) ||
                                     v.Items.Any(i =>
                                         i.Product != null && (
                                             (i.Product.Sku != null && i.Product.Sku.ToLower().Contains(s)) ||
                                             (i.Product.Name != null && i.Product.Name.ToLower().Contains(s)) ||
                                             (i.Product.Barcode != null && i.Product.Barcode.ToLower().Contains(s))
                                         )
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

    public async Task<ExportPagedResult> GetPagedExportsAsync(
        int? customerId = null,
        string? month = null,
        string? date = null,
        string? fromDate = null,
        string? toDate = null,
        string? search = null,
        string? warehouse = null,
        int page = 1,
        int pageSize = 15,
        int? employeeId = null,
        int? supplierId = null,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = pageSize > 0 ? pageSize : 15;

        var query = _uow.ExportVouchers.Query()
            .Include(v => v.Customer)
            .Include(v => v.Supplier)
            .Include(v => v.Employee)
            .Include(v => v.Items)
                .ThenInclude(i => i.Product)
            .AsQueryable();

        if (customerId.HasValue)
        {
            query = query.Where(v => v.CustomerId == customerId.Value);
        }

        if (supplierId.HasValue)
        {
            query = query.Where(v => v.SupplierId == supplierId.Value);
        }

        if (employeeId.HasValue)
        {
            query = query.Where(v => v.EmployeeId == employeeId.Value);
        }

        if (!string.IsNullOrWhiteSpace(warehouse) && warehouse != "all" && warehouse != "overview")
        {
            query = query.Where(v => v.Warehouse == warehouse.Trim());
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(v => v.VoucherNumber.ToLower().Contains(s) ||
                                     (v.Customer != null && v.Customer.Name.ToLower().Contains(s)) ||
                                     (v.Supplier != null && v.Supplier.Name.ToLower().Contains(s)) ||
                                     (v.EmployeeName != null && v.EmployeeName.ToLower().Contains(s)) ||
                                     (v.Employee != null && v.Employee.Name.ToLower().Contains(s)) ||
                                     (v.Notes != null && v.Notes.ToLower().Contains(s)) ||
                                     v.Items.Any(i =>
                                         i.Product != null && (
                                             (i.Product.Sku != null && i.Product.Sku.ToLower().Contains(s)) ||
                                             (i.Product.Name != null && i.Product.Name.ToLower().Contains(s)) ||
                                             (i.Product.Barcode != null && i.Product.Barcode.ToLower().Contains(s))
                                         )
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
        var totalAmount = await activeQuery.SumAsync(v => (decimal?)v.TotalSale, ct) ?? 0;
        var totalPaid = await activeQuery.SumAsync(v => (decimal?)v.PaidAmount, ct) ?? 0;
        var totalDebt = await activeQuery.SumAsync(v => (decimal?)v.UnpaidAmount, ct) ?? 0;
        var totalCost = await activeQuery.SumAsync(v => (decimal?)v.TotalCost, ct) ?? 0;
        var totalProfit = totalAmount - totalCost;

        var items = await query.OrderByDescending(v => v.Date)
                              .ThenByDescending(v => v.Id)
                              .Skip((page - 1) * pageSize)
                              .Take(pageSize)
                              .ToListAsync(ct);

        return new ExportPagedResult
        {
            Items = items.Select(MapToDto).ToList(),
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalSale = totalAmount,
            TotalPaid = totalPaid,
            TotalDebt = totalDebt,
            TotalProfit = totalProfit
        };
    }

    public async Task<ExportVoucherDto> GetByIdAsync(long id, CancellationToken ct = default)
    {
        var voucher = await _uow.ExportVouchers.Query()
            .Include(v => v.Customer)
            .Include(v => v.Supplier)
            .Include(v => v.Employee)
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

        var isSupplier = dto.PartnerType?.ToLower() == "supplier" || (!dto.CustomerId.HasValue && dto.SupplierId.HasValue);

        await _uow.BeginTransactionAsync(ct);
        var voucherDate = DateTime.UtcNow;
        try
        {
            Customer? customer = null;
            Supplier? supplier = null;

            if (isSupplier)
            {
                var suppId = dto.SupplierId ?? throw new ValidationException("Vui lòng chọn nhà cung cấp");
                supplier = await _uow.Suppliers.GetByIdAsync(suppId, ct)
                    ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {suppId}");
            }
            else
            {
                var custId = dto.CustomerId ?? throw new ValidationException("Vui lòng chọn khách hàng");
                customer = await _uow.Customers.GetByIdAsync(custId, ct)
                    ?? throw new NotFoundException($"Không tìm thấy khách hàng với ID {custId}");
            }

            Employee? employee = null;
            string? employeeName = string.IsNullOrWhiteSpace(dto.EmployeeName) ? null : dto.EmployeeName.Trim();
            if (dto.EmployeeId.HasValue && dto.EmployeeId.Value > 0)
            {
                employee = await _uow.Employees.GetByIdAsync(dto.EmployeeId.Value, ct);
                if (employee != null)
                {
                    employeeName = employee.Name;
                }
            }

            var warehouse = string.IsNullOrWhiteSpace(dto.Warehouse) ? DomainConstants.Warehouses.Warehouse1 : dto.Warehouse;
            voucherDate = dto.Date.HasValue
                ? (dto.Date.Value.TimeOfDay == TimeSpan.Zero ? dto.Date.Value.Date.Add(DateTime.UtcNow.TimeOfDay) : dto.Date.Value)
                : DateTime.UtcNow;
            var voucherNumber = $"PX{voucherDate:yyyyMMdd}-{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000):D3}";

            var voucher = new ExportVoucher
            {
                VoucherNumber = voucherNumber,
                Date = voucherDate,
                Warehouse = warehouse,
                PartnerType = isSupplier ? "supplier" : "customer",
                CustomerId = customer?.Id,
                Customer = customer,
                SupplierId = supplier?.Id,
                Supplier = supplier,
                EmployeeId = employee?.Id,
                Employee = employee,
                EmployeeName = employeeName,
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

                var convRate = itemDto.ConversionRate.HasValue && itemDto.ConversionRate.Value > 0 ? itemDto.ConversionRate.Value : 1m;
                var baseQty = itemDto.Quantity * convRate;

                var salePrice = itemDto.SalePrice ?? (convRate > 1 ? product.RetailPrice * convRate : product.RetailPrice);
                var unitCost = product.UnitCost;
                var lineTotal = itemDto.Quantity * salePrice;

                subtotalSale += lineTotal;
                totalCost += baseQty * unitCost;

                var voucherItem = new ExportVoucherItem
                {
                    ExportVoucher = voucher,
                    ProductId = product.Id,
                    Quantity = itemDto.Quantity,
                    UnitName = itemDto.UnitName ?? product.Uom,
                    ConversionRate = convRate,
                    BaseQuantity = baseQty,
                    UnitCost = unitCost,
                    SalePrice = salePrice,
                    LineTotal = lineTotal
                };
                voucher.Items.Add(voucherItem);

                // Deduct stock in base unit
                decimal beforeWhStock = product.GetWarehouseStock(warehouse);
                var delta = -baseQty;
                var afterWhStock = beforeWhStock + delta;
                var beforeTotal = product.TotalStock;

                product.SetWarehouseStock(warehouse, afterWhStock);
                var afterTotal = product.TotalStock;
                product.UpdatedAt = DateTime.UtcNow;
                _uow.Products.Update(product);

                // Log StockHistory
                var partnerDesc = isSupplier ? $"cho NCC {supplier!.Name}" : $"cho KH {customer!.Name}";
                var reasonDesc = convRate > 1
                    ? $"Xuất hàng {partnerDesc} phiếu {voucherNumber} ({itemDto.Quantity} {itemDto.UnitName} = {baseQty} {product.Uom ?? "đv"})"
                    : $"Xuất hàng {partnerDesc} phiếu {voucherNumber}";

                var stockHistory = new StockHistory
                {
                    ProductId = product.Id,
                    Warehouse = warehouse,
                    SourceType = DomainConstants.SourceTypes.Export,
                    ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                    ReferenceId = voucherNumber,
                    Reason = reasonDesc,
                    BeforeWarehouseStock = beforeWhStock,
                    Delta = delta,
                    AfterWarehouseStock = afterWhStock,
                    BeforeTotalStock = beforeTotal,
                    AfterTotalStock = afterTotal,
                    ChangeDate = voucherDate,
                    CreatedAt = voucherDate
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

            // Debt & Receipt handling
            if (isSupplier)
            {
                // Returning/Exporting to supplier reduces what we owe supplier (+totalSale on supplier debt)
                if (totalSale > 0)
                {
                    var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                        await DebtHelper.ApplySupplierDebtAsync(_uow, supplier!.Id, warehouse, totalSale, ct);

                    await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                    {
                        SupplierId = supplier.Id,
                        Warehouse = warehouse,
                        SourceType = DomainConstants.SourceTypes.Export,
                        ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                        ReferenceId = voucherNumber,
                        Reason = $"Xuất trả hàng cho NCC theo phiếu {voucherNumber}",
                        BeforeDebt = beforeTotalDebt,
                        Delta = totalSale,
                        AfterDebt = afterTotalDebt,
                        CreatedAt = voucherDate
                    }, ct);
                }

                // If supplier refunded cash immediately: decreases supplier debt (-paidAmount)
                if (paidAmount > 0)
                {
                    var receiptNumber = $"PT{voucherDate:yyyyMMdd}-{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000000):D6}";
                    var receipt = new Receipt
                    {
                        ReceiptNumber = receiptNumber,
                        Date = voucherDate,
                        Warehouse = warehouse,
                        SupplierId = supplier!.Id,
                        Supplier = supplier,
                        Amount = paidAmount,
                        Method = "cash",
                        RelatedVoucherType = "export_voucher",
                        RelatedVoucherId = voucherNumber,
                        Notes = $"Thu tiền hoàn trả từ NCC theo phiếu xuất {voucherNumber}",
                        CreatedAt = voucherDate
                    };
                    await _uow.Receipts.AddAsync(receipt, ct);

                    var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                        await DebtHelper.ApplySupplierDebtAsync(_uow, supplier.Id, warehouse, -paidAmount, ct);

                    await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                    {
                        SupplierId = supplier.Id,
                        Warehouse = warehouse,
                        SourceType = DomainConstants.SourceTypes.Receipt,
                        ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                        ReferenceId = receiptNumber,
                        Reason = $"Thu tiền hoàn trả từ NCC theo phiếu xuất {voucherNumber}",
                        BeforeDebt = beforeTotalDebt,
                        Delta = -paidAmount,
                        AfterDebt = afterTotalDebt,
                        CreatedAt = voucherDate.AddMilliseconds(1)
                    }, ct);
                }
            }
            else
            {
                // Customer debt: customer owes us (+totalSale)
                if (totalSale > 0)
                {
                    var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                        await DebtHelper.ApplyCustomerDebtAsync(_uow, customer!.Id, warehouse, totalSale, ct);

                    var debtHistory = new CustomerDebtHistory
                    {
                        CustomerId = customer.Id,
                        Customer = customer,
                        Warehouse = warehouse,
                        SourceType = DomainConstants.SourceTypes.Export,
                        ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                        ReferenceId = voucherNumber,
                        Reason = $"Xuất bán hàng theo phiếu {voucherNumber}",
                        BeforeDebt = beforeTotalDebt,
                        Delta = totalSale,
                        AfterDebt = afterTotalDebt,
                        CreatedAt = voucherDate
                    };
                    await _uow.CustomerDebtHistories.AddAsync(debtHistory, ct);
                }

                // If paid immediately: customer paid us cash (-paidAmount)
                if (paidAmount > 0)
                {
                    var receiptNumber = $"PT{voucherDate:yyyyMMdd}-{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000000):D6}";
                    var receipt = new Receipt
                    {
                        ReceiptNumber = receiptNumber,
                        Date = voucherDate,
                        Warehouse = warehouse,
                        CustomerId = customer!.Id,
                        Customer = customer,
                        Amount = paidAmount,
                        Method = "cash",
                        RelatedVoucherType = "export_voucher",
                        RelatedVoucherId = voucherNumber,
                        Notes = $"Thu tiền bán hàng ngay theo phiếu xuất {voucherNumber}",
                        CreatedAt = voucherDate
                    };
                    await _uow.Receipts.AddAsync(receipt, ct);

                    var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                        await DebtHelper.ApplyCustomerDebtAsync(_uow, customer.Id, warehouse, -paidAmount, ct);

                    var receiptHistory = new CustomerDebtHistory
                    {
                        CustomerId = customer.Id,
                        Customer = customer,
                        Warehouse = warehouse,
                        SourceType = DomainConstants.SourceTypes.Receipt,
                        ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                        ReferenceId = receiptNumber,
                        Reason = $"Thu tiền bán hàng ngay theo phiếu xuất {voucherNumber}",
                        BeforeDebt = beforeTotalDebt,
                        Delta = -paidAmount,
                        AfterDebt = afterTotalDebt,
                        CreatedAt = voucherDate.AddMilliseconds(1)
                    };
                    await _uow.CustomerDebtHistories.AddAsync(receiptHistory, ct);
                }
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

    public async Task<ExportVoucherDto> UpdateExportAsync(long id, UpdateExportDto dto, CancellationToken ct = default)
    {
        if (dto.Items == null || dto.Items.Count == 0)
        {
            throw new ValidationException("Phiếu xuất phải có ít nhất 1 sản phẩm");
        }

        var voucher = await _uow.ExportVouchers.Query()
            .Include(v => v.Customer)
            .Include(v => v.Supplier)
            .Include(v => v.Employee)
            .Include(v => v.Items)
                .ThenInclude(i => i.Product)
            .FirstOrDefaultAsync(v => v.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu xuất có ID {id}");

        if (voucher.Status == DomainConstants.VoucherStatuses.Cancelled)
        {
            throw new BusinessRuleException("Không thể chỉnh sửa phiếu xuất đã bị hủy. Hãy khôi phục trước khi sửa.");
        }

        await _uow.BeginTransactionAsync(ct);
        var voucherDate = DateTime.UtcNow;
        try
        {
            var oldWarehouse = voucher.Warehouse;
            var oldPartnerType = voucher.PartnerType ?? (voucher.SupplierId.HasValue ? "supplier" : "customer");
            var oldCustomerId = voucher.CustomerId;
            var oldSupplierId = voucher.SupplierId;
            var oldTotalSale = voucher.TotalSale;
            var oldPaidAmount = voucher.PaidAmount;

            // 1. REVERT OLD STOCK
            foreach (var item in voucher.Items)
            {
                var product = await _uow.Products.GetByIdAsync(item.ProductId, ct);
                if (product == null) continue;

                var rate = item.ConversionRate > 0 ? item.ConversionRate : 1m;
                var baseQty = item.BaseQuantity > 0 ? item.BaseQuantity : (item.Quantity * rate);

                decimal beforeWhStock = product.GetWarehouseStock(oldWarehouse);
                var delta = baseQty; // Revert export = restore stock
                var afterWhStock = beforeWhStock + delta;
                var beforeTotal = product.TotalStock;

                product.SetWarehouseStock(oldWarehouse, afterWhStock);
                var afterTotal = product.TotalStock;
                product.UpdatedAt = DateTime.UtcNow;
                _uow.Products.Update(product);

                await _uow.StockHistories.AddAsync(new StockHistory
                {
                    ProductId = product.Id,
                    Warehouse = oldWarehouse,
                    SourceType = "export_updated_revert",
                    ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                    ReferenceId = voucher.VoucherNumber,
                    Reason = $"Hoàn kho dòng cũ do sửa phiếu xuất {voucher.VoucherNumber}",
                    BeforeWarehouseStock = beforeWhStock,
                    Delta = delta,
                    AfterWarehouseStock = afterWhStock,
                    BeforeTotalStock = beforeTotal,
                    AfterTotalStock = afterTotal,
                    ChangeDate = DateTime.UtcNow,
                    CreatedAt = voucherDate
                }, ct);
            }

            // 2. REVERT OLD DEBT & LINKED RECEIPTS
            if (oldPartnerType == "supplier" && oldSupplierId.HasValue)
            {
                if (oldTotalSale > 0)
                {
                    await DebtHelper.ApplySupplierDebtAsync(_uow, oldSupplierId.Value, oldWarehouse, -oldTotalSale, ct);
                }
                if (oldPaidAmount > 0)
                {
                    await DebtHelper.ApplySupplierDebtAsync(_uow, oldSupplierId.Value, oldWarehouse, oldPaidAmount, ct);
                }
            }
            else if (oldCustomerId.HasValue)
            {
                if (oldTotalSale > 0)
                {
                    await DebtHelper.ApplyCustomerDebtAsync(_uow, oldCustomerId.Value, oldWarehouse, -oldTotalSale, ct);
                }
                if (oldPaidAmount > 0)
                {
                    await DebtHelper.ApplyCustomerDebtAsync(_uow, oldCustomerId.Value, oldWarehouse, oldPaidAmount, ct);
                }
            }

            var oldLinkedReceipts = await _uow.Receipts.Query()
                .Where(r => r.RelatedVoucherId == voucher.VoucherNumber && r.RelatedVoucherType == "export_voucher")
                .ToListAsync(ct);
            if (oldLinkedReceipts.Count > 0)
            {
                _uow.Receipts.RemoveRange(oldLinkedReceipts);
            }

            // 3. REMOVE OLD ITEMS
            _uow.ExportVoucherItems.RemoveRange(voucher.Items);
            voucher.Items.Clear();

            // 4. PREPARE NEW PARTNER & DETAILS
            var isNewSupplier = dto.PartnerType?.ToLower() == "supplier" || (!dto.CustomerId.HasValue && dto.SupplierId.HasValue);
            Customer? newCustomer = null;
            Supplier? newSupplier = null;

            if (isNewSupplier)
            {
                var suppId = dto.SupplierId ?? throw new ValidationException("Vui lòng chọn nhà cung cấp");
                newSupplier = await _uow.Suppliers.GetByIdAsync(suppId, ct)
                    ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp với ID {suppId}");
            }
            else
            {
                var custId = dto.CustomerId ?? throw new ValidationException("Vui lòng chọn khách hàng");
                newCustomer = await _uow.Customers.GetByIdAsync(custId, ct)
                    ?? throw new NotFoundException($"Không tìm thấy khách hàng với ID {custId}");
            }

            Employee? employee = null;
            string? employeeName = string.IsNullOrWhiteSpace(dto.EmployeeName) ? null : dto.EmployeeName.Trim();
            if (dto.EmployeeId.HasValue && dto.EmployeeId.Value > 0)
            {
                employee = await _uow.Employees.GetByIdAsync(dto.EmployeeId.Value, ct);
                if (employee != null)
                {
                    employeeName = employee.Name;
                }
            }

            var newWarehouse = string.IsNullOrWhiteSpace(dto.Warehouse) ? DomainConstants.Warehouses.Warehouse1 : dto.Warehouse;
            var newDate = dto.Date.HasValue
                ? (dto.Date.Value.TimeOfDay == TimeSpan.Zero ? dto.Date.Value.Date.Add(DateTime.UtcNow.TimeOfDay) : dto.Date.Value)
                : voucher.Date;

            voucher.Warehouse = newWarehouse;
            voucher.Date = newDate;
            voucher.PartnerType = isNewSupplier ? "supplier" : "customer";
            voucher.CustomerId = newCustomer?.Id;
            voucher.Customer = newCustomer;
            voucher.SupplierId = newSupplier?.Id;
            voucher.Supplier = newSupplier;
            voucher.EmployeeId = employee?.Id;
            voucher.Employee = employee;
            voucher.EmployeeName = employeeName;
            voucher.Notes = dto.Notes?.Trim();

            // 5. ADD NEW ITEMS & APPLY NEW STOCK
            decimal newSubtotalSale = 0;
            decimal newTotalCost = 0;

            foreach (var itemDto in dto.Items)
            {
                var product = await _uow.Products.GetByIdAsync(itemDto.ProductId, ct)
                    ?? throw new InvalidOperationException($"Không tìm thấy sản phẩm với ID {itemDto.ProductId}");

                var convRate = itemDto.ConversionRate.HasValue && itemDto.ConversionRate.Value > 0 ? itemDto.ConversionRate.Value : 1m;
                var baseQty = itemDto.Quantity * convRate;

                var salePrice = itemDto.SalePrice ?? (convRate > 1 ? product.RetailPrice * convRate : product.RetailPrice);
                var unitCost = product.UnitCost;
                var lineTotal = itemDto.Quantity * salePrice;

                newSubtotalSale += lineTotal;
                newTotalCost += baseQty * unitCost;

                var voucherItem = new ExportVoucherItem
                {
                    ExportVoucher = voucher,
                    ProductId = product.Id,
                    Quantity = itemDto.Quantity,
                    UnitName = itemDto.UnitName ?? product.Uom,
                    ConversionRate = convRate,
                    BaseQuantity = baseQty,
                    UnitCost = unitCost,
                    SalePrice = salePrice,
                    LineTotal = lineTotal
                };
                voucher.Items.Add(voucherItem);

                // Deduct stock in base unit
                decimal beforeWhStock = product.GetWarehouseStock(newWarehouse);
                var delta = -baseQty;
                var afterWhStock = beforeWhStock + delta;
                var beforeTotal = product.TotalStock;

                product.SetWarehouseStock(newWarehouse, afterWhStock);
                var afterTotal = product.TotalStock;
                product.UpdatedAt = DateTime.UtcNow;
                _uow.Products.Update(product);

                var partnerDesc = isNewSupplier ? $"cho NCC {newSupplier!.Name}" : $"cho KH {newCustomer!.Name}";
                var reasonDesc = convRate > 1
                    ? $"Cập nhật xuất hàng {partnerDesc} phiếu {voucher.VoucherNumber} ({itemDto.Quantity} {itemDto.UnitName} = {baseQty} {product.Uom ?? "đv"})"
                    : $"Cập nhật xuất hàng {partnerDesc} phiếu {voucher.VoucherNumber}";

                await _uow.StockHistories.AddAsync(new StockHistory
                {
                    ProductId = product.Id,
                    Warehouse = newWarehouse,
                    SourceType = "export_updated",
                    ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                    ReferenceId = voucher.VoucherNumber,
                    Reason = reasonDesc,
                    BeforeWarehouseStock = beforeWhStock,
                    Delta = delta,
                    AfterWarehouseStock = afterWhStock,
                    BeforeTotalStock = beforeTotal,
                    AfterTotalStock = afterTotal,
                    ChangeDate = newDate,
                    CreatedAt = voucherDate
                }, ct);
            }

            decimal newDiscountAmount = 0;
            if (dto.DiscountPercent.HasValue && dto.DiscountPercent.Value > 0)
            {
                newDiscountAmount = newSubtotalSale * (dto.DiscountPercent.Value / 100m);
            }
            else if (dto.DiscountValue.HasValue && dto.DiscountValue.Value > 0)
            {
                newDiscountAmount = dto.DiscountValue.Value;
            }
            newDiscountAmount = Math.Clamp(newDiscountAmount, 0, newSubtotalSale);

            var newTotalSale = newSubtotalSale - newDiscountAmount;
            var newPaidAmount = Math.Min(newTotalSale, Math.Max(0, dto.PaidAmount));
            var newUnpaidAmount = Math.Max(0, newTotalSale - newPaidAmount);

            voucher.SubtotalSale = newSubtotalSale;
            voucher.DiscountAmount = newDiscountAmount;
            voucher.TotalCost = newTotalCost;
            voucher.TotalSale = newTotalSale;
            voucher.PaidAmount = newPaidAmount;
            voucher.UnpaidAmount = newUnpaidAmount;

            // 6. APPLY NEW DEBT & RECEIPT
            if (isNewSupplier)
            {
                if (newTotalSale > 0)
                {
                    var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                        await DebtHelper.ApplySupplierDebtAsync(_uow, newSupplier!.Id, newWarehouse, newTotalSale, ct);

                    await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                    {
                        SupplierId = newSupplier.Id,
                        Warehouse = newWarehouse,
                        SourceType = "export_updated",
                        ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                        ReferenceId = voucher.VoucherNumber,
                        Reason = $"Cập nhật công nợ theo phiếu xuất {voucher.VoucherNumber}",
                        BeforeDebt = beforeTotalDebt,
                        Delta = newTotalSale,
                        AfterDebt = afterTotalDebt,
                        CreatedAt = newDate
                    }, ct);
                }

                if (newPaidAmount > 0)
                {
                    var receiptNumber = $"PT{newDate:yyyyMMdd}-{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000000):D6}";
                    var receipt = new Receipt
                    {
                        ReceiptNumber = receiptNumber,
                        Date = newDate,
                        Warehouse = newWarehouse,
                        SupplierId = newSupplier!.Id,
                        Supplier = newSupplier,
                        Amount = newPaidAmount,
                        Method = "cash",
                        RelatedVoucherType = "export_voucher",
                        RelatedVoucherId = voucher.VoucherNumber,
                        Notes = $"Thu tiền hoàn trả từ NCC theo phiếu xuất {voucher.VoucherNumber} (Đã sửa)",
                        CreatedAt = newDate
                    };
                    await _uow.Receipts.AddAsync(receipt, ct);

                    var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                        await DebtHelper.ApplySupplierDebtAsync(_uow, newSupplier.Id, newWarehouse, -newPaidAmount, ct);

                    await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                    {
                        SupplierId = newSupplier.Id,
                        Warehouse = newWarehouse,
                        SourceType = DomainConstants.SourceTypes.Receipt,
                        ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                        ReferenceId = receiptNumber,
                        Reason = $"Thu tiền hoàn trả từ NCC theo phiếu xuất {voucher.VoucherNumber} (Đã sửa)",
                        BeforeDebt = beforeTotalDebt,
                        Delta = -newPaidAmount,
                        AfterDebt = afterTotalDebt,
                        CreatedAt = newDate.AddMilliseconds(1)
                    }, ct);
                }
            }
            else
            {
                if (newTotalSale > 0)
                {
                    var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                        await DebtHelper.ApplyCustomerDebtAsync(_uow, newCustomer!.Id, newWarehouse, newTotalSale, ct);

                    var debtHistory = new CustomerDebtHistory
                    {
                        CustomerId = newCustomer.Id,
                        Customer = newCustomer,
                        Warehouse = newWarehouse,
                        SourceType = "export_updated",
                        ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                        ReferenceId = voucher.VoucherNumber,
                        Reason = $"Cập nhật công nợ theo phiếu xuất {voucher.VoucherNumber}",
                        BeforeDebt = beforeTotalDebt,
                        Delta = newTotalSale,
                        AfterDebt = afterTotalDebt,
                        CreatedAt = newDate
                    };
                    await _uow.CustomerDebtHistories.AddAsync(debtHistory, ct);
                }

                if (newPaidAmount > 0)
                {
                    var receiptNumber = $"PT{newDate:yyyyMMdd}-{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000000):D6}";
                    var receipt = new Receipt
                    {
                        ReceiptNumber = receiptNumber,
                        Date = newDate,
                        Warehouse = newWarehouse,
                        CustomerId = newCustomer!.Id,
                        Customer = newCustomer,
                        Amount = newPaidAmount,
                        Method = "cash",
                        RelatedVoucherType = "export_voucher",
                        RelatedVoucherId = voucher.VoucherNumber,
                        Notes = $"Thu tiền bán hàng ngay theo phiếu xuất {voucher.VoucherNumber} (Đã sửa)",
                        CreatedAt = newDate
                    };
                    await _uow.Receipts.AddAsync(receipt, ct);

                    var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                        await DebtHelper.ApplyCustomerDebtAsync(_uow, newCustomer.Id, newWarehouse, -newPaidAmount, ct);

                    var receiptHistory = new CustomerDebtHistory
                    {
                        CustomerId = newCustomer.Id,
                        Customer = newCustomer,
                        Warehouse = newWarehouse,
                        SourceType = DomainConstants.SourceTypes.Receipt,
                        ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                        ReferenceId = receiptNumber,
                        Reason = $"Thu tiền bán hàng ngay theo phiếu xuất {voucher.VoucherNumber} (Đã sửa)",
                        BeforeDebt = beforeTotalDebt,
                        Delta = -newPaidAmount,
                        AfterDebt = afterTotalDebt,
                        CreatedAt = newDate.AddMilliseconds(1)
                    };
                    await _uow.CustomerDebtHistories.AddAsync(receiptHistory, ct);
                }
            }

            _uow.ExportVouchers.Update(voucher);
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
            .Include(v => v.Supplier)
            .Include(v => v.Items)
            .FirstOrDefaultAsync(v => v.Id == id, ct)
            ?? throw new NotFoundException($"Không tìm thấy phiếu xuất có ID {id}");

        if (!action.Equals("cancel", StringComparison.OrdinalIgnoreCase) && !action.Equals("restore", StringComparison.OrdinalIgnoreCase))
        {
            throw new BusinessRuleException($"Hành động '{action}' không được hỗ trợ");
        }

        var isSupplier = voucher.PartnerType == "supplier" || (!voucher.CustomerId.HasValue && voucher.SupplierId.HasValue);

        await _uow.BeginTransactionAsync(ct);
        var voucherDate = DateTime.UtcNow;
        try
        {
            if (action.Equals("cancel", StringComparison.OrdinalIgnoreCase))
            {
                if (voucher.Status == DomainConstants.VoucherStatuses.Cancelled) return true;

                // Return items to warehouse using base quantity
                foreach (var item in voucher.Items)
                {
                    var product = await _uow.Products.GetByIdAsync(item.ProductId, ct);
                    if (product == null) continue;

                    var rate = item.ConversionRate > 0 ? item.ConversionRate : 1m;
                    var baseQty = item.BaseQuantity > 0 ? item.BaseQuantity : (item.Quantity * rate);

                    decimal beforeWhStock = product.GetWarehouseStock(voucher.Warehouse);
                    var delta = baseQty; // Restore stock
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
                        CreatedAt = voucherDate
                    }, ct);
                }

                // Reverse Debt
                if (isSupplier && voucher.SupplierId.HasValue)
                {
                    if (voucher.TotalSale > 0)
                    {
                        var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                            await DebtHelper.ApplySupplierDebtAsync(_uow, voucher.SupplierId.Value, voucher.Warehouse, -voucher.TotalSale, ct);

                        await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                        {
                            SupplierId = voucher.SupplierId.Value,
                            Warehouse = voucher.Warehouse,
                            SourceType = "export_cancelled",
                            ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                            ReferenceId = voucher.VoucherNumber,
                            Reason = $"Hủy giảm nợ do hủy phiếu xuất {voucher.VoucherNumber}",
                            BeforeDebt = beforeTotalDebt,
                            Delta = -voucher.TotalSale,
                            AfterDebt = afterTotalDebt,
                            CreatedAt = voucherDate
                        }, ct);
                    }

                    if (voucher.PaidAmount > 0)
                    {
                        var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                            await DebtHelper.ApplySupplierDebtAsync(_uow, voucher.SupplierId.Value, voucher.Warehouse, voucher.PaidAmount, ct);

                        await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                        {
                            SupplierId = voucher.SupplierId.Value,
                            Warehouse = voucher.Warehouse,
                            SourceType = "receipt_cancelled",
                            ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                            ReferenceId = voucher.VoucherNumber,
                            Reason = $"Hủy thu tiền hoàn trả do hủy phiếu xuất {voucher.VoucherNumber}",
                            BeforeDebt = beforeTotalDebt,
                            Delta = voucher.PaidAmount,
                            AfterDebt = afterTotalDebt,
                            CreatedAt = voucherDate.AddMilliseconds(1)
                        }, ct);
                    }
                }
                else if (voucher.CustomerId.HasValue)
                {
                    if (voucher.TotalSale > 0)
                    {
                        var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                            await DebtHelper.ApplyCustomerDebtAsync(_uow, voucher.CustomerId.Value, voucher.Warehouse, -voucher.TotalSale, ct);

                        await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                        {
                            CustomerId = voucher.CustomerId.Value,
                            Warehouse = voucher.Warehouse,
                            SourceType = "export_cancelled",
                            ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                            ReferenceId = voucher.VoucherNumber,
                            Reason = $"Hủy ghi nợ do hủy phiếu xuất {voucher.VoucherNumber}",
                            BeforeDebt = beforeTotalDebt,
                            Delta = -voucher.TotalSale,
                            AfterDebt = afterTotalDebt,
                            CreatedAt = voucherDate
                        }, ct);
                    }

                    if (voucher.PaidAmount > 0)
                    {
                        var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                            await DebtHelper.ApplyCustomerDebtAsync(_uow, voucher.CustomerId.Value, voucher.Warehouse, voucher.PaidAmount, ct);

                        await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                        {
                            CustomerId = voucher.CustomerId.Value,
                            Warehouse = voucher.Warehouse,
                            SourceType = "receipt_cancelled",
                            ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                            ReferenceId = voucher.VoucherNumber,
                            Reason = $"Hủy thu tiền bán ngay do hủy phiếu xuất {voucher.VoucherNumber}",
                            BeforeDebt = beforeTotalDebt,
                            Delta = voucher.PaidAmount,
                            AfterDebt = afterTotalDebt,
                            CreatedAt = voucherDate.AddMilliseconds(1)
                        }, ct);
                    }
                }

                voucher.Status = DomainConstants.VoucherStatuses.Cancelled;
                voucher.CancelledAt = DateTime.UtcNow;

                // Đồng bộ hủy phiếu thu gắn với phiếu xuất nếu có
                var linkedReceipts = await _uow.Receipts.Query()
                    .Where(r => r.RelatedVoucherId == voucher.VoucherNumber && r.RelatedVoucherType == "export_voucher")
                    .ToListAsync(ct);
                if (linkedReceipts.Count > 0)
                {
                    _uow.Receipts.RemoveRange(linkedReceipts);
                }
            }
            else if (action.Equals("restore", StringComparison.OrdinalIgnoreCase))
            {
                if (voucher.Status == DomainConstants.VoucherStatuses.Active) return true;

                // Re-deduct stock
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
                        CreatedAt = voucherDate
                    }, ct);
                }

                // Re-add Debt
                if (isSupplier && voucher.SupplierId.HasValue)
                {
                    if (voucher.TotalSale > 0)
                    {
                        var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                            await DebtHelper.ApplySupplierDebtAsync(_uow, voucher.SupplierId.Value, voucher.Warehouse, voucher.TotalSale, ct);

                        await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                        {
                            SupplierId = voucher.SupplierId.Value,
                            Warehouse = voucher.Warehouse,
                            SourceType = "export_restored",
                            ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                            ReferenceId = voucher.VoucherNumber,
                            Reason = $"Khôi phục giảm nợ NCC do khôi phục phiếu xuất {voucher.VoucherNumber}",
                            BeforeDebt = beforeTotalDebt,
                            Delta = voucher.TotalSale,
                            AfterDebt = afterTotalDebt,
                            CreatedAt = voucherDate
                        }, ct);
                    }

                    if (voucher.PaidAmount > 0)
                    {
                        var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                            await DebtHelper.ApplySupplierDebtAsync(_uow, voucher.SupplierId.Value, voucher.Warehouse, -voucher.PaidAmount, ct);

                        var receiptDate = voucher.Date;
                        var receiptNumber = $"PT{receiptDate:yyyyMMdd}-{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000000):D6}";
                        var existingReceipt = await _uow.Receipts.Query()
                            .FirstOrDefaultAsync(r => r.RelatedVoucherId == voucher.VoucherNumber && r.RelatedVoucherType == "export_voucher", ct);

                        if (existingReceipt == null)
                        {
                            var newReceipt = new Receipt
                            {
                                ReceiptNumber = receiptNumber,
                                Date = receiptDate,
                                Warehouse = voucher.Warehouse,
                                SupplierId = voucher.SupplierId.Value,
                                Amount = voucher.PaidAmount,
                                Method = "cash",
                                RelatedVoucherType = "export_voucher",
                                RelatedVoucherId = voucher.VoucherNumber,
                                Notes = $"Thu tiền hoàn trả từ NCC theo phiếu xuất {voucher.VoucherNumber} (Khôi phục)",
                                CreatedAt = receiptDate
                            };
                            await _uow.Receipts.AddAsync(newReceipt, ct);
                        }
                        else
                        {
                            receiptNumber = existingReceipt.ReceiptNumber;
                        }

                        await _uow.SupplierDebtHistories.AddAsync(new SupplierDebtHistory
                        {
                            SupplierId = voucher.SupplierId.Value,
                            Warehouse = voucher.Warehouse,
                            SourceType = DomainConstants.SourceTypes.Receipt,
                            ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                            ReferenceId = receiptNumber,
                            Reason = $"Thu tiền hoàn trả từ NCC theo phiếu xuất {voucher.VoucherNumber} (Khôi phục)",
                            BeforeDebt = beforeTotalDebt,
                            Delta = -voucher.PaidAmount,
                            AfterDebt = afterTotalDebt,
                            CreatedAt = voucherDate.AddMilliseconds(1)
                        }, ct);
                    }
                }
                else if (voucher.CustomerId.HasValue)
                {
                    if (voucher.TotalSale > 0)
                    {
                        var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                            await DebtHelper.ApplyCustomerDebtAsync(_uow, voucher.CustomerId.Value, voucher.Warehouse, voucher.TotalSale, ct);

                        await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                        {
                            CustomerId = voucher.CustomerId.Value,
                            Warehouse = voucher.Warehouse,
                            SourceType = "export_restored",
                            ReferenceType = DomainConstants.ReferenceTypes.ExportVoucher,
                            ReferenceId = voucher.VoucherNumber,
                            Reason = $"Tăng lại nợ do khôi phục phiếu xuất {voucher.VoucherNumber}",
                            BeforeDebt = beforeTotalDebt,
                            Delta = voucher.TotalSale,
                            AfterDebt = afterTotalDebt,
                            CreatedAt = voucherDate
                        }, ct);
                    }

                    if (voucher.PaidAmount > 0)
                    {
                        var (beforeTotalDebt, afterTotalDebt, beforeWhDebt, afterWhDebt) =
                            await DebtHelper.ApplyCustomerDebtAsync(_uow, voucher.CustomerId.Value, voucher.Warehouse, -voucher.PaidAmount, ct);

                        var receiptDate = voucher.Date;
                        var receiptNumber = $"PT{receiptDate:yyyyMMdd}-{(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() % 1000000):D6}";
                        var existingReceipt = await _uow.Receipts.Query()
                            .FirstOrDefaultAsync(r => r.RelatedVoucherId == voucher.VoucherNumber && r.RelatedVoucherType == "export_voucher", ct);

                        if (existingReceipt == null)
                        {
                            var newReceipt = new Receipt
                            {
                                ReceiptNumber = receiptNumber,
                                Date = receiptDate,
                                Warehouse = voucher.Warehouse,
                                CustomerId = voucher.CustomerId.Value,
                                Amount = voucher.PaidAmount,
                                Method = "cash",
                                RelatedVoucherType = "export_voucher",
                                RelatedVoucherId = voucher.VoucherNumber,
                                Notes = $"Thu tiền bán hàng ngay theo phiếu xuất {voucher.VoucherNumber} (Khôi phục)",
                                CreatedAt = receiptDate
                            };
                            await _uow.Receipts.AddAsync(newReceipt, ct);
                        }
                        else
                        {
                            receiptNumber = existingReceipt.ReceiptNumber;
                        }

                        await _uow.CustomerDebtHistories.AddAsync(new CustomerDebtHistory
                        {
                            CustomerId = voucher.CustomerId.Value,
                            Warehouse = voucher.Warehouse,
                            SourceType = DomainConstants.SourceTypes.Receipt,
                            ReferenceType = DomainConstants.ReferenceTypes.Receipt,
                            ReferenceId = receiptNumber,
                            Reason = $"Thu tiền bán hàng ngay theo phiếu xuất {voucher.VoucherNumber} (Khôi phục)",
                            BeforeDebt = beforeTotalDebt,
                            Delta = -voucher.PaidAmount,
                            AfterDebt = afterTotalDebt,
                            CreatedAt = voucherDate.AddMilliseconds(1)
                        }, ct);
                    }
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
            .Include(v => v.Supplier)
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

            var linkedReceipts = await _uow.Receipts.Query()
                .Where(r => r.RelatedVoucherId == voucher.VoucherNumber && r.RelatedVoucherType == "export_voucher")
                .ToListAsync(ct);
            if (linkedReceipts.Count > 0)
            {
                _uow.Receipts.RemoveRange(linkedReceipts);
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

    private static ExportVoucherDto MapToDto(ExportVoucher v)
    {
        var isSupplier = v.PartnerType == "supplier" || (!v.CustomerId.HasValue && v.SupplierId.HasValue);
        var partnerType = isSupplier ? "supplier" : "customer";
        var partnerName = isSupplier ? (v.Supplier?.Name ?? string.Empty) : (v.Customer?.Name ?? string.Empty);
        var partnerDebt = isSupplier ? (v.Supplier?.Debt ?? 0) : (v.Customer?.Debt ?? 0);

        return new()
        {
            Id = v.Id,
            VoucherNumber = v.VoucherNumber,
            Date = v.Date,
            Warehouse = v.Warehouse,
            PartnerType = partnerType,
            CustomerId = v.CustomerId,
            CustomerName = v.Customer?.Name ?? string.Empty,
            CustomerDebt = v.Customer?.Debt ?? 0,
            SupplierId = v.SupplierId,
            SupplierName = v.Supplier?.Name ?? string.Empty,
            PartnerName = partnerName,
            PartnerDebt = partnerDebt,
            EmployeeId = v.EmployeeId,
            EmployeeName = v.Employee?.Name ?? v.EmployeeName,
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
                UnitName = i.UnitName,
                ConversionRate = i.ConversionRate,
                BaseQuantity = i.BaseQuantity,
                UnitCost = i.UnitCost,
                SalePrice = i.SalePrice,
                LineTotal = i.LineTotal,
                Uom = i.Product?.Uom ?? string.Empty
            }).ToList()
        };
    }
}
