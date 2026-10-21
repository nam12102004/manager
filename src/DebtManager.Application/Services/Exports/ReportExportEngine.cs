using System.Globalization;
using DebtManager.Application.DTOs.Exports;
using DebtManager.Application.Interfaces;
using DebtManager.Application.Interfaces.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using MiniExcelLibs;

namespace DebtManager.Application.Services.Exports;

public class ReportExportEngine
{
    private readonly IExportJobManager _jobManager;
    private readonly IBackgroundTaskQueue _queue;

    public ReportExportEngine(IExportJobManager jobManager, IBackgroundTaskQueue queue)
    {
        _jobManager = jobManager;
        _queue = queue;
    }

    public string StartExport(ExportReportRequestDto request)
    {
        request.ProductIds ??= new();
        request.CustomerIds ??= new();
        request.SupplierIds ??= new();
        request.Warehouses ??= new();

        var reportTitle = GetReportTitle(request);
        var jobId = _jobManager.CreateJob($"Đang khởi tạo {reportTitle}...");

        _queue.QueueBackgroundWorkItemAsync(async (sp, ct) =>
        {
            try
            {
                var uow = sp.GetRequiredService<IUnitOfWork>();
                var tempDir = Path.Combine(Path.GetTempPath(), "debtmanager_exports");
                if (!Directory.Exists(tempDir)) Directory.CreateDirectory(tempDir);

                _jobManager.UpdateProgress(jobId, 10, "Đang xác định phạm vi thời gian...");
                var (rangeStart, rangeEndExclusive, periodLabel) = await PeriodResolver.ResolveAsync(
                    request.Period, request.ReportType, uow, ct);

                _jobManager.UpdateProgress(jobId, 20, "Đang phân bổ các mốc thời gian...");
                var buckets = BucketBuilder.Build(rangeStart, rangeEndExclusive, request.Granularity);

                if (buckets.Count > BucketBuilder.MaxBucketsAllowed)
                {
                    throw new InvalidOperationException($"Số mốc thời gian ({buckets.Count} cột) vượt quá giới hạn cho phép. Vui lòng chọn mốc lớn hơn (Tuần hoặc Tháng).");
                }

                _jobManager.UpdateProgress(jobId, 30, "Đang truy vấn dữ liệu từ máy chủ...");

                var sheets = new Dictionary<string, object>();
                var fileNamePrefix = GetFileNamePrefix(request.ReportType);
                var fileName = $"{fileNamePrefix}_{periodLabel}_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";
                var filePath = Path.Combine(tempDir, $"{jobId}.xlsx");

                switch (request.ReportType.ToLowerInvariant())
                {
                    case "purchases":
                        await BuildPurchasesReportAsync(sheets, request, buckets, rangeStart, rangeEndExclusive, uow, ct);
                        break;

                    case "inventory":
                        await BuildInventoryReportAsync(sheets, request, buckets, rangeStart, rangeEndExclusive, uow, ct);
                        break;

                    case "inout":
                        await BuildInOutReportAsync(sheets, request, buckets, rangeStart, rangeEndExclusive, uow, ct);
                        break;

                    case "cashflow":
                        await BuildCashflowReportAsync(sheets, request, buckets, rangeStart, rangeEndExclusive, uow, ct);
                        break;

                    case "debt":
                        await BuildDebtReportAsync(sheets, request, buckets, rangeStart, rangeEndExclusive, uow, ct);
                        break;

                    case "sales":
                    default:
                        await BuildSalesReportAsync(sheets, request, buckets, rangeStart, rangeEndExclusive, uow, ct);
                        break;
                }

                _jobManager.UpdateProgress(jobId, 85, "Đang ghi dữ liệu vào tệp Excel...");
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

    public async Task<ExcelPreviewResultDto> GeneratePreviewAsync(
        ExportReportRequestDto request,
        IUnitOfWork uow,
        CancellationToken ct = default)
    {
        request.ProductIds ??= new();
        request.CustomerIds ??= new();
        request.SupplierIds ??= new();
        request.Warehouses ??= new();

        var reportTitle = GetReportTitle(request);
        var (rangeStart, rangeEndExclusive, periodLabel) = await PeriodResolver.ResolveAsync(
            request.Period, request.ReportType, uow, ct);

        var buckets = BucketBuilder.Build(rangeStart, rangeEndExclusive, request.Granularity);
        if (buckets.Count > BucketBuilder.MaxBucketsAllowed)
        {
            buckets = buckets.Take(BucketBuilder.MaxBucketsAllowed).ToList();
        }

        // Always generate detail sheet for preview
        var originalDetail = request.IncludeDetailSheet;
        request.IncludeDetailSheet = true;

        var sheets = new Dictionary<string, object>();
        var rType = request.ReportType.ToLowerInvariant();

        switch (rType)
        {
            case "purchases":
                await BuildPurchasesReportAsync(sheets, request, buckets, rangeStart, rangeEndExclusive, uow, ct);
                break;
            case "inventory":
                await BuildInventoryReportAsync(sheets, request, buckets, rangeStart, rangeEndExclusive, uow, ct);
                break;
            case "inout":
                await BuildInOutReportAsync(sheets, request, buckets, rangeStart, rangeEndExclusive, uow, ct);
                break;
            case "cashflow":
                await BuildCashflowReportAsync(sheets, request, buckets, rangeStart, rangeEndExclusive, uow, ct);
                break;
            case "debt":
                await BuildDebtReportAsync(sheets, request, buckets, rangeStart, rangeEndExclusive, uow, ct);
                break;
            case "sales":
            default:
                await BuildSalesReportAsync(sheets, request, buckets, rangeStart, rangeEndExclusive, uow, ct);
                break;
        }

        request.IncludeDetailSheet = originalDetail;

        var result = new ExcelPreviewResultDto
        {
            PeriodLabel = periodLabel,
            ReportTitle = char.ToUpper(reportTitle[0]) + reportTitle.Substring(1),
            Buckets = buckets.Select(b => b.Header).ToList()
        };

        List<string>? activeWarehouses = null;
        if (request.Warehouses != null && request.Warehouses.Count > 0)
        {
            activeWarehouses = request.Warehouses;
        }
        else if (request.BreakdownByWarehouse)
        {
            if (rType == "inventory")
            {
                activeWarehouses = new List<string> { "warehouse1", "warehouse2", "warehouse3" };
            }
            else if (rType == "purchases")
            {
                var q = uow.ImportVoucherItems.Query()
                    .Where(i => i.ImportVoucher.Status != "cancelled" && i.ImportVoucher.Date >= rangeStart && i.ImportVoucher.Date < rangeEndExclusive);
                if (request.SupplierIds.Count > 0)
                    q = q.Where(i => request.SupplierIds.Contains(i.ImportVoucher.SupplierId));
                if (request.ProductIds.Count > 0)
                    q = q.Where(i => request.ProductIds.Contains(i.ProductId));
                activeWarehouses = await q
                    .Select(i => i.ImportVoucher.Warehouse)
                    .Where(w => !string.IsNullOrEmpty(w))
                    .Distinct()
                    .ToListAsync(ct);
            }
            else
            {
                var q = uow.ExportVoucherItems.Query()
                    .Where(i => i.ExportVoucher.Status != "cancelled" && i.ExportVoucher.Date >= rangeStart && i.ExportVoucher.Date < rangeEndExclusive);
                if (request.CustomerIds.Count > 0)
                    q = q.Where(i => request.CustomerIds.Contains(i.ExportVoucher.CustomerId));
                if (request.ProductIds.Count > 0)
                    q = q.Where(i => request.ProductIds.Contains(i.ProductId));
                activeWarehouses = await q
                    .Select(i => i.ExportVoucher.Warehouse)
                    .Where(w => !string.IsNullOrEmpty(w))
                    .Distinct()
                    .ToListAsync(ct);
            }
        }

        SetupPreviewColumnMetadata(result, request, rType, activeWarehouses);

        if (sheets.Count > 0)
        {
            var firstPair = sheets.First();
            result.Sheet1Title = "Sheet 1: Tổng hợp";
            if (firstPair.Value is List<Dictionary<string, object>> summaryList)
            {
                result.TotalSummaryRows = summaryList.Count;
                if (summaryList.Count > 0)
                {
                    result.SummaryColumns = summaryList[0].Keys.ToList();

                    bool hasRealData = summaryList.Count > 1;
                    if (!hasRealData && summaryList.Count == 1)
                    {
                        var singleRow = summaryList[0];
                        hasRealData = singleRow.Values.Any(v => v is decimal d && d != 0 || v is int i && i != 0);
                    }
                    result.HasData = hasRealData;

                    if (summaryList.Count > 35)
                    {
                        var previewRows = summaryList.Take(34).ToList();
                        var lastTotal = summaryList.Last();
                        previewRows.Add(lastTotal);
                        result.SummaryRows = previewRows.Select(r => r.ToDictionary(k => k.Key, v => (object?)v.Value)).ToList();
                    }
                    else
                    {
                        result.SummaryRows = summaryList.Select(r => r.ToDictionary(k => k.Key, v => (object?)v.Value)).ToList();
                    }
                }
            }
        }

        if (sheets.TryGetValue("Chi_Tiet", out var detailObj) && detailObj is List<Dictionary<string, object>> detailList)
        {
            result.TotalDetailRows = detailList.Count;
            if (detailList.Count > 0)
            {
                result.DetailColumns = detailList[0].Keys.ToList();
                result.DetailRows = detailList.Take(35).Select(r => r.ToDictionary(k => k.Key, v => (object?)v.Value)).ToList();
            }
        }

        return result;
    }

    private static string FormatWarehouseLabel(string wh)
    {
        if (string.IsNullOrWhiteSpace(wh)) return "Kho";
        var lower = wh.ToLowerInvariant().Trim();
        if (lower == "warehouse1" || lower == "kho_1" || lower == "kho1") return "Kho 1";
        if (lower == "warehouse2" || lower == "kho_2" || lower == "kho2") return "Kho 2";
        if (lower == "warehouse3" || lower == "kho_3" || lower == "kho3") return "Kho 3";
        return wh;
    }

    private static void SetupPreviewColumnMetadata(
        ExcelPreviewResultDto result,
        ExportReportRequestDto req,
        string rType,
        List<string>? activeWarehouses = null)
    {
        var gb = (req.GroupBy ?? "product").ToLowerInvariant();
        var isSupplier = rType == "purchases" || req.PartnerScope == "supplier";
        var partnerHeader = isSupplier ? "Nhà cung cấp" : "Khách hàng";
        var valueHeader = isSupplier ? "Tiền nhập" : "Doanh số";

        var isWhBreakdown = req.BreakdownByWarehouse;
        List<string> whs = new();
        if (isWhBreakdown)
        {
            if (req.Warehouses != null && req.Warehouses.Count > 1)
            {
                whs = req.Warehouses.Distinct().OrderBy(w => w).ToList();
            }
            else if (activeWarehouses != null && activeWarehouses.Count > 1)
            {
                whs = activeWarehouses.Distinct().OrderBy(w => w).ToList();
            }
            if (whs.Count <= 1)
            {
                isWhBreakdown = false;
            }
        }

        result.BreakdownByWarehouse = isWhBreakdown;
        result.Warehouses = whs.Select(FormatWarehouseLabel).ToList();

        if (rType == "sales" || rType == "purchases")
        {
            if (gb == "partner")
            {
                result.FixedColumns = new List<string> { "STT", "Mã đối tác", partnerHeader };
            }
            else if (gb == "partner_product")
            {
                result.FixedColumns = new List<string> { "STT", "Mã đối tác", partnerHeader, "Mã SKU", "Tên sản phẩm", "ĐVT" };
            }
            else if (gb == "product_partner")
            {
                result.FixedColumns = new List<string> { "STT", "Mã SKU", "Tên sản phẩm", "ĐVT", partnerHeader };
            }
            else if (gb == "warehouse_product")
            {
                result.FixedColumns = new List<string> { "STT", "Kho", "Mã SKU", "Tên sản phẩm", "ĐVT" };
            }
            else
            {
                result.FixedColumns = new List<string> { "STT", "Mã SKU", "Tên sản phẩm", "ĐVT" };
            }

            bool hasQty = req.IncludeQuantity;
            bool hasAmt = req.IncludeAmount || req.IncludeRevenue;
            bool hasPrice = req.IncludeAvgPrice || req.IncludePrice;

            if (isWhBreakdown)
            {
                if (hasQty)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        result.BucketMetrics.Add(new BucketMetricDto { Key = $"qty_{w}", Label = $"SL ({label})", Suffix = $" SL ({label})" });
                    }
                    result.BucketMetrics.Add(new BucketMetricDto { Key = "qty_tot", Label = "Tổng SL", Suffix = " (Tổng SL)" });
                }
                if (hasAmt)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        result.BucketMetrics.Add(new BucketMetricDto { Key = $"amt_{w}", Label = label, Suffix = $" ({label})" });
                    }
                    result.BucketMetrics.Add(new BucketMetricDto { Key = "amt_tot", Label = $"Tổng {valueHeader}", Suffix = $" (Tổng {valueHeader})" });
                }
                if (hasPrice)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        result.BucketMetrics.Add(new BucketMetricDto { Key = $"prc_{w}", Label = $"Giá ({label})", Suffix = $" Giá ({label})" });
                    }
                    result.BucketMetrics.Add(new BucketMetricDto { Key = "prc_avg", Label = "Đơn giá TB", Suffix = " (Đơn giá TB)" });
                }

                if (hasQty)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        result.TotalColumns.Add($"Tổng SL ({label})");
                    }
                    result.TotalColumns.Add("Tổng Số Lượng");
                }
                if (hasAmt)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        result.TotalColumns.Add($"Tổng {valueHeader} ({label})");
                    }
                    result.TotalColumns.Add($"Tổng {valueHeader}");
                }
                if (hasPrice)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        result.TotalColumns.Add($"Đơn giá TB ({label})");
                    }
                    result.TotalColumns.Add("Đơn Giá TB Toàn Kỳ");
                }
            }
            else
            {
                if (hasQty)
                {
                    result.BucketMetrics.Add(new BucketMetricDto { Key = "qty", Label = "SL", Suffix = " (SL)" });
                }
                if (hasAmt)
                {
                    result.BucketMetrics.Add(new BucketMetricDto { Key = "amt", Label = valueHeader, Suffix = $" ({valueHeader})" });
                }
                if (hasPrice)
                {
                    result.BucketMetrics.Add(new BucketMetricDto { Key = "prc", Label = "Đơn giá TB", Suffix = " (Đơn giá TB)" });
                }

                if (hasQty) result.TotalColumns.Add("Tổng Số Lượng");
                if (hasAmt) result.TotalColumns.Add($"Tổng {valueHeader}");
                if (hasPrice) result.TotalColumns.Add("Đơn Giá TB Toàn Kỳ");
            }
        }
        else if (rType == "inout")
        {
            if (gb == "warehouse_product")
            {
                result.FixedColumns = new List<string> { "STT", "Mã SKU", "Tên sản phẩm", "ĐVT", "Kho" };
            }
            else
            {
                result.FixedColumns = new List<string> { "STT", "Mã SKU", "Tên sản phẩm", "ĐVT" };
            }

            result.BucketMetrics.Add(new BucketMetricDto { Key = "in_qty", Label = "SL Nhập", Suffix = " Nhập (SL)" });
            if (req.IncludeAmount)
                result.BucketMetrics.Add(new BucketMetricDto { Key = "in_amt", Label = "Tiền nhập", Suffix = " Tiền nhập" });
            result.BucketMetrics.Add(new BucketMetricDto { Key = "out_qty", Label = "SL Xuất", Suffix = " Xuất (SL)" });
            if (req.IncludeAmount)
                result.BucketMetrics.Add(new BucketMetricDto { Key = "out_amt", Label = "Doanh số", Suffix = " Doanh số" });
            result.BucketMetrics.Add(new BucketMetricDto { Key = "diff_qty", Label = "Chênh lệch SL", Suffix = " Chênh lệch SL" });

            result.TotalColumns.Add("Tổng Nhập (SL)");
            if (req.IncludeAmount) result.TotalColumns.Add("Tổng Tiền Nhập");
            result.TotalColumns.Add("Tổng Xuất (SL)");
            if (req.IncludeAmount) result.TotalColumns.Add("Tổng Doanh Số");
            result.TotalColumns.Add("Chênh Lệch SL");
        }
        else if (rType == "cashflow")
        {
            result.FixedColumns = new List<string> { "STT", "Loại đối tác", "Mã đối tác", "Tên đối tác" };
            result.BucketMetrics.Add(new BucketMetricDto { Key = "rec", Label = "Thu", Suffix = " (Thu)" });
            result.BucketMetrics.Add(new BucketMetricDto { Key = "pay", Label = "Chi", Suffix = " (Chi)" });
            result.BucketMetrics.Add(new BucketMetricDto { Key = "net", Label = "Ròng", Suffix = " (Ròng)" });

            result.TotalColumns.Add("Tổng Thu");
            result.TotalColumns.Add("Tổng Chi");
            result.TotalColumns.Add("Ròng Toàn Kỳ");
        }
        else if (rType == "debt")
        {
            result.FixedColumns = new List<string> { "STT", "Loại", "Mã", "Tên đối tác", "Đầu kỳ" };
            result.BucketMetrics.Add(new BucketMetricDto { Key = "inc", Label = "Tăng", Suffix = " (Tăng)" });
            result.BucketMetrics.Add(new BucketMetricDto { Key = "dec", Label = "Giảm", Suffix = " (Giảm)" });
            result.BucketMetrics.Add(new BucketMetricDto { Key = "bal", Label = "Dư nợ", Suffix = " (Dư nợ)" });

            result.TotalColumns.Add("Tổng Tăng");
            result.TotalColumns.Add("Tổng Giảm");
            result.TotalColumns.Add("Cuối kỳ");
        }
        else if (rType == "inventory")
        {
            var isWhRowGroup = gb == "warehouse_product";
            result.FixedColumns = isWhRowGroup
                ? new List<string> { "STT", "Kho", "Mã SKU", "Tên sản phẩm", "Danh mục", "ĐVT" }
                : new List<string> { "STT", "Mã SKU", "Tên sản phẩm", "Danh mục", "ĐVT" };
            result.Buckets = new List<string> { "Tồn kho hiện tại" };
            result.TotalColumns = new List<string>();

            bool hasQty = req.IncludeQuantity;
            bool hasPrice = req.IncludePrice || req.IncludeAvgPrice;
            bool hasAmt = req.IncludeAmount || req.IncludeRevenue;
            if (!hasQty && !hasPrice && !hasAmt) hasQty = true;

            if (isWhBreakdown && !isWhRowGroup)
            {
                if (hasQty)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        result.BucketMetrics.Add(new BucketMetricDto { Key = $"stock_{w}", Label = $"Tồn ({label})", Suffix = $" ({label})" });
                    }
                    result.BucketMetrics.Add(new BucketMetricDto { Key = "stock_tot", Label = "Tổng tồn", Suffix = " (Tổng tồn)" });
                }
                if (hasPrice)
                {
                    result.BucketMetrics.Add(new BucketMetricDto { Key = "cost_price", Label = "Đơn giá vốn", Suffix = " (Đơn giá vốn)" });
                }
                if (hasAmt)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        result.BucketMetrics.Add(new BucketMetricDto { Key = $"val_{w}", Label = $"Giá trị ({label})", Suffix = $" Giá trị ({label})" });
                    }
                    result.BucketMetrics.Add(new BucketMetricDto { Key = "stock_val", Label = "Tổng giá trị tồn", Suffix = " (Giá trị tồn)" });
                }
            }
            else
            {
                if (hasQty)
                {
                    result.BucketMetrics.Add(new BucketMetricDto { Key = "stock_tot", Label = "Số lượng tồn", Suffix = " (Tồn kho)" });
                }
                if (hasPrice)
                {
                    result.BucketMetrics.Add(new BucketMetricDto { Key = "cost_price", Label = "Đơn giá vốn", Suffix = " (Đơn giá vốn)" });
                }
                if (hasAmt)
                {
                    result.BucketMetrics.Add(new BucketMetricDto { Key = "stock_val", Label = "Giá trị tồn", Suffix = " (Giá trị tồn)" });
                }
            }

            result.BucketMetrics.Add(new BucketMetricDto { Key = "status", Label = "Trạng thái", Suffix = " (Trạng thái)" });
        }
    }


    private static string GetReportTitle(ExportReportRequestDto req)
    {
        return req.ReportType.ToLowerInvariant() switch
        {
            "purchases" => "báo cáo nhập hàng",
            "inventory" => "báo cáo tồn kho hiện tại",
            "inout" => "báo cáo nhập xuất sản phẩm",
            "cashflow" => "báo cáo thu chi",
            "debt" => "báo cáo công nợ theo kỳ",
            _ => "báo cáo xuất bán hàng"
        };
    }

    private static string GetFileNamePrefix(string reportType)
    {
        return reportType.ToLowerInvariant() switch
        {
            "purchases" => "BaoCao_NhapHang",
            "inventory" => "BaoCao_TonKho_HienTai",
            "inout" => "BaoCao_NhapXuat_SP",
            "cashflow" => "BaoCao_ThuChi",
            "debt" => "BaoCao_CongNo_TheoKy",
            _ => "BaoCao_XuatHang"
        };
    }

    // ==========================================
    // 1. SALES REPORT (Xuất Bán Hàng)
    // ==========================================
    private static async Task BuildSalesReportAsync(
        Dictionary<string, object> sheets,
        ExportReportRequestDto request,
        List<TimeBucket> buckets,
        DateTime start,
        DateTime end,
        IUnitOfWork uow,
        CancellationToken ct)
    {
        var itemQuery = uow.ExportVoucherItems.Query()
            .Where(i => i.ExportVoucher.Status != "cancelled" && i.ExportVoucher.Date >= start && i.ExportVoucher.Date < end);

        if (request.CustomerIds.Count > 0)
            itemQuery = itemQuery.Where(i => request.CustomerIds.Contains(i.ExportVoucher.CustomerId));
        if (request.Warehouses.Count > 0)
            itemQuery = itemQuery.Where(i => request.Warehouses.Contains(i.ExportVoucher.Warehouse));
        if (request.ProductIds.Count > 0)
            itemQuery = itemQuery.Where(i => request.ProductIds.Contains(i.ProductId));

        var records = await itemQuery.Select(i => new
        {
            Date = i.ExportVoucher.Date,
            VoucherNumber = i.ExportVoucher.VoucherNumber,
            CustomerId = i.ExportVoucher.CustomerId,
            CustomerCode = i.ExportVoucher.Customer != null ? i.ExportVoucher.Customer.Code : "",
            CustomerName = i.ExportVoucher.Customer != null ? i.ExportVoucher.Customer.Name : "Khách lẻ",
            Warehouse = i.ExportVoucher.Warehouse ?? "",
            ProductId = i.ProductId,
            ProductSku = i.Product != null ? i.Product.Sku : $"SP{i.ProductId:D3}",
            ProductName = i.Product != null ? i.Product.Name : $"Sản phẩm #{i.ProductId}",
            Unit = i.Product != null ? (i.Product.Uom ?? "") : "",
            Quantity = (decimal)i.Quantity,
            Amount = i.LineTotal,
            Price = i.SalePrice
        }).ToListAsync(ct);

        var rows = GenerateStandardMatrixRows(
            records.Select(r => new StandardRecord
            {
                Date = r.Date,
                ProductId = r.ProductId,
                ProductSku = r.ProductSku,
                ProductName = r.ProductName,
                Unit = r.Unit,
                PartnerId = r.CustomerId,
                PartnerCode = r.CustomerCode,
                PartnerName = r.CustomerName,
                Warehouse = r.Warehouse,
                Quantity = r.Quantity,
                Amount = r.Amount,
                Price = r.Price
            }).ToList(),
            buckets,
            request.GroupBy,
            request.IncludeQuantity,
            request.IncludeAmount || request.IncludeRevenue,
            request.IncludeAvgPrice || request.IncludePrice,
            valueHeader: "Doanh số",
            partnerHeader: "Khách hàng",
            breakdownByWarehouse: request.BreakdownByWarehouse,
            requestedWarehouses: request.Warehouses);

        sheets["Xuat_Ban"] = rows;

        if (request.IncludeDetailSheet)
        {
            sheets["Chi_Tiet"] = records.Select(r => new Dictionary<string, object>
            {
                ["Ngày chứng từ"] = r.Date.ToString("dd/MM/yyyy"),
                ["Số phiếu"] = r.VoucherNumber,
                ["Mã KH"] = r.CustomerCode,
                ["Khách hàng"] = r.CustomerName,
                ["Kho"] = r.Warehouse,
                ["Mã SKU"] = r.ProductSku,
                ["Sản phẩm"] = r.ProductName,
                ["ĐVT"] = r.Unit,
                ["Số lượng"] = r.Quantity,
                ["Đơn giá"] = r.Price,
                ["Thành tiền"] = r.Amount
            }).ToList();
        }
    }

    // ==========================================
    // 2. PURCHASES REPORT (Nhập Hàng)
    // ==========================================
    private static async Task BuildPurchasesReportAsync(
        Dictionary<string, object> sheets,
        ExportReportRequestDto request,
        List<TimeBucket> buckets,
        DateTime start,
        DateTime end,
        IUnitOfWork uow,
        CancellationToken ct)
    {
        var itemQuery = uow.ImportVoucherItems.Query()
            .Where(i => i.ImportVoucher.Status != "cancelled" && i.ImportVoucher.Date >= start && i.ImportVoucher.Date < end);

        if (request.SupplierIds.Count > 0)
            itemQuery = itemQuery.Where(i => request.SupplierIds.Contains(i.ImportVoucher.SupplierId));
        if (request.Warehouses.Count > 0)
            itemQuery = itemQuery.Where(i => request.Warehouses.Contains(i.ImportVoucher.Warehouse));
        if (request.ProductIds.Count > 0)
            itemQuery = itemQuery.Where(i => request.ProductIds.Contains(i.ProductId));

        var records = await itemQuery.Select(i => new
        {
            Date = i.ImportVoucher.Date,
            VoucherNumber = i.ImportVoucher.VoucherNumber,
            SupplierId = i.ImportVoucher.SupplierId,
            SupplierCode = i.ImportVoucher.Supplier != null ? i.ImportVoucher.Supplier.Code : "",
            SupplierName = i.ImportVoucher.Supplier != null ? i.ImportVoucher.Supplier.Name : "Nhà cung cấp",
            Warehouse = i.ImportVoucher.Warehouse ?? "",
            ProductId = i.ProductId,
            ProductSku = i.Product != null ? i.Product.Sku : (i.Sku ?? $"SP{i.ProductId:D3}"),
            ProductName = i.Product != null ? i.Product.Name : (i.ProductName ?? $"Sản phẩm #{i.ProductId}"),
            Unit = i.Product != null ? (i.Product.Uom ?? "") : "",
            Quantity = (decimal)i.Quantity,
            Amount = i.LineTotal,
            Price = i.UnitPrice
        }).ToListAsync(ct);

        var rows = GenerateStandardMatrixRows(
            records.Select(r => new StandardRecord
            {
                Date = r.Date,
                ProductId = r.ProductId,
                ProductSku = r.ProductSku,
                ProductName = r.ProductName,
                Unit = r.Unit,
                PartnerId = r.SupplierId,
                PartnerCode = r.SupplierCode,
                PartnerName = r.SupplierName,
                Warehouse = r.Warehouse,
                Quantity = r.Quantity,
                Amount = r.Amount,
                Price = r.Price
            }).ToList(),
            buckets,
            request.GroupBy,
            request.IncludeQuantity,
            request.IncludeAmount || request.IncludeRevenue,
            request.IncludeAvgPrice || request.IncludePrice,
            valueHeader: "Tiền nhập",
            partnerHeader: "Nhà cung cấp",
            breakdownByWarehouse: request.BreakdownByWarehouse,
            requestedWarehouses: request.Warehouses);

        sheets["Nhap_Hang"] = rows;

        if (request.IncludeDetailSheet)
        {
            sheets["Chi_Tiet"] = records.Select(r => new Dictionary<string, object>
            {
                ["Ngày chứng từ"] = r.Date.ToString("dd/MM/yyyy"),
                ["Số phiếu"] = r.VoucherNumber,
                ["Mã NCC"] = r.SupplierCode,
                ["Nhà cung cấp"] = r.SupplierName,
                ["Kho"] = r.Warehouse,
                ["Mã SKU"] = r.ProductSku,
                ["Sản phẩm"] = r.ProductName,
                ["ĐVT"] = r.Unit,
                ["Số lượng"] = r.Quantity,
                ["Giá nhập"] = r.Price,
                ["Thành tiền"] = r.Amount
            }).ToList();
        }
    }

    // ==========================================
    // 3. IN-OUT REPORT (Nhập - Xuất Sản Phẩm)
    // ==========================================
    private static async Task BuildInOutReportAsync(
        Dictionary<string, object> sheets,
        ExportReportRequestDto request,
        List<TimeBucket> buckets,
        DateTime start,
        DateTime end,
        IUnitOfWork uow,
        CancellationToken ct)
    {
        // Import query
        var impQuery = uow.ImportVoucherItems.Query()
            .Where(i => i.ImportVoucher.Status != "cancelled" && i.ImportVoucher.Date >= start && i.ImportVoucher.Date < end);
        if (request.Warehouses.Count > 0)
            impQuery = impQuery.Where(i => request.Warehouses.Contains(i.ImportVoucher.Warehouse));
        if (request.ProductIds.Count > 0)
            impQuery = impQuery.Where(i => request.ProductIds.Contains(i.ProductId));

        var imports = await impQuery.Select(i => new
        {
            Date = i.ImportVoucher.Date,
            Warehouse = i.ImportVoucher.Warehouse ?? "",
            ProductId = i.ProductId,
            ProductSku = i.Product != null ? i.Product.Sku : (i.Sku ?? $"SP{i.ProductId:D3}"),
            ProductName = i.Product != null ? i.Product.Name : (i.ProductName ?? $"Sản phẩm #{i.ProductId}"),
            Unit = i.Product != null ? (i.Product.Uom ?? "") : "",
            Quantity = (decimal)i.Quantity,
            Amount = i.LineTotal
        }).ToListAsync(ct);

        // Export query
        var expQuery = uow.ExportVoucherItems.Query()
            .Where(i => i.ExportVoucher.Status != "cancelled" && i.ExportVoucher.Date >= start && i.ExportVoucher.Date < end);
        if (request.Warehouses.Count > 0)
            expQuery = expQuery.Where(i => request.Warehouses.Contains(i.ExportVoucher.Warehouse));
        if (request.ProductIds.Count > 0)
            expQuery = expQuery.Where(i => request.ProductIds.Contains(i.ProductId));

        var exports = await expQuery.Select(i => new
        {
            Date = i.ExportVoucher.Date,
            Warehouse = i.ExportVoucher.Warehouse ?? "",
            ProductId = i.ProductId,
            ProductSku = i.Product != null ? i.Product.Sku : $"SP{i.ProductId:D3}",
            ProductName = i.Product != null ? i.Product.Name : $"Sản phẩm #{i.ProductId}",
            Unit = i.Product != null ? (i.Product.Uom ?? "") : "",
            Quantity = (decimal)i.Quantity,
            Amount = i.LineTotal
        }).ToListAsync(ct);

        // Group rows by Product or Warehouse_Product
        var isWarehouseGroup = request.GroupBy.Equals("warehouse_product", StringComparison.OrdinalIgnoreCase);

        var allProductKeys = imports.Select(i => (i.ProductId, i.ProductSku, i.ProductName, i.Unit, isWarehouseGroup ? i.Warehouse : ""))
            .Concat(exports.Select(e => (e.ProductId, e.ProductSku, e.ProductName, e.Unit, isWarehouseGroup ? e.Warehouse : "")))
            .Distinct()
            .OrderBy(p => p.Item5)
            .ThenBy(p => p.ProductSku)
            .ToList();

        var rows = new List<Dictionary<string, object>>();

        // Totals per bucket
        var totalInQtyByBucket = new decimal[buckets.Count];
        var totalInAmtByBucket = new decimal[buckets.Count];
        var totalOutQtyByBucket = new decimal[buckets.Count];
        var totalOutAmtByBucket = new decimal[buckets.Count];

        decimal grandTotalInQty = 0;
        decimal grandTotalInAmt = 0;
        decimal grandTotalOutQty = 0;
        decimal grandTotalOutAmt = 0;

        int stt = 1;
        foreach (var p in allProductKeys)
        {
            var row = new Dictionary<string, object>
            {
                ["STT"] = stt++,
                ["Mã SKU"] = p.ProductSku,
                ["Tên sản phẩm"] = p.ProductName,
                ["ĐVT"] = p.Unit
            };
            if (isWarehouseGroup) row["Kho"] = p.Item5;

            decimal rowInQty = 0;
            decimal rowInAmt = 0;
            decimal rowOutQty = 0;
            decimal rowOutAmt = 0;

            for (int b = 0; b < buckets.Count; b++)
            {
                var bucket = buckets[b];
                var inMatches = imports.Where(i => i.ProductId == p.ProductId
                    && (!isWarehouseGroup || i.Warehouse == p.Item5)
                    && i.Date >= bucket.Start && i.Date < bucket.EndExclusive);

                var outMatches = exports.Where(e => e.ProductId == p.ProductId
                    && (!isWarehouseGroup || e.Warehouse == p.Item5)
                    && e.Date >= bucket.Start && e.Date < bucket.EndExclusive);

                decimal inQ = inMatches.Sum(i => i.Quantity);
                decimal inA = inMatches.Sum(i => i.Amount);
                decimal outQ = outMatches.Sum(e => e.Quantity);
                decimal outA = outMatches.Sum(e => e.Amount);

                rowInQty += inQ;
                rowInAmt += inA;
                rowOutQty += outQ;
                rowOutAmt += outA;

                totalInQtyByBucket[b] += inQ;
                totalInAmtByBucket[b] += inA;
                totalOutQtyByBucket[b] += outQ;
                totalOutAmtByBucket[b] += outA;

                row[$"{bucket.Header} Nhập (SL)"] = inQ;
                if (request.IncludeAmount) row[$"{bucket.Header} Tiền nhập"] = inA;
                row[$"{bucket.Header} Xuất (SL)"] = outQ;
                if (request.IncludeAmount) row[$"{bucket.Header} Doanh số"] = outA;
                row[$"{bucket.Header} Chênh lệch SL"] = inQ - outQ;
            }

            row["Tổng Nhập (SL)"] = rowInQty;
            if (request.IncludeAmount) row["Tổng Tiền Nhập"] = rowInAmt;
            row["Tổng Xuất (SL)"] = rowOutQty;
            if (request.IncludeAmount) row["Tổng Doanh Số"] = rowOutAmt;
            row["Chênh Lệch SL"] = rowInQty - rowOutQty;

            grandTotalInQty += rowInQty;
            grandTotalInAmt += rowInAmt;
            grandTotalOutQty += rowOutQty;
            grandTotalOutAmt += rowOutAmt;

            rows.Add(row);
        }

        // Summary Total Row
        var totalRow = new Dictionary<string, object>
        {
            ["STT"] = "TỔNG",
            ["Mã SKU"] = "CỘNG",
            ["Tên sản phẩm"] = $"Toàn bộ ({allProductKeys.Count} mặt hàng)",
            ["ĐVT"] = ""
        };
        if (isWarehouseGroup) totalRow["Kho"] = "";

        for (int b = 0; b < buckets.Count; b++)
        {
            var bucket = buckets[b];
            totalRow[$"{bucket.Header} Nhập (SL)"] = totalInQtyByBucket[b];
            if (request.IncludeAmount) totalRow[$"{bucket.Header} Tiền nhập"] = totalInAmtByBucket[b];
            totalRow[$"{bucket.Header} Xuất (SL)"] = totalOutQtyByBucket[b];
            if (request.IncludeAmount) totalRow[$"{bucket.Header} Doanh số"] = totalOutAmtByBucket[b];
            totalRow[$"{bucket.Header} Chênh lệch SL"] = totalInQtyByBucket[b] - totalOutQtyByBucket[b];
        }

        totalRow["Tổng Nhập (SL)"] = grandTotalInQty;
        if (request.IncludeAmount) totalRow["Tổng Tiền Nhập"] = grandTotalInAmt;
        totalRow["Tổng Xuất (SL)"] = grandTotalOutQty;
        if (request.IncludeAmount) totalRow["Tổng Doanh Số"] = grandTotalOutAmt;
        totalRow["Chênh Lệch SL"] = grandTotalInQty - grandTotalOutQty;

        rows.Add(totalRow);
        sheets["Nhap_Xuat_SP"] = rows;
    }

    // ==========================================
    // 4. CASHFLOW REPORT (Thu - Chi)
    // ==========================================
    private static async Task BuildCashflowReportAsync(
        Dictionary<string, object> sheets,
        ExportReportRequestDto request,
        List<TimeBucket> buckets,
        DateTime start,
        DateTime end,
        IUnitOfWork uow,
        CancellationToken ct)
    {
        // Receipts query: only with partner
        var recQuery = uow.Receipts.Query()
            .Where(r => r.Date >= start && r.Date < end && (r.CustomerId.HasValue || r.SupplierId.HasValue));

        if (request.PartnerScope == "customer")
            recQuery = recQuery.Where(r => r.CustomerId.HasValue);
        else if (request.PartnerScope == "supplier")
            recQuery = recQuery.Where(r => r.SupplierId.HasValue);

        if (request.CustomerIds.Count > 0)
            recQuery = recQuery.Where(r => r.CustomerId.HasValue && request.CustomerIds.Contains(r.CustomerId.Value));
        if (request.SupplierIds.Count > 0)
            recQuery = recQuery.Where(r => r.SupplierId.HasValue && request.SupplierIds.Contains(r.SupplierId.Value));

        var receipts = await recQuery.Select(r => new
        {
            Date = r.Date,
            ReceiptNumber = r.ReceiptNumber,
            Amount = r.Amount,
            IsCustomer = r.CustomerId.HasValue,
            PartnerId = r.CustomerId ?? r.SupplierId ?? 0,
            PartnerCode = r.Customer != null ? r.Customer.Code : (r.Supplier != null ? r.Supplier.Code : ""),
            PartnerName = r.Customer != null ? r.Customer.Name : (r.Supplier != null ? r.Supplier.Name : "")
        }).ToListAsync(ct);

        // Payments query: exclude cancelled, only with partner
        var payQuery = uow.Payments.Query()
            .Where(p => p.Status != "cancelled" && p.Date >= start && p.Date < end && (p.CustomerId.HasValue || p.SupplierId.HasValue));

        if (request.PartnerScope == "customer")
            payQuery = payQuery.Where(p => p.CustomerId.HasValue);
        else if (request.PartnerScope == "supplier")
            payQuery = payQuery.Where(p => p.SupplierId.HasValue);

        if (request.CustomerIds.Count > 0)
            payQuery = payQuery.Where(p => p.CustomerId.HasValue && request.CustomerIds.Contains(p.CustomerId.Value));
        if (request.SupplierIds.Count > 0)
            payQuery = payQuery.Where(p => p.SupplierId.HasValue && request.SupplierIds.Contains(p.SupplierId.Value));

        var payments = await payQuery.Select(p => new
        {
            Date = p.Date,
            PaymentNumber = p.PaymentNumber,
            Amount = p.Amount,
            IsCustomer = p.CustomerId.HasValue,
            PartnerId = p.CustomerId ?? p.SupplierId ?? 0,
            PartnerCode = p.Customer != null ? p.Customer.Code : (p.Supplier != null ? p.Supplier.Code : ""),
            PartnerName = p.Customer != null ? p.Customer.Name : (p.Supplier != null ? p.Supplier.Name : "")
        }).ToListAsync(ct);

        // Partner list
        var partners = receipts.Select(r => (r.IsCustomer, r.PartnerId, r.PartnerCode, r.PartnerName))
            .Concat(payments.Select(p => (p.IsCustomer, p.PartnerId, p.PartnerCode, p.PartnerName)))
            .Distinct()
            .OrderBy(p => p.IsCustomer ? 0 : 1)
            .ThenBy(p => p.PartnerCode)
            .ToList();

        var rows = new List<Dictionary<string, object>>();
        var totalThuByBucket = new decimal[buckets.Count];
        var totalChiByBucket = new decimal[buckets.Count];
        decimal grandTotalThu = 0;
        decimal grandTotalChi = 0;

        int stt = 1;
        foreach (var p in partners)
        {
            var row = new Dictionary<string, object>
            {
                ["STT"] = stt++,
                ["Loại đối tác"] = p.IsCustomer ? "Khách hàng" : "Nhà cung cấp",
                ["Mã đối tác"] = p.PartnerCode,
                ["Tên đối tác"] = p.PartnerName
            };

            decimal rowThu = 0;
            decimal rowChi = 0;

            for (int b = 0; b < buckets.Count; b++)
            {
                var bucket = buckets[b];
                var thu = receipts
                    .Where(r => r.IsCustomer == p.IsCustomer && r.PartnerId == p.PartnerId && r.Date >= bucket.Start && r.Date < bucket.EndExclusive)
                    .Sum(r => r.Amount);
                var chi = payments
                    .Where(pay => pay.IsCustomer == p.IsCustomer && pay.PartnerId == p.PartnerId && pay.Date >= bucket.Start && pay.Date < bucket.EndExclusive)
                    .Sum(pay => pay.Amount);

                rowThu += thu;
                rowChi += chi;
                totalThuByBucket[b] += thu;
                totalChiByBucket[b] += chi;

                row[$"{bucket.Header} (Thu)"] = thu;
                row[$"{bucket.Header} (Chi)"] = chi;
                row[$"{bucket.Header} (Ròng)"] = thu - chi;
            }

            row["Tổng Thu"] = rowThu;
            row["Tổng Chi"] = rowChi;
            row["Ròng Toàn Kỳ"] = rowThu - rowChi;

            grandTotalThu += rowThu;
            grandTotalChi += rowChi;
            rows.Add(row);
        }

        // Summary row
        var totalRow = new Dictionary<string, object>
        {
            ["STT"] = "TỔNG",
            ["Loại đối tác"] = "CỘNG",
            ["Mã đối tác"] = "",
            ["Tên đối tác"] = $"Toàn bộ ({partners.Count} đối tác)"
        };

        for (int b = 0; b < buckets.Count; b++)
        {
            var bucket = buckets[b];
            totalRow[$"{bucket.Header} (Thu)"] = totalThuByBucket[b];
            totalRow[$"{bucket.Header} (Chi)"] = totalChiByBucket[b];
            totalRow[$"{bucket.Header} (Ròng)"] = totalThuByBucket[b] - totalChiByBucket[b];
        }

        totalRow["Tổng Thu"] = grandTotalThu;
        totalRow["Tổng Chi"] = grandTotalChi;
        totalRow["Ròng Toàn Kỳ"] = grandTotalThu - grandTotalChi;
        rows.Add(totalRow);

        sheets["Thu_Chi"] = rows;
    }

    // ==========================================
    // 5. DEBT REPORT (Công Nợ Theo Kỳ)
    // ==========================================
    private static async Task BuildDebtReportAsync(
        Dictionary<string, object> sheets,
        ExportReportRequestDto request,
        List<TimeBucket> buckets,
        DateTime start,
        DateTime end,
        IUnitOfWork uow,
        CancellationToken ct)
    {
        var rows = new List<Dictionary<string, object>>();
        int stt = 1;

        var totalDauKy = 0m;
        var totalTang = 0m;
        var totalGiam = 0m;
        var totalCuoiKy = 0m;

        var totalTangByBucket = new decimal[buckets.Count];
        var totalGiamByBucket = new decimal[buckets.Count];

        // Process Customers if in scope
        if (request.PartnerScope != "supplier")
        {
            var custQuery = uow.Customers.Query();
            if (request.CustomerIds.Count > 0)
                custQuery = custQuery.Where(c => request.CustomerIds.Contains(c.Id));

            var customers = await custQuery.Select(c => new { c.Id, c.Code, c.Name, c.Debt }).ToListAsync(ct);

            foreach (var c in customers)
            {
                var lastBefore = await uow.CustomerDebtHistories.Query()
                    .Where(h => h.CustomerId == c.Id && h.CreatedAt < start)
                    .OrderByDescending(h => h.CreatedAt)
                    .Select(h => (decimal?)h.AfterDebt)
                    .FirstOrDefaultAsync(ct);

                var dauKy = lastBefore ?? 0m;

                var histories = await uow.CustomerDebtHistories.Query()
                    .Where(h => h.CustomerId == c.Id && h.CreatedAt >= start && h.CreatedAt < end)
                    .Select(h => new { h.CreatedAt, h.Delta })
                    .ToListAsync(ct);

                decimal rowTang = 0;
                decimal rowGiam = 0;
                decimal runningBal = dauKy;

                var bucketData = new Dictionary<string, object>();
                for (int b = 0; b < buckets.Count; b++)
                {
                    var bucket = buckets[b];
                    var inBucket = histories.Where(h => h.CreatedAt >= bucket.Start && h.CreatedAt < bucket.EndExclusive);

                    decimal bTang = inBucket.Where(h => h.Delta > 0).Sum(h => h.Delta);
                    decimal bGiam = inBucket.Where(h => h.Delta < 0).Sum(h => Math.Abs(h.Delta));

                    rowTang += bTang;
                    rowGiam += bGiam;
                    runningBal += (bTang - bGiam);

                    totalTangByBucket[b] += bTang;
                    totalGiamByBucket[b] += bGiam;

                    bucketData[$"{bucket.Header} (Tăng)"] = bTang;
                    bucketData[$"{bucket.Header} (Giảm)"] = bGiam;
                    bucketData[$"{bucket.Header} (Dư nợ)"] = runningBal;
                }

                decimal cuoiKy = dauKy + rowTang - rowGiam;

                if (!request.IncludeZeroRows && dauKy == 0 && rowTang == 0 && rowGiam == 0 && cuoiKy == 0)
                {
                    continue;
                }

                var row = new Dictionary<string, object>
                {
                    ["STT"] = stt++,
                    ["Loại"] = "Khách hàng",
                    ["Mã"] = c.Code,
                    ["Tên đối tác"] = c.Name,
                    ["Đầu kỳ"] = dauKy
                };

                foreach (var kvp in bucketData) row[kvp.Key] = kvp.Value;

                row["Tổng Tăng"] = rowTang;
                row["Tổng Giảm"] = rowGiam;
                row["Cuối kỳ"] = cuoiKy;

                totalDauKy += dauKy;
                totalTang += rowTang;
                totalGiam += rowGiam;
                totalCuoiKy += cuoiKy;
                rows.Add(row);
            }
        }

        // Process Suppliers if in scope
        if (request.PartnerScope != "customer")
        {
            var suppQuery = uow.Suppliers.Query();
            if (request.SupplierIds.Count > 0)
                suppQuery = suppQuery.Where(s => request.SupplierIds.Contains(s.Id));

            var suppliers = await suppQuery.Select(s => new { s.Id, s.Code, s.Name, s.Debt }).ToListAsync(ct);

            foreach (var s in suppliers)
            {
                var lastBefore = await uow.SupplierDebtHistories.Query()
                    .Where(h => h.SupplierId == s.Id && h.CreatedAt < start)
                    .OrderByDescending(h => h.CreatedAt)
                    .Select(h => (decimal?)h.AfterDebt)
                    .FirstOrDefaultAsync(ct);

                var dauKy = lastBefore ?? 0m;

                var histories = await uow.SupplierDebtHistories.Query()
                    .Where(h => h.SupplierId == s.Id && h.CreatedAt >= start && h.CreatedAt < end)
                    .Select(h => new { h.CreatedAt, h.Delta })
                    .ToListAsync(ct);

                decimal rowTang = 0;
                decimal rowGiam = 0;
                decimal runningBal = dauKy;

                var bucketData = new Dictionary<string, object>();
                for (int b = 0; b < buckets.Count; b++)
                {
                    var bucket = buckets[b];
                    var inBucket = histories.Where(h => h.CreatedAt >= bucket.Start && h.CreatedAt < bucket.EndExclusive);

                    decimal bTang = inBucket.Where(h => h.Delta > 0).Sum(h => h.Delta);
                    decimal bGiam = inBucket.Where(h => h.Delta < 0).Sum(h => Math.Abs(h.Delta));

                    rowTang += bTang;
                    rowGiam += bGiam;
                    runningBal += (bTang - bGiam);

                    totalTangByBucket[b] += bTang;
                    totalGiamByBucket[b] += bGiam;

                    bucketData[$"{bucket.Header} (Tăng)"] = bTang;
                    bucketData[$"{bucket.Header} (Giảm)"] = bGiam;
                    bucketData[$"{bucket.Header} (Dư nợ)"] = runningBal;
                }

                decimal cuoiKy = dauKy + rowTang - rowGiam;

                if (!request.IncludeZeroRows && dauKy == 0 && rowTang == 0 && rowGiam == 0 && cuoiKy == 0)
                {
                    continue;
                }

                var row = new Dictionary<string, object>
                {
                    ["STT"] = stt++,
                    ["Loại"] = "Nhà cung cấp",
                    ["Mã"] = s.Code,
                    ["Tên đối tác"] = s.Name,
                    ["Đầu kỳ"] = dauKy
                };

                foreach (var kvp in bucketData) row[kvp.Key] = kvp.Value;

                row["Tổng Tăng"] = rowTang;
                row["Tổng Giảm"] = rowGiam;
                row["Cuối kỳ"] = cuoiKy;

                totalDauKy += dauKy;
                totalTang += rowTang;
                totalGiam += rowGiam;
                totalCuoiKy += cuoiKy;
                rows.Add(row);
            }
        }

        // Summary row
        var totalRow = new Dictionary<string, object>
        {
            ["STT"] = "TỔNG",
            ["Loại"] = "CỘNG",
            ["Mã"] = "",
            ["Tên đối tác"] = $"Toàn bộ ({rows.Count} đối tác)",
            ["Đầu kỳ"] = totalDauKy
        };

        for (int b = 0; b < buckets.Count; b++)
        {
            var bucket = buckets[b];
            totalRow[$"{bucket.Header} (Tăng)"] = totalTangByBucket[b];
            totalRow[$"{bucket.Header} (Giảm)"] = totalGiamByBucket[b];
            totalRow[$"{bucket.Header} (Dư nợ)"] = "";
        }

        totalRow["Tổng Tăng"] = totalTang;
        totalRow["Tổng Giảm"] = totalGiam;
        totalRow["Cuối kỳ"] = totalCuoiKy;
        rows.Add(totalRow);

        sheets["Cong_No"] = rows;
    }

    // ==========================================
    // HELPER: Generate standard matrix rows (Sales / Purchases)
    // ==========================================
    private class StandardRecord
    {
        public DateTime Date { get; set; }
        public int ProductId { get; set; }
        public string ProductSku { get; set; } = string.Empty;
        public string ProductName { get; set; } = string.Empty;
        public string Unit { get; set; } = string.Empty;
        public int PartnerId { get; set; }
        public string PartnerCode { get; set; } = string.Empty;
        public string PartnerName { get; set; } = string.Empty;
        public string Warehouse { get; set; } = string.Empty;
        public decimal Quantity { get; set; }
        public decimal Amount { get; set; }
        public decimal Price { get; set; }
    }

    private static List<Dictionary<string, object>> GenerateStandardMatrixRows(
        List<StandardRecord> records,
        List<TimeBucket> buckets,
        string groupBy,
        bool includeQuantity,
        bool includeAmount,
        bool includeAvgPrice,
        string valueHeader,
        string partnerHeader,
        bool breakdownByWarehouse = false,
        List<string>? requestedWarehouses = null)
    {
        var rows = new List<Dictionary<string, object>>();
        var gb = (groupBy ?? "product").ToLowerInvariant();

        var isWhBreakdown = breakdownByWarehouse;
        List<string> whs = new();
        if (isWhBreakdown)
        {
            if (requestedWarehouses != null && requestedWarehouses.Count > 1)
            {
                whs = requestedWarehouses.Distinct().OrderBy(w => w).ToList();
            }
            else
            {
                whs = records.Select(r => r.Warehouse).Where(w => !string.IsNullOrEmpty(w)).Distinct().OrderBy(w => w).ToList();
            }
            if (whs.Count <= 1)
            {
                isWhBreakdown = false;
            }
        }

        var bucketQtyTotals = new decimal[buckets.Count];
        var bucketAmtTotals = new decimal[buckets.Count];
        decimal grandTotalQty = 0;
        decimal grandTotalAmt = 0;

        var bucketWhQtyTotals = new Dictionary<string, decimal>[buckets.Count];
        var bucketWhAmtTotals = new Dictionary<string, decimal>[buckets.Count];
        for (int b = 0; b < buckets.Count; b++)
        {
            bucketWhQtyTotals[b] = new Dictionary<string, decimal>();
            bucketWhAmtTotals[b] = new Dictionary<string, decimal>();
            foreach (var w in whs)
            {
                bucketWhQtyTotals[b][w] = 0;
                bucketWhAmtTotals[b][w] = 0;
            }
        }

        var grandTotalWhQty = new Dictionary<string, decimal>();
        var grandTotalWhAmt = new Dictionary<string, decimal>();
        foreach (var w in whs)
        {
            grandTotalWhQty[w] = 0;
            grandTotalWhAmt[w] = 0;
        }

        int stt = 1;

        void PopulateRowBucketMetrics(
            Dictionary<string, object> row,
            IEnumerable<StandardRecord> inBucket,
            TimeBucket bucket,
            int bIdx,
            ref decimal rowQty,
            ref decimal rowAmt,
            bool isSubRow = false)
        {
            decimal bQty = inBucket.Sum(r => r.Quantity);
            decimal bAmt = inBucket.Sum(r => r.Amount);

            rowQty += bQty;
            rowAmt += bAmt;

            if (!isSubRow)
            {
                bucketQtyTotals[bIdx] += bQty;
                bucketAmtTotals[bIdx] += bAmt;
            }

            if (isWhBreakdown)
            {
                if (includeQuantity)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        var q_w = inBucket.Where(r => r.Warehouse == w).Sum(r => r.Quantity);
                        if (!isSubRow) bucketWhQtyTotals[bIdx][w] += q_w;
                        row[$"{bucket.Header} SL ({label})"] = q_w;
                    }
                    row[$"{bucket.Header} (Tổng SL)"] = bQty;
                }
                if (includeAmount)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        var a_w = inBucket.Where(r => r.Warehouse == w).Sum(r => r.Amount);
                        if (!isSubRow) bucketWhAmtTotals[bIdx][w] += a_w;
                        row[$"{bucket.Header} ({label})"] = a_w;
                    }
                    row[$"{bucket.Header} (Tổng {valueHeader})"] = bAmt;
                }
                if (includeAvgPrice)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        var q_w = inBucket.Where(r => r.Warehouse == w).Sum(r => r.Quantity);
                        var a_w = inBucket.Where(r => r.Warehouse == w).Sum(r => r.Amount);
                        row[$"{bucket.Header} Giá ({label})"] = q_w > 0 ? Math.Round(a_w / q_w, 0) : 0;
                    }
                    row[$"{bucket.Header} (Đơn giá TB)"] = bQty > 0 ? Math.Round(bAmt / bQty, 0) : 0;
                }
            }
            else
            {
                if (includeQuantity) row[$"{bucket.Header} (SL)"] = bQty;
                if (includeAmount) row[$"{bucket.Header} ({valueHeader})"] = bAmt;
                if (includeAvgPrice)
                {
                    row[$"{bucket.Header} (Đơn giá TB)"] = bQty > 0 ? Math.Round(bAmt / bQty, 0) : 0;
                }
            }
        }

        void PopulateRowFinalTotals(
            Dictionary<string, object> row,
            IEnumerable<StandardRecord> groupRecords,
            decimal rowQty,
            decimal rowAmt,
            bool isSubRow = false)
        {
            if (isWhBreakdown)
            {
                if (includeQuantity)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        var tot_q_w = groupRecords.Where(r => r.Warehouse == w).Sum(r => r.Quantity);
                        if (!isSubRow) grandTotalWhQty[w] += tot_q_w;
                        row[$"Tổng SL ({label})"] = tot_q_w;
                    }
                    row["Tổng Số Lượng"] = rowQty;
                }
                if (includeAmount)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        var tot_a_w = groupRecords.Where(r => r.Warehouse == w).Sum(r => r.Amount);
                        if (!isSubRow) grandTotalWhAmt[w] += tot_a_w;
                        row[$"Tổng {valueHeader} ({label})"] = tot_a_w;
                    }
                    row[$"Tổng {valueHeader}"] = rowAmt;
                }
                if (includeAvgPrice)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        var tot_q_w = groupRecords.Where(r => r.Warehouse == w).Sum(r => r.Quantity);
                        var tot_a_w = groupRecords.Where(r => r.Warehouse == w).Sum(r => r.Amount);
                        row[$"Đơn giá TB ({label})"] = tot_q_w > 0 ? Math.Round(tot_a_w / tot_q_w, 0) : 0;
                    }
                    row["Đơn Giá TB Toàn Kỳ"] = rowQty > 0 ? Math.Round(rowAmt / rowQty, 0) : 0;
                }
            }
            else
            {
                if (includeQuantity) row["Tổng Số Lượng"] = rowQty;
                if (includeAmount) row[$"Tổng {valueHeader}"] = rowAmt;
                if (includeAvgPrice)
                {
                    row["Đơn Giá TB Toàn Kỳ"] = rowQty > 0 ? Math.Round(rowAmt / rowQty, 0) : 0;
                }
            }
        }

        if (gb == "partner")
        {
            var partnerGroups = records.GroupBy(r => (r.PartnerId, r.PartnerCode, r.PartnerName))
                .OrderBy(g => g.Key.PartnerCode)
                .ToList();

            foreach (var g in partnerGroups)
            {
                var row = new Dictionary<string, object>
                {
                    ["STT"] = stt++,
                    ["Mã đối tác"] = g.Key.PartnerCode,
                    [partnerHeader] = g.Key.PartnerName
                };

                decimal rowQty = 0;
                decimal rowAmt = 0;

                for (int b = 0; b < buckets.Count; b++)
                {
                    var bucket = buckets[b];
                    var inBucket = g.Where(r => r.Date >= bucket.Start && r.Date < bucket.EndExclusive);
                    PopulateRowBucketMetrics(row, inBucket, bucket, b, ref rowQty, ref rowAmt);
                }

                PopulateRowFinalTotals(row, g, rowQty, rowAmt);

                grandTotalQty += rowQty;
                grandTotalAmt += rowAmt;
                rows.Add(row);
            }
        }
        else if (gb == "product_partner")
        {
            var productGroups = records.GroupBy(r => (r.ProductId, r.ProductSku, r.ProductName, r.Unit))
                .OrderBy(g => g.Key.ProductSku)
                .ToList();

            foreach (var pg in productGroups)
            {
                var pRow = new Dictionary<string, object>
                {
                    ["STT"] = stt++,
                    ["Mã SKU"] = pg.Key.ProductSku,
                    ["Tên sản phẩm"] = pg.Key.ProductName,
                    ["ĐVT"] = pg.Key.Unit,
                    [partnerHeader] = "TẤT CẢ"
                };

                decimal pQty = 0;
                decimal pAmt = 0;

                for (int b = 0; b < buckets.Count; b++)
                {
                    var bucket = buckets[b];
                    var inBucket = pg.Where(r => r.Date >= bucket.Start && r.Date < bucket.EndExclusive);
                    PopulateRowBucketMetrics(pRow, inBucket, bucket, b, ref pQty, ref pAmt);
                }

                PopulateRowFinalTotals(pRow, pg, pQty, pAmt);

                grandTotalQty += pQty;
                grandTotalAmt += pAmt;
                rows.Add(pRow);

                // Sub-rows for each partner
                var partnerSubGroups = pg.GroupBy(r => (r.PartnerId, r.PartnerCode, r.PartnerName)).OrderBy(g => g.Key.PartnerCode);
                foreach (var sg in partnerSubGroups)
                {
                    var subRow = new Dictionary<string, object>
                    {
                        ["STT"] = "",
                        ["Mã SKU"] = "",
                        ["Tên sản phẩm"] = $"↳ {pg.Key.ProductName}",
                        ["ĐVT"] = pg.Key.Unit,
                        [partnerHeader] = $"{sg.Key.PartnerName} ({sg.Key.PartnerCode})"
                    };

                    decimal sQty = 0;
                    decimal sAmt = 0;

                    for (int b = 0; b < buckets.Count; b++)
                    {
                        var bucket = buckets[b];
                        var inBucket = sg.Where(r => r.Date >= bucket.Start && r.Date < bucket.EndExclusive);
                        PopulateRowBucketMetrics(subRow, inBucket, bucket, b, ref sQty, ref sAmt, isSubRow: true);
                    }

                    PopulateRowFinalTotals(subRow, sg, sQty, sAmt, isSubRow: true);
                    rows.Add(subRow);
                }
            }
        }
        else if (gb == "partner_product")
        {
            var partnerGroups = records.GroupBy(r => (r.PartnerId, r.PartnerCode, r.PartnerName))
                .OrderBy(g => g.Key.PartnerCode)
                .ToList();

            foreach (var pg in partnerGroups)
            {
                var pRow = new Dictionary<string, object>
                {
                    ["STT"] = stt++,
                    ["Mã đối tác"] = pg.Key.PartnerCode,
                    [partnerHeader] = pg.Key.PartnerName,
                    ["Mã SKU"] = "TẤT CẢ",
                    ["Tên sản phẩm"] = "(Tất cả SP)",
                    ["ĐVT"] = ""
                };

                decimal pQty = 0;
                decimal pAmt = 0;

                for (int b = 0; b < buckets.Count; b++)
                {
                    var bucket = buckets[b];
                    var inBucket = pg.Where(r => r.Date >= bucket.Start && r.Date < bucket.EndExclusive);
                    PopulateRowBucketMetrics(pRow, inBucket, bucket, b, ref pQty, ref pAmt);
                }

                PopulateRowFinalTotals(pRow, pg, pQty, pAmt);

                grandTotalQty += pQty;
                grandTotalAmt += pAmt;
                rows.Add(pRow);

                // Sub-rows per product
                var prodSub = pg.GroupBy(r => (r.ProductId, r.ProductSku, r.ProductName, r.Unit)).OrderBy(g => g.Key.ProductSku);
                foreach (var sg in prodSub)
                {
                    var subRow = new Dictionary<string, object>
                    {
                        ["STT"] = "",
                        ["Mã đối tác"] = "",
                        [partnerHeader] = "",
                        ["Mã SKU"] = sg.Key.ProductSku,
                        ["Tên sản phẩm"] = $"↳ {sg.Key.ProductName}",
                        ["ĐVT"] = sg.Key.Unit
                    };

                    decimal sQty = 0;
                    decimal sAmt = 0;

                    for (int b = 0; b < buckets.Count; b++)
                    {
                        var bucket = buckets[b];
                        var inBucket = sg.Where(r => r.Date >= bucket.Start && r.Date < bucket.EndExclusive);
                        PopulateRowBucketMetrics(subRow, inBucket, bucket, b, ref sQty, ref sAmt, isSubRow: true);
                    }

                    PopulateRowFinalTotals(subRow, sg, sQty, sAmt, isSubRow: true);
                    rows.Add(subRow);
                }
            }
        }
        else // default: "product" or "warehouse_product"
        {
            var isWh = gb == "warehouse_product";
            var prodGroups = records.GroupBy(r => (r.ProductId, r.ProductSku, r.ProductName, r.Unit, isWh ? r.Warehouse : ""))
                .OrderBy(g => isWh ? g.Key.Item5 : "")
                .ThenBy(g => g.Key.ProductSku)
                .ToList();

            foreach (var g in prodGroups)
            {
                var row = new Dictionary<string, object>
                {
                    ["STT"] = stt++,
                    ["Mã SKU"] = g.Key.ProductSku,
                    ["Tên sản phẩm"] = g.Key.ProductName,
                    ["ĐVT"] = g.Key.Unit
                };
                if (isWh) row["Kho"] = g.Key.Item5;

                decimal rowQty = 0;
                decimal rowAmt = 0;

                for (int b = 0; b < buckets.Count; b++)
                {
                    var bucket = buckets[b];
                    var inBucket = g.Where(r => r.Date >= bucket.Start && r.Date < bucket.EndExclusive);
                    PopulateRowBucketMetrics(row, inBucket, bucket, b, ref rowQty, ref rowAmt);
                }

                PopulateRowFinalTotals(row, g, rowQty, rowAmt);

                grandTotalQty += rowQty;
                grandTotalAmt += rowAmt;
                rows.Add(row);
            }
        }

        // Grand Total row
        var totalRow = new Dictionary<string, object>
        {
            ["STT"] = "TỔNG",
            ["Mã SKU"] = "CỘNG",
            ["Tên sản phẩm"] = $"Toàn bộ ({rows.Count} dòng)",
            ["ĐVT"] = ""
        };
        if (gb == "partner")
        {
            totalRow["Mã đối tác"] = "CỘNG";
            totalRow[partnerHeader] = $"Toàn bộ ({rows.Count} dòng)";
            totalRow.Remove("Mã SKU");
            totalRow.Remove("Tên sản phẩm");
            totalRow.Remove("ĐVT");
        }
        else if (gb == "partner_product")
        {
            totalRow["Mã đối tác"] = "CỘNG";
            totalRow[partnerHeader] = $"Toàn bộ ({rows.Count} dòng)";
            totalRow["Mã SKU"] = "";
            totalRow["Tên sản phẩm"] = "";
            totalRow["ĐVT"] = "";
        }
        else if (gb == "product_partner")
        {
            totalRow[partnerHeader] = "";
        }
        else if (gb == "warehouse_product")
        {
            totalRow["Kho"] = "";
        }

        for (int b = 0; b < buckets.Count; b++)
        {
            var bucket = buckets[b];
            if (isWhBreakdown)
            {
                if (includeQuantity)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        totalRow[$"{bucket.Header} SL ({label})"] = bucketWhQtyTotals[b][w];
                    }
                    totalRow[$"{bucket.Header} (Tổng SL)"] = bucketQtyTotals[b];
                }
                if (includeAmount)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        totalRow[$"{bucket.Header} ({label})"] = bucketWhAmtTotals[b][w];
                    }
                    totalRow[$"{bucket.Header} (Tổng {valueHeader})"] = bucketAmtTotals[b];
                }
                if (includeAvgPrice)
                {
                    foreach (var w in whs)
                    {
                        var label = FormatWarehouseLabel(w);
                        var q_w = bucketWhQtyTotals[b][w];
                        var a_w = bucketWhAmtTotals[b][w];
                        totalRow[$"{bucket.Header} Giá ({label})"] = q_w > 0 ? Math.Round(a_w / q_w, 0) : 0;
                    }
                    totalRow[$"{bucket.Header} (Đơn giá TB)"] = bucketQtyTotals[b] > 0 ? Math.Round(bucketAmtTotals[b] / bucketQtyTotals[b], 0) : 0;
                }
            }
            else
            {
                if (includeQuantity) totalRow[$"{bucket.Header} (SL)"] = bucketQtyTotals[b];
                if (includeAmount) totalRow[$"{bucket.Header} ({valueHeader})"] = bucketAmtTotals[b];
                if (includeAvgPrice) totalRow[$"{bucket.Header} (Đơn giá TB)"] = bucketQtyTotals[b] > 0 ? Math.Round(bucketAmtTotals[b] / bucketQtyTotals[b], 0) : 0;
            }
        }

        if (isWhBreakdown)
        {
            if (includeQuantity)
            {
                foreach (var w in whs)
                {
                    var label = FormatWarehouseLabel(w);
                    totalRow[$"Tổng SL ({label})"] = grandTotalWhQty[w];
                }
                totalRow["Tổng Số Lượng"] = grandTotalQty;
            }
            if (includeAmount)
            {
                foreach (var w in whs)
                {
                    var label = FormatWarehouseLabel(w);
                    totalRow[$"Tổng {valueHeader} ({label})"] = grandTotalWhAmt[w];
                }
                totalRow[$"Tổng {valueHeader}"] = grandTotalAmt;
            }
            if (includeAvgPrice)
            {
                foreach (var w in whs)
                {
                    var label = FormatWarehouseLabel(w);
                    var q_w = grandTotalWhQty[w];
                    var a_w = grandTotalWhAmt[w];
                    totalRow[$"Đơn giá TB ({label})"] = q_w > 0 ? Math.Round(a_w / q_w, 0) : 0;
                }
                totalRow["Đơn Giá TB Toàn Kỳ"] = grandTotalQty > 0 ? Math.Round(grandTotalAmt / grandTotalQty, 0) : 0;
            }
        }
        else
        {
            if (includeQuantity) totalRow["Tổng Số Lượng"] = grandTotalQty;
            if (includeAmount) totalRow[$"Tổng {valueHeader}"] = grandTotalAmt;
            if (includeAvgPrice) totalRow["Đơn Giá TB Toàn Kỳ"] = grandTotalQty > 0 ? Math.Round(grandTotalAmt / grandTotalQty, 0) : 0;
        }

        rows.Add(totalRow);
        return rows;
    }

    // ==========================================
    // 6. INVENTORY REPORT (Tồn Kho Hiện Tại - Không kèm LS Nhập/Xuất)
    // ==========================================
    private static async Task BuildInventoryReportAsync(
        Dictionary<string, object> sheets,
        ExportReportRequestDto request,
        List<TimeBucket> buckets,
        DateTime start,
        DateTime end,
        IUnitOfWork uow,
        CancellationToken ct)
    {
        var prodQuery = uow.Products.Query().AsNoTracking();

        if (request.ProductIds.Count > 0)
            prodQuery = prodQuery.Where(p => request.ProductIds.Contains(p.Id));

        var products = await prodQuery
            .OrderBy(p => p.Category ?? "")
            .ThenBy(p => p.Name)
            .ToListAsync(ct);

        var gb = (request.GroupBy ?? "product").ToLowerInvariant();
        var isWhRowGroup = gb == "warehouse_product";
        var isWhBreakdown = request.BreakdownByWarehouse && !isWhRowGroup;

        List<string> whs = new();
        if (request.Warehouses != null && request.Warehouses.Count > 0)
            whs = request.Warehouses.Distinct().OrderBy(w => w).ToList();
        else
            whs = new List<string> { "warehouse1", "warehouse2", "warehouse3" };

        if (whs.Count <= 1) isWhBreakdown = false;

        bool hasQty = request.IncludeQuantity;
        bool hasPrice = request.IncludePrice || request.IncludeAvgPrice;
        bool hasAmt = request.IncludeAmount || request.IncludeRevenue;
        if (!hasQty && !hasPrice && !hasAmt) hasQty = true;

        var bName = "Tồn kho hiện tại";
        var summaryRows = new List<Dictionary<string, object>>();

        decimal grandTotalStock = 0;
        decimal grandTotalValue = 0;
        var whTotals = whs.ToDictionary(w => w, _ => 0m);
        var whValueTotals = whs.ToDictionary(w => w, _ => 0m);

        if (isWhRowGroup)
        {
            int stt = 1;
            foreach (var w in whs)
            {
                var whLabel = FormatWarehouseLabel(w);
                foreach (var p in products)
                {
                    var st = p.GetWarehouseStock(w);
                    var val = st * p.UnitCost;
                    grandTotalStock += st;
                    grandTotalValue += val;

                    string status = "Bình thường";
                    if (st <= 0)
                        status = st < 0 ? "Âm kho" : "Hết hàng";
                    else if (p.ReorderPoint > 0 && st <= p.ReorderPoint)
                        status = "Sắp hết";

                    var row = new Dictionary<string, object>
                    {
                        ["STT"] = stt++,
                        ["Kho"] = whLabel,
                        ["Mã SKU"] = p.Sku,
                        ["Tên sản phẩm"] = p.Name,
                        ["Danh mục"] = p.Category ?? "Mặc định",
                        ["ĐVT"] = p.Uom ?? ""
                    };

                    if (hasQty) row[$"{bName} (Tồn kho)"] = st;
                    if (hasPrice) row[$"{bName} (Đơn giá vốn)"] = p.UnitCost;
                    if (hasAmt) row[$"{bName} (Giá trị tồn)"] = val;
                    row[$"{bName} (Trạng thái)"] = status;

                    summaryRows.Add(row);
                }
            }
        }
        else
        {
            for (int i = 0; i < products.Count; i++)
            {
                var p = products[i];
                var row = new Dictionary<string, object>
                {
                    ["STT"] = i + 1,
                    ["Mã SKU"] = p.Sku,
                    ["Tên sản phẩm"] = p.Name,
                    ["Danh mục"] = p.Category ?? "Mặc định",
                    ["ĐVT"] = p.Uom ?? ""
                };

                decimal pStock = request.Warehouses != null && request.Warehouses.Count > 0
                    ? request.Warehouses.Sum(w => p.GetWarehouseStock(w))
                    : p.TotalStock;

                decimal pValue = pStock * p.UnitCost;
                grandTotalStock += pStock;
                grandTotalValue += pValue;

                if (isWhBreakdown)
                {
                    if (hasQty)
                    {
                        foreach (var w in whs)
                        {
                            var whLabel = FormatWarehouseLabel(w);
                            var st = p.GetWarehouseStock(w);
                            whTotals[w] += st;
                            row[$"{bName} ({whLabel})"] = st;
                        }
                        row[$"{bName} (Tổng tồn)"] = pStock;
                    }
                    if (hasPrice)
                    {
                        row[$"{bName} (Đơn giá vốn)"] = p.UnitCost;
                    }
                    if (hasAmt)
                    {
                        foreach (var w in whs)
                        {
                            var whLabel = FormatWarehouseLabel(w);
                            var st = p.GetWarehouseStock(w);
                            var valW = st * p.UnitCost;
                            whValueTotals[w] += valW;
                            row[$"{bName} Giá trị ({whLabel})"] = valW;
                        }
                        row[$"{bName} (Giá trị tồn)"] = pValue;
                    }
                }
                else
                {
                    if (hasQty) row[$"{bName} (Tồn kho)"] = pStock;
                    if (hasPrice) row[$"{bName} (Đơn giá vốn)"] = p.UnitCost;
                    if (hasAmt) row[$"{bName} (Giá trị tồn)"] = pValue;
                }

                string status = "Bình thường";
                if (pStock <= 0)
                    status = pStock < 0 ? "Âm kho" : "Hết hàng";
                else if (p.ReorderPoint > 0 && pStock <= p.ReorderPoint)
                    status = "Sắp hết";

                row[$"{bName} (Trạng thái)"] = status;
                summaryRows.Add(row);
            }
        }

        // Grand total row
        var totalRow = new Dictionary<string, object>
        {
            ["STT"] = "TỔNG CỘNG"
        };
        if (isWhRowGroup) totalRow["Kho"] = "Tất cả kho";
        totalRow["Mã SKU"] = "";
        totalRow["Tên sản phẩm"] = $"{products.Count} sản phẩm";
        totalRow["Danh mục"] = "";
        totalRow["ĐVT"] = "";

        if (isWhBreakdown && !isWhRowGroup)
        {
            if (hasQty)
            {
                foreach (var w in whs)
                {
                    var whLabel = FormatWarehouseLabel(w);
                    totalRow[$"{bName} ({whLabel})"] = whTotals[w];
                }
                totalRow[$"{bName} (Tổng tồn)"] = grandTotalStock;
            }
            if (hasPrice)
            {
                totalRow[$"{bName} (Đơn giá vốn)"] = products.Count > 0 ? Math.Round(grandTotalValue / (grandTotalStock == 0 ? 1 : grandTotalStock), 0) : 0m;
            }
            if (hasAmt)
            {
                foreach (var w in whs)
                {
                    var whLabel = FormatWarehouseLabel(w);
                    totalRow[$"{bName} Giá trị ({whLabel})"] = whValueTotals[w];
                }
                totalRow[$"{bName} (Giá trị tồn)"] = grandTotalValue;
            }
        }
        else
        {
            if (hasQty) totalRow[$"{bName} (Tồn kho)"] = grandTotalStock;
            if (hasPrice)
            {
                totalRow[$"{bName} (Đơn giá vốn)"] = products.Count > 0 ? Math.Round(grandTotalValue / (grandTotalStock == 0 ? 1 : grandTotalStock), 0) : 0m;
            }
            if (hasAmt) totalRow[$"{bName} (Giá trị tồn)"] = grandTotalValue;
        }

        totalRow[$"{bName} (Trạng thái)"] = "";

        summaryRows.Add(totalRow);
        sheets["Ton_Kho_Hien_Tai"] = summaryRows;

        if (request.IncludeDetailSheet)
        {
            var detailRows = new List<Dictionary<string, object>>();
            int dIdx = 1;
            foreach (var p in products)
            {
                foreach (var w in whs)
                {
                    var st = p.GetWarehouseStock(w);
                    string stStatus = st <= 0 ? (st < 0 ? "Âm kho" : "Hết hàng") : (p.ReorderPoint > 0 && st <= p.ReorderPoint ? "Sắp hết" : "Bình thường");
                    detailRows.Add(new Dictionary<string, object>
                    {
                        ["STT"] = dIdx++,
                        ["Kho hàng"] = FormatWarehouseLabel(w),
                        ["Mã SKU"] = p.Sku,
                        ["Tên sản phẩm"] = p.Name,
                        ["Danh mục"] = p.Category ?? "Mặc định",
                        ["ĐVT"] = p.Uom ?? "",
                        ["Số lượng tồn"] = st,
                        ["Định mức tối thiểu"] = p.ReorderPoint,
                        ["Đơn giá vốn"] = p.UnitCost,
                        ["Giá trị tồn"] = st * p.UnitCost,
                        ["Trạng thái"] = stStatus
                    });
                }
            }
            sheets["Chi_Tiet"] = detailRows;
        }
    }
}
