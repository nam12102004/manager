namespace DebtManager.Application.DTOs.Exports;

public class PeriodDto
{
    public string Mode { get; set; } = "month"; // day | dayRange | month | monthRange | year | all
    public string? Date { get; set; } // yyyy-MM-dd
    public string? Day { get => Date; set => Date = value; }
    public string? FromDate { get; set; } // yyyy-MM-dd
    public string? ToDate { get; set; } // yyyy-MM-dd
    public string? Month { get; set; } // yyyy-MM
    public string? FromMonth { get; set; } // yyyy-MM
    public string? ToMonth { get; set; } // yyyy-MM
    public int? Year { get; set; } // yyyy
}

public class ExportReportRequestDto
{
    public string ReportType { get; set; } = "sales"; // sales | purchases | inout | cashflow | debt
    public PeriodDto Period { get; set; } = new();
    public string Granularity { get; set; } = "day"; // day | week | month
    public string GroupBy { get; set; } = "product"; // product | product_partner | partner | partner_product | warehouse_product
    public string PartnerScope { get; set; } = "customer"; // customer | supplier | both (for cashflow & debt)
    public string? PartnerType { get => PartnerScope; set => PartnerScope = value ?? "customer"; }

    // Debt calculation mode: "from_beginning" (default - công nợ từ đầu) | "in_period" (công nợ phát sinh trong khoảng thời gian lọc)
    public string DebtMode { get; set; } = "from_beginning";

    private List<int>? _productIds;
    public List<int> ProductIds { get => _productIds ??= new(); set => _productIds = value ?? new(); }

    private List<int>? _customerIds;
    public List<int> CustomerIds { get => _customerIds ??= new(); set => _customerIds = value ?? new(); }

    private List<int>? _supplierIds;
    public List<int> SupplierIds { get => _supplierIds ??= new(); set => _supplierIds = value ?? new(); }

    private List<string>? _warehouses;
    public List<string> Warehouses { get => _warehouses ??= new(); set => _warehouses = value ?? new(); }

    private List<int>? _employeeIds;
    public List<int> EmployeeIds { get => _employeeIds ??= new(); set => _employeeIds = value ?? new(); }

    // Metric options
    public bool IncludeQuantity { get; set; } = true;
    public bool IncludeAmount { get; set; } = true;
    public bool IncludeRevenue { get => IncludeAmount; set => IncludeAmount = value; }
    public bool IncludeAvgPrice { get; set; } = false;
    public bool IncludePrice { get => IncludeAvgPrice; set => IncludeAvgPrice = value; }

    // Advanced options
    public bool IncludeDetailSheet { get; set; } = false;
    public bool IncludeZeroRows { get; set; } = false;
    public string SplitSheets { get; set; } = "none"; // none | month | year
    public bool BreakdownByWarehouse { get; set; } = false;
}

public class DailyMatrixExportRequestDto
{
    public int? CustomerId { get; set; }
    public int? SupplierId { get; set; }
    public string PartnerType { get; set; } = "customer"; // "customer" | "supplier"
    public string? Warehouse { get; set; }
    public int? ProductId { get; set; }
    public string TimeScope { get; set; } = "month"; // "month" | "all" | "custom"
    public string? Month { get; set; } // "yyyy-MM"
    public string? FromDate { get; set; } // "yyyy-MM-dd"
    public string? ToDate { get; set; } // "yyyy-MM-dd"

    // Tùy chọn cột
    public bool IncludeQuantity { get; set; } = true;
    public bool IncludeRevenue { get; set; } = true;
    public bool IncludePrice { get; set; } = false;
    public bool SeparateSheets { get; set; } = false;
}

public class FullDbExportRequestDto
{
    public List<string>? Tables { get; set; }
    public string TimeScope { get; set; } = "all"; // "all" | "month" | "custom"
    public string? Month { get; set; }
    public string? FromDate { get; set; }
    public string? ToDate { get; set; }
}

public class ExportJobStatusDto
{
    public string JobId { get; set; } = string.Empty;
    public string Status { get; set; } = "queued"; // "queued" | "processing" | "completed" | "failed"
    public int ProgressPercentage { get; set; } = 0;
    public string Message { get; set; } = string.Empty;
    public string? FileName { get; set; }
    public long FileSize { get; set; } = 0;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }
    public string? Error { get; set; }
}

public class BucketMetricDto
{
    public string Key { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string Suffix { get; set; } = string.Empty;
}

public class ExcelPreviewResultDto
{
    public string PeriodLabel { get; set; } = string.Empty;
    public string ReportTitle { get; set; } = string.Empty;
    public string Sheet1Title { get; set; } = "Sheet 1: Tổng hợp";
    public string Sheet2Title { get; set; } = "Sheet 2: Dữ liệu chi tiết";
    public List<string> Buckets { get; set; } = new();
    public List<string> FixedColumns { get; set; } = new();
    public List<BucketMetricDto> BucketMetrics { get; set; } = new();
    public List<string> TotalColumns { get; set; } = new();
    public List<string> SummaryColumns { get; set; } = new();
    public List<Dictionary<string, object?>> SummaryRows { get; set; } = new();
    public int TotalSummaryRows { get; set; }
    public List<string> DetailColumns { get; set; } = new();
    public List<Dictionary<string, object?>> DetailRows { get; set; } = new();
    public int TotalDetailRows { get; set; }
    public bool HasData { get; set; }
    public bool BreakdownByWarehouse { get; set; } = false;
    public List<string> Warehouses { get; set; } = new();
}

