namespace DebtManager.Domain.Entities;

public class Product
{
    public int Id { get; set; }
    public string Sku { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Category { get; set; }
    public string? Uom { get; set; }
    public string? Barcode { get; set; }
    public int? SupplierId { get; set; }
    public Supplier? Supplier { get; set; }

    public decimal UnitCost { get; set; } = 0;
    public decimal WholesalePrice { get; set; } = 0;
    public decimal RetailPrice { get; set; } = 0;

    public decimal StockWarehouse1 { get; set; } = 0;
    public decimal StockWarehouse2 { get; set; } = 0;
    public decimal StockWarehouse3 { get; set; } = 0;
    public decimal TotalStock { get; set; } = 0;
    public decimal ReorderPoint { get; set; } = 0;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<StockHistory> StockHistories { get; set; } = new List<StockHistory>();
    public ICollection<ExportVoucherItem> ExportVoucherItems { get; set; } = new List<ExportVoucherItem>();
    public ICollection<ImportVoucherItem> ImportVoucherItems { get; set; } = new List<ImportVoucherItem>();
}
