namespace DebtManager.Application.DTOs.Reports;

public class WarehouseProductSalesDto
{
    public int ProductId { get; set; }
    public string Sku { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Category { get; set; }
    public string? Uom { get; set; }
    public decimal UnitCost { get; set; }
    public decimal WholesalePrice { get; set; }
    public decimal RetailPrice { get; set; }
    public decimal ImportQty { get; set; }
    public decimal ImportAmount { get; set; }
    public decimal ExportQty { get; set; }
    public decimal ExportAmount { get; set; }
    public decimal CurrentStock { get; set; }
}

public class WarehouseCustomerSalesDto
{
    public int CustomerId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Region { get; set; }
    public string? Phone { get; set; }
    public int ExportCount { get; set; }
    public decimal ExportQty { get; set; }
    public decimal ExportAmount { get; set; }
    public decimal ImportQty { get; set; }
    public decimal ImportAmount { get; set; }
}

public class WarehouseSupplierSalesDto
{
    public int SupplierId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Region { get; set; }
    public string? Phone { get; set; }
    public int ImportCount { get; set; }
    public decimal ImportQty { get; set; }
    public decimal ImportAmount { get; set; }
    public decimal ExportQty { get; set; }
    public decimal ExportAmount { get; set; }
}

public class WarehouseSalesResponseDto
{
    public string Warehouse { get; set; } = string.Empty;
    public string Period { get; set; } = string.Empty;
    public decimal TotalImportAmount { get; set; }
    public decimal TotalExportAmount { get; set; }
    public decimal TotalImportQty { get; set; }
    public decimal TotalExportQty { get; set; }
    public List<WarehouseProductSalesDto> ProductSales { get; set; } = new();
    public List<WarehouseCustomerSalesDto> CustomerSales { get; set; } = new();
    public List<WarehouseSupplierSalesDto> SupplierSales { get; set; } = new();
}
