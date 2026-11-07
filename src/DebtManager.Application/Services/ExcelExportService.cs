using DebtManager.Application.DTOs.Exports;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Application.Services.Exports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MiniExcelLibs;

namespace DebtManager.Application.Services;

public class ExcelExportService : IExcelExportService
{
    private readonly IExportJobManager _jobManager;
    private readonly IBackgroundTaskQueue _queue;
    private readonly IUnitOfWork _uow;
    private readonly ReportExportEngine _reportEngine;

    public ExcelExportService(IExportJobManager jobManager, IBackgroundTaskQueue queue, IUnitOfWork uow)
    {
        _jobManager = jobManager;
        _queue = queue;
        _uow = uow;
        _reportEngine = new ReportExportEngine(jobManager, queue);
    }

    public string StartReportExport(ExportReportRequestDto request)
    {
        return _reportEngine.StartExport(request);
    }

    public async Task<ExcelPreviewResultDto> GeneratePreviewAsync(ExportReportRequestDto request, CancellationToken ct = default)
    {
        return await _reportEngine.GeneratePreviewAsync(request, _uow, ct);
    }

    public string StartDailyMatrixExport(DailyMatrixExportRequestDto request)
    {
        var isSupplier = request.PartnerType.Equals("supplier", StringComparison.OrdinalIgnoreCase) || request.SupplierId.HasValue;
        var mapped = new ExportReportRequestDto
        {
            ReportType = isSupplier ? "purchases" : "sales",
            Period = new PeriodDto
            {
                Mode = request.TimeScope.Equals("custom", StringComparison.OrdinalIgnoreCase) ? "dayRange"
                    : request.TimeScope.Equals("all", StringComparison.OrdinalIgnoreCase) ? "all" : "month",
                Month = request.Month,
                FromDate = request.FromDate,
                ToDate = request.ToDate
            },
            Granularity = "day",
            GroupBy = "product",
            ProductIds = request.ProductId.HasValue ? new List<int> { request.ProductId.Value } : new List<int>(),
            CustomerIds = !isSupplier && request.CustomerId.HasValue ? new List<int> { request.CustomerId.Value } : new List<int>(),
            SupplierIds = isSupplier && request.SupplierId.HasValue ? new List<int> { request.SupplierId.Value } : new List<int>(),
            Warehouses = !string.IsNullOrWhiteSpace(request.Warehouse) ? new List<string> { request.Warehouse } : new List<string>(),
            IncludeQuantity = request.IncludeQuantity,
            IncludeAmount = request.IncludeRevenue,
            IncludeAvgPrice = request.IncludePrice,
            SplitSheets = request.SeparateSheets ? "month" : "none"
        };

        return _reportEngine.StartExport(mapped);
    }

