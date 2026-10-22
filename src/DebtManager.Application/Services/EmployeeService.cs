using System.Globalization;
using System.Text.RegularExpressions;
using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.DTOs.Employees;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Common;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using MiniExcelLibs;

namespace DebtManager.Application.Services;

public class EmployeeService : IEmployeeService
{
    private readonly IUnitOfWork _uow;

    public EmployeeService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<List<EmployeeDto>> GetEmployeesAsync(
        string? search = null,
        string? month = null,
        string? date = null,
        string? fromDate = null,
        string? toDate = null,
        CancellationToken ct = default)
    {
        var query = _uow.Employees.Query().AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(e =>
                e.Name.ToLower().Contains(s) ||
                (e.Phone != null && e.Phone.ToLower().Contains(s)) ||
                (e.Notes != null && e.Notes.ToLower().Contains(s)));
        }

        var employees = await query
            .OrderByDescending(e => e.CreatedAt)
            .ThenByDescending(e => e.Id)
            .ToListAsync(ct);

        if (employees.Count == 0)
        {
            return new List<EmployeeDto>();
        }

        var empIds = employees.Select(e => (int?)e.Id).ToList();

        var exportQuery = _uow.ExportVouchers.Query()
            .Where(v => v.EmployeeId != null && empIds.Contains(v.EmployeeId) && v.Status != DomainConstants.VoucherStatuses.Cancelled);

