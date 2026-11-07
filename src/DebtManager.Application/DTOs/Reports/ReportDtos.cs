namespace DebtManager.Application.DTOs.Reports;

public class StockReportWarehouseDetailDto
{
    public decimal OpeningStock { get; set; }
    public decimal ImportStock { get; set; }
    public decimal ExportStock { get; set; }
    public decimal ClosingStock { get; set; }
}

public class StockReportItemDto
{
    public int ProductId { get; set; }
    public string Sku { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Category { get; set; }
    public string? Uom { get; set; }
    public decimal UnitCost { get; set; }
    public decimal WholesalePrice { get; set; }
    public decimal RetailPrice { get; set; }

    public decimal OpeningStock { get; set; }
    public decimal OpeningValue { get; set; }
    public decimal ImportQty { get; set; }
    public decimal ImportStock { get; set; }
    public decimal ImportValue { get; set; }
    public decimal ExportQty { get; set; }
    public decimal ExportStock { get; set; }
    public decimal ExportValue { get; set; }
    public decimal ClosingStock { get; set; }
    public decimal ClosingValue { get; set; }

    public StockReportWarehouseDetailDto Warehouse1 { get; set; } = new();
    public StockReportWarehouseDetailDto Warehouse2 { get; set; } = new();
    public StockReportWarehouseDetailDto Warehouse3 { get; set; } = new();

    public decimal TotalCostValue => ClosingStock * UnitCost;
    public decimal TotalWholesaleValue => ClosingStock * WholesalePrice;
    public decimal TotalRetailValue => ClosingStock * RetailPrice;
}

public class StockReportResponseDto
{
    public string Month { get; set; } = string.Empty;
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public List<StockReportItemDto> Items { get; set; } = new();
    public decimal TotalCostValue { get; set; }
    public decimal TotalWholesaleValue { get; set; }
    public decimal TotalRetailValue { get; set; }
    public decimal TotalOpeningValue { get; set; }
    public decimal TotalImportValue { get; set; }
    public decimal TotalExportValue { get; set; }
    public decimal TotalClosingValue { get; set; }
}

public class DebtReportItemDto
{
    public int PartnerId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string PartnerType { get; set; } = string.Empty; // "customer" | "supplier"
    public decimal OpeningDebt { get; set; }
    public decimal IncreaseDebt { get; set; }
    public decimal DecreaseDebt { get; set; }
    public decimal ClosingDebt { get; set; }
    public decimal Receivable => ClosingDebt > 0 ? ClosingDebt : 0;
    public decimal Payable => ClosingDebt < 0 ? -ClosingDebt : 0;

    public decimal DebtWarehouse1 { get; set; }
    public decimal DebtWarehouse2 { get; set; }
    public decimal DebtWarehouse3 { get; set; }
}

public class DebtReportResponseDto
{
    public string Month { get; set; } = string.Empty;
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public string? SelectedWarehouse { get; set; }
    public List<DebtReportItemDto> Items { get; set; } = new();
    public decimal TotalOpeningReceivable { get; set; }
    public decimal TotalOpeningPayable { get; set; }
    public decimal TotalClosingReceivable { get; set; }
    public decimal TotalClosingPayable { get; set; }
}
