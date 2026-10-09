namespace DebtManager.Application.DTOs.Products;

public class ProductDto
{
    public int Id { get; set; }
    public string Sku { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Category { get; set; }
    public string? Uom { get; set; }
    public string? Barcode { get; set; }
    public int? SupplierId { get; set; }
    public string? SupplierName { get; set; }
    public decimal UnitCost { get; set; }
    public decimal WholesalePrice { get; set; }
    public decimal RetailPrice { get; set; }
    public decimal StockWarehouse1 { get; set; }
    public decimal StockWarehouse2 { get; set; }
    public decimal StockWarehouse3 { get; set; }
    public Dictionary<string, decimal> WarehouseStocks { get; set; } = new();
    public decimal TotalStock { get; set; }
    public decimal ReorderPoint { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateProductDto
{
    public string? Sku { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Category { get; set; }
    public string? Uom { get; set; }
    public string? Barcode { get; set; }
    public int? SupplierId { get; set; }
    public decimal UnitCost { get; set; } = 0;
    public decimal WholesalePrice { get; set; } = 0;
    public decimal RetailPrice { get; set; } = 0;
    public decimal StockWarehouse1 { get; set; } = 0;
    public decimal StockWarehouse2 { get; set; } = 0;
    public decimal StockWarehouse3 { get; set; } = 0;
    public Dictionary<string, decimal>? WarehouseStocks { get; set; }
    public decimal ReorderPoint { get; set; } = 0;
}

public class UpdateProductDto
{
    public string Name { get; set; } = string.Empty;
    public string? Category { get; set; }
    public string? Uom { get; set; }
    public string? Barcode { get; set; }
    public int? SupplierId { get; set; }
    public decimal UnitCost { get; set; }
    public decimal WholesalePrice { get; set; }
    public decimal RetailPrice { get; set; }
    public decimal ReorderPoint { get; set; }
}

public class StockAdjustDto
{
    public string Warehouse { get; set; } = "warehouse1";
    public decimal? Delta { get; set; }
    public decimal? Quantity { get; set; }
    public string? Reason { get; set; }
    public string? Note { get; set; }
    public DateTime? ChangeDate { get; set; }
}

public class StockHistoryDto
{
    public long Id { get; set; }
    public int ProductId { get; set; }
    public string Warehouse { get; set; } = string.Empty;
    public string SourceType { get; set; } = string.Empty;
    public string? ReferenceType { get; set; }
    public string? ReferenceId { get; set; }
    public string? Reason { get; set; }
    public string? Note { get; set; }
    public decimal BeforeWarehouseStock { get; set; }
    public decimal Delta { get; set; }
    public decimal AfterWarehouseStock { get; set; }
    public decimal BeforeTotalStock { get; set; }
    public decimal AfterTotalStock { get; set; }
    public DateTime ChangeDate { get; set; }
    public DateTime CreatedAt { get; set; }
}