        var effectiveDate = !string.IsNullOrWhiteSpace(date) ? date : month;

        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            var start = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
            exportQuery = exportQuery.Where(v => v.Date >= start);
        }

        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            var end = new DateTime(pTo.Year, pTo.Month, pTo.Day, 23, 59, 59, 999, DateTimeKind.Utc);
            exportQuery = exportQuery.Where(v => v.Date <= end);
        }

        if (string.IsNullOrWhiteSpace(fromDate) && string.IsNullOrWhiteSpace(toDate) && !string.IsNullOrWhiteSpace(effectiveDate))
        {
            if (DateTime.TryParseExact(effectiveDate.Trim(), "yyyy-MM-dd", null, DateTimeStyles.None, out var parsedDate))
            {
                var start = new DateTime(parsedDate.Year, parsedDate.Month, parsedDate.Day, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddDays(1);
                exportQuery = exportQuery.Where(v => v.Date >= start && v.Date < end);
            }
            else if (DateTime.TryParseExact(effectiveDate.Trim(), "yyyy-MM", null, DateTimeStyles.None, out var parsedMonth))
            {
                var start = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddMonths(1);
                exportQuery = exportQuery.Where(v => v.Date >= start && v.Date < end);
            }
        }

        var stats = await exportQuery
            .GroupBy(v => v.EmployeeId!.Value)
            .Select(g => new
            {
                EmployeeId = g.Key,
                Count = g.Count(),
                TotalValue = g.Sum(v => v.TotalSale)
            })
            .ToDictionaryAsync(x => x.EmployeeId, ct);

        return employees.Select(e =>
        {
            stats.TryGetValue(e.Id, out var st);
            return new EmployeeDto
            {
                Id = e.Id,
                Name = e.Name,
                Phone = e.Phone,
                Notes = e.Notes,
                CreatedAt = e.CreatedAt,
                ExportCount = st?.Count ?? 0,
                TotalExportValue = st?.TotalValue ?? 0
            };
        }).ToList();
    }

    public async Task<EmployeeDto> GetByIdAsync(int id, CancellationToken ct = default)
    {
        var employee = await _uow.Employees.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy nhân viên có ID {id}");

        var exportStats = await _uow.ExportVouchers.Query()
            .Where(v => v.EmployeeId == id && v.Status != DomainConstants.VoucherStatuses.Cancelled)
            .GroupBy(v => v.EmployeeId)
            .Select(g => new
            {
                Count = g.Count(),
                TotalValue = g.Sum(v => v.TotalSale)
            })
            .FirstOrDefaultAsync(ct);

        return new EmployeeDto
        {
            Id = employee.Id,
            Name = employee.Name,
            Phone = employee.Phone,
            Notes = employee.Notes,
            CreatedAt = employee.CreatedAt,
            ExportCount = exportStats?.Count ?? 0,
            TotalExportValue = exportStats?.TotalValue ?? 0
        };
    }

    public async Task<EmployeeDto> CreateEmployeeAsync(CreateEmployeeDto dto, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(dto.Name))
        {
            throw new ValidationException("Tên nhân viên không được để trống");
        }

        var name = dto.Name.Trim();

        var existing = await _uow.Employees.Query()
            .AnyAsync(e => e.Name.ToLower() == name.ToLower(), ct);

        if (existing)
        {
            throw new BusinessRuleException($"Nhân viên '{name}' đã tồn tại trong hệ thống");
        }

        var employee = new Employee
        {
            Name = name,
            Phone = string.IsNullOrWhiteSpace(dto.Phone) ? null : dto.Phone.Trim(),
            Notes = string.IsNullOrWhiteSpace(dto.Notes) ? null : dto.Notes.Trim(),
            CreatedAt = DateTime.UtcNow
        };

        await _uow.Employees.AddAsync(employee, ct);
        await _uow.SaveChangesAsync(ct);

        return new EmployeeDto
        {
            Id = employee.Id,
            Name = employee.Name,
            Phone = employee.Phone,
            Notes = employee.Notes,
            CreatedAt = employee.CreatedAt,
            ExportCount = 0,
            TotalExportValue = 0
        };
    }

    public async Task<bool> DeleteEmployeeAsync(int id, CancellationToken ct = default)
    {
        var employee = await _uow.Employees.GetByIdAsync(id, ct)
            ?? throw new NotFoundException($"Không tìm thấy nhân viên có ID {id}");

        var linkedVouchers = await _uow.ExportVouchers.Query()
            .Where(v => v.EmployeeId == id)
            .ToListAsync(ct);

        foreach (var v in linkedVouchers)
        {
            if (string.IsNullOrWhiteSpace(v.EmployeeName))
            {
                v.EmployeeName = employee.Name;
            }
            v.EmployeeId = null;
            _uow.ExportVouchers.Update(v);
        }

        _uow.Employees.Remove(employee);
        await _uow.SaveChangesAsync(ct);

        return true;
    }

    public async Task<(byte[] Bytes, string FileName)> ExportEmployeeSalesExcelAsync(
        int? employeeId = null,
        string? month = null,
        string? date = null,
        string? fromDate = null,
        string? toDate = null,
        CancellationToken ct = default)
    {
        Employee? targetEmployee = null;
        if (employeeId.HasValue && employeeId.Value > 0)
        {
            targetEmployee = await _uow.Employees.GetByIdAsync(employeeId.Value, ct)
                ?? throw new NotFoundException($"Không tìm thấy nhân viên có ID {employeeId.Value}");
        }

        // Determine period label
        string periodLabel;
        var effectiveDate = !string.IsNullOrWhiteSpace(date) ? date : month;
        if (!string.IsNullOrWhiteSpace(date))
        {
            periodLabel = date.Trim();
        }
        else if (!string.IsNullOrWhiteSpace(month))
        {
            periodLabel = month.Trim();
        }
        else if (!string.IsNullOrWhiteSpace(fromDate) || !string.IsNullOrWhiteSpace(toDate))
        {
            periodLabel = $"{fromDate?.Trim() ?? "start"}_den_{toDate?.Trim() ?? "end"}";
        }
        else
        {
            periodLabel = "ToanBo";
        }

        // Build query for Export Vouchers
        var voucherQuery = _uow.ExportVouchers.Query()
            .Include(v => v.Customer)
            .Include(v => v.Employee)
            .Include(v => v.Items)
                .ThenInclude(i => i.Product)
            .AsQueryable();

        if (targetEmployee != null)
        {
            voucherQuery = voucherQuery.Where(v => v.EmployeeId == targetEmployee.Id);
        }
        else
        {
            voucherQuery = voucherQuery.Where(v => v.EmployeeId != null || !string.IsNullOrEmpty(v.EmployeeName));
        }

        if (!string.IsNullOrWhiteSpace(fromDate) && DateTime.TryParse(fromDate.Trim(), out var pFrom))
        {
            var start = new DateTime(pFrom.Year, pFrom.Month, pFrom.Day, 0, 0, 0, DateTimeKind.Utc);
            voucherQuery = voucherQuery.Where(v => v.Date >= start);
        }

        if (!string.IsNullOrWhiteSpace(toDate) && DateTime.TryParse(toDate.Trim(), out var pTo))
        {
            var end = new DateTime(pTo.Year, pTo.Month, pTo.Day, 23, 59, 59, 999, DateTimeKind.Utc);
            voucherQuery = voucherQuery.Where(v => v.Date <= end);
        }

        if (string.IsNullOrWhiteSpace(fromDate) && string.IsNullOrWhiteSpace(toDate) && !string.IsNullOrWhiteSpace(effectiveDate))
        {
            if (DateTime.TryParseExact(effectiveDate.Trim(), "yyyy-MM-dd", null, DateTimeStyles.None, out var parsedDate))
            {
                var start = new DateTime(parsedDate.Year, parsedDate.Month, parsedDate.Day, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddDays(1);
                voucherQuery = voucherQuery.Where(v => v.Date >= start && v.Date < end);
            }
            else if (DateTime.TryParseExact(effectiveDate.Trim(), "yyyy-MM", null, DateTimeStyles.None, out var parsedMonth))
            {
                var start = new DateTime(parsedMonth.Year, parsedMonth.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                var end = start.AddMonths(1);
                voucherQuery = voucherQuery.Where(v => v.Date >= start && v.Date < end);
            }
        }

        var vouchers = await voucherQuery
            .OrderByDescending(v => v.Date)
            .ThenByDescending(v => v.Id)
            .ToListAsync(ct);

        var sheets = new Dictionary<string, object>();
        string fileName;

        if (targetEmployee != null)
        {
            var safeEmpName = Regex.Replace(targetEmployee.Name.Trim(), @"[^\w\d\-_]", "_");
            fileName = $"BaoCao_DoanhSo_SP_{safeEmpName}_{periodLabel}.xlsx";

            // 1. Sheet: Doanh số phiếu xuất
            var voucherRows = new List<Dictionary<string, object>>();
            int vStt = 1;
            decimal sumSubtotal = 0, sumDiscount = 0, sumTotal = 0, sumPaid = 0, sumUnpaid = 0;

            foreach (var v in vouchers)
            {
                bool isActive = v.Status != DomainConstants.VoucherStatuses.Cancelled;
                if (isActive)
                {
                    sumSubtotal += v.SubtotalSale;
                    sumDiscount += v.DiscountAmount;
                    sumTotal += v.TotalSale;
                    sumPaid += v.PaidAmount;
                    sumUnpaid += v.UnpaidAmount;
                }

                voucherRows.Add(new Dictionary<string, object>
                {
                    ["STT"] = vStt++,
                    ["Số phiếu"] = v.VoucherNumber,
                    ["Ngày xuất"] = v.Date.ToString("dd/MM/yyyy HH:mm"),
                    ["Khách hàng"] = v.Customer?.Name ?? "",
                    ["Kho xuất"] = v.Warehouse,
                    ["Tiền hàng (VNĐ)"] = v.SubtotalSale,
                    ["Chiết khấu (VNĐ)"] = v.DiscountAmount,
                    ["Tổng doanh số (VNĐ)"] = v.TotalSale,
                    ["Đã thanh toán (VNĐ)"] = v.PaidAmount,
                    ["Còn nợ (VNĐ)"] = v.UnpaidAmount,
                    ["Trạng thái"] = v.Status == "cancelled" ? "Đã hủy" : "Hoạt động",
                    ["Ghi chú"] = v.Notes ?? ""
                });
            }

            voucherRows.Add(new Dictionary<string, object>
            {
                ["STT"] = "TỔNG CỘNG",
                ["Số phiếu"] = $"(Hoạt động: {vouchers.Count(v => v.Status != "cancelled")}/{vouchers.Count} phiếu)",
                ["Ngày xuất"] = "",
                ["Khách hàng"] = "",
                ["Kho xuất"] = "",
                ["Tiền hàng (VNĐ)"] = sumSubtotal,
                ["Chiết khấu (VNĐ)"] = sumDiscount,
                ["Tổng doanh số (VNĐ)"] = sumTotal,
                ["Đã thanh toán (VNĐ)"] = sumPaid,
                ["Còn nợ (VNĐ)"] = sumUnpaid,
                ["Trạng thái"] = "",
                ["Ghi chú"] = ""
            });

            sheets["1.DoanhSo_PhieuXuat"] = voucherRows;

            // 2. Sheet: Sản phẩm bán ra (Chỉ tính phiếu hoạt động)
            var activeVouchers = vouchers.Where(v => v.Status != DomainConstants.VoucherStatuses.Cancelled).ToList();
            var activeItems = activeVouchers.SelectMany(v => v.Items).ToList();

            var productGroups = activeItems
                .GroupBy(i => new
                {
                    ProductId = i.ProductId,
                    ProductName = i.Product != null ? i.Product.Name : $"SP_{i.ProductId}",
                    Sku = i.Product != null ? i.Product.Sku : $"SKU_{i.ProductId}",
                    Uom = i.Product != null ? i.Product.Uom : ""
                })
                .Select(g => new
                {
                    g.Key.Sku,
                    g.Key.ProductName,
                    g.Key.Uom,
                    Quantity = g.Sum(x => x.Quantity),
                    TotalAmount = g.Sum(x => x.LineTotal),
                    AvgPrice = g.Sum(x => x.Quantity) > 0 ? Math.Round(g.Sum(x => x.LineTotal) / g.Sum(x => x.Quantity), 0) : 0
                })
                .OrderByDescending(p => p.TotalAmount)
                .ToList();

            var productRows = new List<Dictionary<string, object>>();
            int pStt = 1;
            decimal totalProductQty = 0, totalProductAmount = 0;

            foreach (var p in productGroups)
            {
                totalProductQty += p.Quantity;
                totalProductAmount += p.TotalAmount;
                decimal percent = sumTotal > 0 ? (p.TotalAmount * 100m / sumTotal) : 0;

                productRows.Add(new Dictionary<string, object>
                {
                    ["STT"] = pStt++,
                    ["Mã SKU"] = p.Sku,
                    ["Tên sản phẩm"] = p.ProductName,
                    ["ĐVT"] = p.Uom,
                    ["Số lượng bán"] = p.Quantity,
                    ["Đơn giá trung bình (VNĐ)"] = p.AvgPrice,
                    ["Tổng thành tiền (VNĐ)"] = p.TotalAmount,
                    ["Tỷ lệ / Doanh số"] = $"{percent:0.1}%"
                });
            }

            productRows.Add(new Dictionary<string, object>
            {
                ["STT"] = "TỔNG CỘNG",
                ["Mã SKU"] = "",
                ["Tên sản phẩm"] = $"Tổng cộng {productGroups.Count} mặt hàng",
                ["ĐVT"] = "",
                ["Số lượng bán"] = totalProductQty,
                ["Đơn giá trung bình (VNĐ)"] = totalProductQty > 0 ? Math.Round(totalProductAmount / totalProductQty, 0) : 0,
                ["Tổng thành tiền (VNĐ)"] = totalProductAmount,
                ["Tỷ lệ / Doanh số"] = "100%"
            });

            sheets["2.SanPham_BanRa"] = productRows;

            // 3. Sheet: Chi tiết từng dòng mặt hàng trong từng phiếu xuất
            var lineItemRows = new List<Dictionary<string, object>>();
            int lStt = 1;

            foreach (var v in vouchers)
            {
                foreach (var i in v.Items)
                {
                    lineItemRows.Add(new Dictionary<string, object>
                    {
                        ["STT"] = lStt++,
                        ["Số phiếu"] = v.VoucherNumber,
                        ["Ngày xuất"] = v.Date.ToString("dd/MM/yyyy HH:mm"),
                        ["Khách hàng"] = v.Customer?.Name ?? "",
                        ["Mã SKU"] = i.Product != null ? i.Product.Sku : $"SKU_{i.ProductId}",
                        ["Tên sản phẩm"] = i.Product != null ? i.Product.Name : $"SP_{i.ProductId}",
                        ["ĐVT"] = i.Product != null ? i.Product.Uom : "",
                        ["Số lượng"] = i.Quantity,
                        ["Đơn giá bán (VNĐ)"] = i.SalePrice,
                        ["Thành tiền (VNĐ)"] = i.LineTotal,
                        ["Trạng thái phiếu"] = v.Status == "cancelled" ? "Đã hủy" : "Hoạt động"
                    });
                }
            }

            sheets["3.ChiTiet_TungMatHang"] = lineItemRows;
        }
        else
        {
            // ALL EMPLOYEES REPORT
            fileName = $"BaoCao_DoanhSo_NhanVien_{periodLabel}.xlsx";

            var allEmployees = await _uow.Employees.Query()
                .OrderBy(e => e.Name)
                .ToListAsync(ct);

            var activeVouchers = vouchers.Where(v => v.Status != DomainConstants.VoucherStatuses.Cancelled).ToList();

            // 1. Sheet: Tổng hợp doanh số từng nhân viên
            var summaryRows = new List<Dictionary<string, object>>();
            int eStt = 1;
            decimal gSubtotal = 0, gDiscount = 0, gTotal = 0, gPaid = 0, gUnpaid = 0;
            int gCount = 0;

            foreach (var emp in allEmployees)
            {
                var empVouchers = activeVouchers.Where(v => v.EmployeeId == emp.Id).ToList();
                var empSubtotal = empVouchers.Sum(v => v.SubtotalSale);
                var empDiscount = empVouchers.Sum(v => v.DiscountAmount);
                var empTotal = empVouchers.Sum(v => v.TotalSale);
                var empPaid = empVouchers.Sum(v => v.PaidAmount);
                var empUnpaid = empVouchers.Sum(v => v.UnpaidAmount);

                gCount += empVouchers.Count;
                gSubtotal += empSubtotal;
                gDiscount += empDiscount;
                gTotal += empTotal;
                gPaid += empPaid;
                gUnpaid += empUnpaid;

                summaryRows.Add(new Dictionary<string, object>
                {
                    ["STT"] = eStt++,
                    ["Tên nhân viên"] = emp.Name,
                    ["Số điện thoại"] = emp.Phone ?? "",
                    ["Số phiếu xuất"] = empVouchers.Count,
                    ["Tiền hàng (VNĐ)"] = empSubtotal,
                    ["Chiết khấu (VNĐ)"] = empDiscount,
                    ["Tổng doanh số (VNĐ)"] = empTotal,
                    ["Đã thu (VNĐ)"] = empPaid,
                    ["Còn nợ (VNĐ)"] = empUnpaid,
                    ["Ghi chú"] = emp.Notes ?? ""
                });
            }

            // Also check vouchers that have employee name but no matching employee id
            var unlinkedVouchers = activeVouchers.Where(v => v.EmployeeId == null && !string.IsNullOrWhiteSpace(v.EmployeeName)).ToList();
            if (unlinkedVouchers.Count > 0)
            {
                var unlinkedGroup = unlinkedVouchers.GroupBy(v => v.EmployeeName!.Trim());
                foreach (var ug in unlinkedGroup)
                {
                    var uSubtotal = ug.Sum(v => v.SubtotalSale);
                    var uDiscount = ug.Sum(v => v.DiscountAmount);
                    var uTotal = ug.Sum(v => v.TotalSale);
                    var uPaid = ug.Sum(v => v.PaidAmount);
                    var uUnpaid = ug.Sum(v => v.UnpaidAmount);

                    gCount += ug.Count();
                    gSubtotal += uSubtotal;
                    gDiscount += uDiscount;
                    gTotal += uTotal;
                    gPaid += uPaid;
                    gUnpaid += uUnpaid;

                    summaryRows.Add(new Dictionary<string, object>
                    {
                        ["STT"] = eStt++,
                        ["Tên nhân viên"] = $"{ug.Key} (Đã xóa/Cũ)",
                        ["Số điện thoại"] = "",
                        ["Số phiếu xuất"] = ug.Count(),
                        ["Tiền hàng (VNĐ)"] = uSubtotal,
                        ["Chiết khấu (VNĐ)"] = uDiscount,
                        ["Tổng doanh số (VNĐ)"] = uTotal,
                        ["Đã thu (VNĐ)"] = uPaid,
                        ["Còn nợ (VNĐ)"] = uUnpaid,
                        ["Ghi chú"] = ""
                    });
                }
            }

            summaryRows.Add(new Dictionary<string, object>
            {
                ["STT"] = "TỔNG CỘNG",
                ["Tên nhân viên"] = $"Tổng cộng {summaryRows.Count} nhân sự",
                ["Số điện thoại"] = "",
                ["Số phiếu xuất"] = gCount,
                ["Tiền hàng (VNĐ)"] = gSubtotal,
                ["Chiết khấu (VNĐ)"] = gDiscount,
                ["Tổng doanh số (VNĐ)"] = gTotal,
                ["Đã thu (VNĐ)"] = gPaid,
                ["Còn nợ (VNĐ)"] = gUnpaid,
                ["Ghi chú"] = ""
            });

            sheets["1.TongHop_DoanhSo_NV"] = summaryRows;

            // 2. Sheet: Sản phẩm bán ra theo từng nhân viên
            var empProductRows = new List<Dictionary<string, object>>();
            int epStt = 1;

            var empItems = activeVouchers
                .SelectMany(v => v.Items.Select(i => new
                {
                    EmployeeName = v.Employee?.Name ?? (!string.IsNullOrWhiteSpace(v.EmployeeName) ? v.EmployeeName : "Chưa gán"),
                    Item = i
                }))
                .GroupBy(x => new
                {
                    x.EmployeeName,
                    ProductId = x.Item.ProductId,
                    Sku = x.Item.Product != null ? x.Item.Product.Sku : $"SKU_{x.Item.ProductId}",
                    ProductName = x.Item.Product != null ? x.Item.Product.Name : $"SP_{x.Item.ProductId}",
                    Uom = x.Item.Product != null ? x.Item.Product.Uom : ""
                })
                .Select(g => new
                {
                    g.Key.EmployeeName,
                    g.Key.Sku,
                    g.Key.ProductName,
                    g.Key.Uom,
                    Quantity = g.Sum(x => x.Item.Quantity),
                    TotalAmount = g.Sum(x => x.Item.LineTotal),
                    AvgPrice = g.Sum(x => x.Item.Quantity) > 0 ? Math.Round(g.Sum(x => x.Item.LineTotal) / g.Sum(x => x.Item.Quantity), 0) : 0
                })
                .OrderBy(x => x.EmployeeName)
                .ThenByDescending(x => x.TotalAmount)
                .ToList();

            foreach (var ep in empItems)
            {
                empProductRows.Add(new Dictionary<string, object>
                {
                    ["STT"] = epStt++,
                    ["Nhân viên"] = ep.EmployeeName,
                    ["Mã SKU"] = ep.Sku,
                    ["Tên sản phẩm"] = ep.ProductName,
                    ["ĐVT"] = ep.Uom,
                    ["Số lượng bán"] = ep.Quantity,
                    ["Đơn giá TB (VNĐ)"] = ep.AvgPrice,
                    ["Tổng thành tiền (VNĐ)"] = ep.TotalAmount
                });
            }

            sheets["2.SanPham_BanRa_TheoNV"] = empProductRows;

            // 3. Sheet: Top sản phẩm bán chạy toàn bộ nhân viên
            var allProductGroups = activeVouchers
                .SelectMany(v => v.Items)
                .GroupBy(i => new
                {
                    ProductId = i.ProductId,
                    Sku = i.Product != null ? i.Product.Sku : $"SKU_{i.ProductId}",
                    ProductName = i.Product != null ? i.Product.Name : $"SP_{i.ProductId}",
                    Uom = i.Product != null ? i.Product.Uom : ""
                })
                .Select(g => new
                {
                    g.Key.Sku,
                    g.Key.ProductName,
                    g.Key.Uom,
                    Quantity = g.Sum(x => x.Quantity),
                    TotalAmount = g.Sum(x => x.LineTotal),
                    AvgPrice = g.Sum(x => x.Quantity) > 0 ? Math.Round(g.Sum(x => x.LineTotal) / g.Sum(x => x.Quantity), 0) : 0
                })
                .OrderByDescending(p => p.TotalAmount)
                .ToList();

            var topProductRows = new List<Dictionary<string, object>>();
            int tpStt = 1;
            decimal tpQty = 0, tpAmount = 0;

            foreach (var tp in allProductGroups)
            {
                tpQty += tp.Quantity;
                tpAmount += tp.TotalAmount;

                topProductRows.Add(new Dictionary<string, object>
                {
                    ["STT"] = tpStt++,
                    ["Mã SKU"] = tp.Sku,
                    ["Tên sản phẩm"] = tp.ProductName,
                    ["ĐVT"] = tp.Uom,
                    ["Tổng số lượng bán"] = tp.Quantity,
                    ["Đơn giá TB (VNĐ)"] = tp.AvgPrice,
                    ["Tổng doanh số (VNĐ)"] = tp.TotalAmount
                });
            }

            topProductRows.Add(new Dictionary<string, object>
            {
                ["STT"] = "TỔNG CỘNG",
                ["Mã SKU"] = "",
                ["Tên sản phẩm"] = $"Tổng cộng {allProductGroups.Count} mặt hàng",
                ["ĐVT"] = "",
                ["Tổng số lượng bán"] = tpQty,
                ["Đơn giá TB (VNĐ)"] = tpQty > 0 ? Math.Round(tpAmount / tpQty, 0) : 0,
                ["Tổng doanh số (VNĐ)"] = tpAmount
            });

            sheets["3.Top_SanPham_BanChay"] = topProductRows;

            // 4. Sheet: Toàn bộ phiếu xuất
            var allVoucherRows = new List<Dictionary<string, object>>();
            int avStt = 1;

            foreach (var v in vouchers)
            {
                allVoucherRows.Add(new Dictionary<string, object>
                {
                    ["STT"] = avStt++,
                    ["Số phiếu"] = v.VoucherNumber,
                    ["Ngày xuất"] = v.Date.ToString("dd/MM/yyyy HH:mm"),
                    ["Nhân viên"] = v.Employee?.Name ?? (!string.IsNullOrWhiteSpace(v.EmployeeName) ? v.EmployeeName : "Chưa gán"),
                    ["Khách hàng"] = v.Customer?.Name ?? "",
                    ["Kho xuất"] = v.Warehouse,
                    ["Tiền hàng (VNĐ)"] = v.SubtotalSale,
                    ["Chiết khấu (VNĐ)"] = v.DiscountAmount,
                    ["Tổng doanh số (VNĐ)"] = v.TotalSale,
                    ["Đã thanh toán (VNĐ)"] = v.PaidAmount,
                    ["Còn nợ (VNĐ)"] = v.UnpaidAmount,
                    ["Trạng thái"] = v.Status == "cancelled" ? "Đã hủy" : "Hoạt động",
                    ["Ghi chú"] = v.Notes ?? ""
                });
            }

            sheets["4.ChiTiet_PhieuXuat"] = allVoucherRows;
        }

        // Save sheets to temp file via MiniExcel
        var tempDir = Path.Combine(Path.GetTempPath(), "debtmanager_exports");
        if (!Directory.Exists(tempDir)) Directory.CreateDirectory(tempDir);
        var tempFile = Path.Combine(tempDir, $"emp_sales_{Guid.NewGuid():N}.xlsx");

        await MiniExcel.SaveAsAsync(tempFile, sheets, overwriteFile: true);
        var fileBytes = await File.ReadAllBytesAsync(tempFile, ct);
        try { File.Delete(tempFile); } catch { }

        return (fileBytes, fileName);
    }
}