    public string StartFullDbExport(FullDbExportRequestDto request)
    {
        var jobId = _jobManager.CreateJob("Đang khởi tạo tiến trình sao lưu toàn bộ dữ liệu...");

        _queue.QueueBackgroundWorkItemAsync(async (sp, ct) =>
        {
            try
            {
                var uow = sp.GetRequiredService<IUnitOfWork>();
                var tempDir = Path.Combine(Path.GetTempPath(), "debtmanager_exports");
                if (!Directory.Exists(tempDir)) Directory.CreateDirectory(tempDir);

                var fileName = $"DebtManager_FullBackup_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";
                var filePath = Path.Combine(tempDir, $"{jobId}.xlsx");

                var sheets = new Dictionary<string, object>();
                var tablesToExport = request.Tables != null && request.Tables.Count > 0
                    ? request.Tables
                    : new List<string> { "products", "customers", "suppliers", "exports", "imports", "receipts", "payments", "stock_history", "debt_history" };

                int total = tablesToExport.Count;
                int current = 0;

                foreach (var table in tablesToExport)
                {
                    current++;
                    int progress = 10 + (current * 75 / total);

                    switch (table.ToLowerInvariant())
                    {
                        case "products":
                            _jobManager.UpdateProgress(jobId, progress, "Đang xuất danh mục Sản phẩm, Đơn vị tính & Tồn kho...");
                            var prods = await uow.Products.Query().Include(p => p.Units).AsNoTracking().ToListAsync(ct);
                            sheets["1.SanPham"] = prods.Select(p => new
                            {
                                MaSKU = p.Sku,
                                TenSanPham = p.Name,
                                DVT_CoSo = p.Uom,
                                CacDonViQuyDoi = p.Units != null && p.Units.Any(u => !u.IsBaseUnit)
                                    ? string.Join(", ", p.Units.Where(u => !u.IsBaseUnit).Select(u => $"{u.UnitName} (x{u.ConversionRate:G29})"))
                                    : "",
                                DanhMuc = p.Category,
                                GiaVon = p.UnitCost,
                                GiaSi = p.WholesalePrice,
                                GiaLe = p.RetailPrice,
                                TonKho1 = p.StockWarehouse1,
                                TonKho2 = p.StockWarehouse2,
                                TonKho3 = p.StockWarehouse3,
                                TongTonKhoCoSo = p.TotalStock
                            }).ToList();

                            // Sheet 1b: Danh sách chi tiết các Đơn vị tính quy đổi
                            var allUnits = prods.SelectMany(p => (p.Units ?? new List<Domain.Entities.ProductUnit>()).Select(u => new
                            {
                                MaSKU = p.Sku,
                                TenSanPham = p.Name,
                                TenDonVi = u.UnitName,
                                HeSoQuyDoi = u.ConversionRate,
                                LaDonViCoSo = u.IsBaseUnit ? "Có" : "Không",
                                GiaLe = u.RetailPrice,
                                GiaSi = u.WholesalePrice,
                                MaVach = u.Barcode ?? "",
                                ChoPhepBan = u.CanSell ? "Có" : "Không"
                            })).ToList();

                            if (allUnits.Count > 0)
                            {
                                sheets["1b.DonViQuyDoi"] = allUnits;
                            }
                            break;

                        case "customers":
                            _jobManager.UpdateProgress(jobId, progress, "Đang xuất danh sách Khách hàng & Công nợ theo kho...");
                            var custs = await uow.Customers.Query().Include(c => c.WarehouseDebts).AsNoTracking().ToListAsync(ct);
                            sheets["2.KhachHang"] = custs.Select(c => new
                            {
                                MaKH = c.Code,
                                TenKhachHang = c.Name,
                                NguoiLienHe = c.ContactName,
                                SoDienThoai = c.PhonesJson,
                                Email = c.Email,
                                KhuVuc = c.Region,
                                DiaChi = c.AddressesJson,
                                NoKho1 = c.WarehouseDebts?.FirstOrDefault(w => w.Warehouse == "warehouse1")?.Debt ?? 0,
                                NoKho2 = c.WarehouseDebts?.FirstOrDefault(w => w.Warehouse == "warehouse2")?.Debt ?? 0,
                                NoKho3 = c.WarehouseDebts?.FirstOrDefault(w => w.Warehouse == "warehouse3")?.Debt ?? 0,
                                TongDuNo = c.Debt
                            }).ToList();
                            break;

                        case "suppliers":
                            _jobManager.UpdateProgress(jobId, progress, "Đang xuất danh sách Nhà cung cấp & Công nợ theo kho...");
                            var supps = await uow.Suppliers.Query().Include(s => s.WarehouseDebts).AsNoTracking().ToListAsync(ct);
                            sheets["3.NhaCungCap"] = supps.Select(s => new
                            {
                                MaNCC = s.Code,
                                TenNhaCungCap = s.Name,
                                NguoiLienHe = s.ContactName,
                                SoDienThoai = s.PhonesJson,
                                STK_NganHang = s.BankAccount,
                                MaSoThue = s.TaxNumber,
                                KhuVuc = s.Region,
                                DiaChi = s.AddressesJson,
                                NoKho1 = s.WarehouseDebts?.FirstOrDefault(w => w.Warehouse == "warehouse1")?.Debt ?? 0,
                                NoKho2 = s.WarehouseDebts?.FirstOrDefault(w => w.Warehouse == "warehouse2")?.Debt ?? 0,
                                NoKho3 = s.WarehouseDebts?.FirstOrDefault(w => w.Warehouse == "warehouse3")?.Debt ?? 0,
                                TongDuNo = s.Debt,
                                CongNoPhaiTra = s.Debt < 0 ? Math.Abs(s.Debt) : 0,
                                TienUngTruoc = s.Debt > 0 ? s.Debt : 0
                            }).ToList();
                            break;

                        case "exports":
                            _jobManager.UpdateProgress(jobId, progress, "Đang xuất lịch sử Phiếu xuất kho & Chi tiết...");
                            var exps = await uow.ExportVouchers.Query()
                                .Include(v => v.Customer)
                                .Include(v => v.Items)
                                    .ThenInclude(i => i.Product)
                                .AsNoTracking()
                                .OrderByDescending(v => v.Date)
                                .ToListAsync(ct);

                            sheets["4.PhieuXuat"] = exps.Select(e => new
                            {
                                SoPhieu = e.VoucherNumber,
                                NgayXuat = e.Date.ToString("yyyy-MM-dd HH:mm"),
                                KhachHang = e.Customer != null ? e.Customer.Name : "",
                                KhoXuat = e.Warehouse,
                                TienHang = e.SubtotalSale,
                                ChietKhau = e.DiscountAmount,
                                TongThanhToan = e.TotalSale,
                                DaThanhToan = e.PaidAmount,
                                ConNo = e.UnpaidAmount,
                                TrangThai = e.Status,
                                GhiChu = e.Notes
                            }).ToList();

                            sheets["4b.ChiTietXuat"] = exps.SelectMany(e => e.Items.Select(i => new
                            {
                                SoPhieu = e.VoucherNumber,
                                NgayXuat = e.Date.ToString("yyyy-MM-dd HH:mm"),
                                KhachHang = e.Customer?.Name ?? "",
                                KhoXuat = e.Warehouse,
                                MaSKU = i.Product != null ? i.Product.Sku : "",
                                TenSanPham = i.Product?.Name ?? "",
                                SoLuong = i.Quantity,
                                DVT = !string.IsNullOrWhiteSpace(i.UnitName) ? i.UnitName : (i.Product?.Uom ?? ""),
                                HeSoQuyDoi = i.ConversionRate,
                                SoLuongCoSo = i.BaseQuantity > 0 ? i.BaseQuantity : i.Quantity * i.ConversionRate,
                                DonGia = i.SalePrice,
                                ThanhTien = i.LineTotal
                            })).ToList();
                            break;

                        case "imports":
                            _jobManager.UpdateProgress(jobId, progress, "Đang xuất lịch sử Phiếu nhập kho & Chi tiết...");
                            var imps = await uow.ImportVouchers.Query()
                                .Include(v => v.Supplier)
                                .Include(v => v.Items)
                                    .ThenInclude(i => i.Product)
                                .AsNoTracking()
                                .OrderByDescending(v => v.Date)
                                .ToListAsync(ct);

                            sheets["5.PhieuNhap"] = imps.Select(i => new
                            {
                                SoPhieu = i.VoucherNumber,
                                NgayNhap = i.Date.ToString("yyyy-MM-dd HH:mm"),
                                NhaCungCap = i.Supplier != null ? i.Supplier.Name : "",
                                KhoNhan = i.Warehouse,
                                TienHang = i.SubtotalAmount,
                                ChietKhau = i.DiscountAmount,
                                TongTienNhap = i.TotalAmount,
                                DaTraNCC = i.PaidAmount,
                                ConNoNCC = i.UnpaidAmount,
                                TrangThai = i.Status,
                                GhiChu = i.Notes
                            }).ToList();

                            sheets["5b.ChiTietNhap"] = imps.SelectMany(imp => imp.Items.Select(i => new
                            {
                                SoPhieu = imp.VoucherNumber,
                                NgayNhap = imp.Date.ToString("yyyy-MM-dd HH:mm"),
                                NhaCungCap = imp.Supplier?.Name ?? "",
                                KhoNhan = imp.Warehouse,
                                MaSKU = i.Product != null ? i.Product.Sku : "",
                                TenSanPham = i.Product?.Name ?? "",
                                SoLuong = i.Quantity,
                                DVT = !string.IsNullOrWhiteSpace(i.UnitName) ? i.UnitName : (i.Product?.Uom ?? ""),
                                HeSoQuyDoi = i.ConversionRate,
                                SoLuongCoSo = i.BaseQuantity > 0 ? i.BaseQuantity : i.Quantity * i.ConversionRate,
                                DonGia = i.UnitPrice,
                                ThanhTien = i.LineTotal
                            })).ToList();
                            break;

                        case "receipts":
                            _jobManager.UpdateProgress(jobId, progress, "Đang xuất danh sách Phiếu thu...");
                            var receipts = await uow.Receipts.Query()
                                .Include(r => r.Customer)
                                .Include(r => r.Supplier)
                                .AsNoTracking()
                                .OrderByDescending(r => r.Date)
                                .ToListAsync(ct);
                            sheets["6.PhieuThu"] = receipts.Select(r => new
                            {
                                SoPhieuThu = r.ReceiptNumber,
                                NgayThu = r.Date.ToString("yyyy-MM-dd HH:mm"),
                                Kho = r.Warehouse,
                                DoiTac = r.Customer != null ? r.Customer.Name : (r.Supplier != null ? r.Supplier.Name : ""),
                                SoTienThu = r.Amount,
                                HinhThuc = r.Method,
                                LyDo = r.Notes
                            }).ToList();
                            break;

                        case "payments":
                            _jobManager.UpdateProgress(jobId, progress, "Đang xuất danh sách Phiếu chi...");
                            var payments = await uow.Payments.Query()
                                .Include(p => p.Supplier)
                                .Include(p => p.Customer)
                                .AsNoTracking()
                                .OrderByDescending(p => p.Date)
                                .ToListAsync(ct);
                            sheets["7.PhieuChi"] = payments.Select(p => new
                            {
                                SoPhieuChi = p.PaymentNumber,
                                NgayChi = p.Date.ToString("yyyy-MM-dd HH:mm"),
                                Kho = p.Warehouse,
                                DoiTac = p.Supplier != null ? p.Supplier.Name : (p.Customer != null ? p.Customer.Name : ""),
                                SoTienChi = p.Amount,
                                HinhThuc = p.Method,
                                LyDo = p.Notes,
                                TrangThai = p.Status
                            }).ToList();
                            break;
                    }
                }

                _jobManager.UpdateProgress(jobId, 90, "Đang nén và lưu tệp Excel...");
                await MiniExcel.SaveAsAsync(filePath, sheets, overwriteFile: true);

                _jobManager.CompleteJob(jobId, filePath, fileName);
            }
            catch (Exception ex)
            {
                _jobManager.FailJob(jobId, ex.Message);
            }
        });

        return jobId;
    }
}
