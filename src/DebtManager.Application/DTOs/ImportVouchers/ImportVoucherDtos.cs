namespace DebtManager.Application.DTOs.ImportVouchers;

public class CreateImportItemDto
{
    public int ProductId { get; set; }
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

public class CreateImportDto
{
    public int SupplierId { get; set; }
    public string Warehouse { get; set; } = "warehouse1";
    public DateTime? Date { get; set; }
    public decimal DiscountAmount { get; set; } = 0;
    public decimal PaidAmount { get; set; } = 0;
    public string? Notes { get; set; }
    public List<CreateImportItemDto> Items { get; set; } = new();
}

public class ImportVoucherItemDto
{
    public long Id { get; set; }
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal LineTotal { get; set; }
}

public class ImportVoucherDto
{
    public long Id { get; set; }
    public string VoucherNumber { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public string Warehouse { get; set; } = string.Empty;
    public int SupplierId { get; set; }
    public string SupplierName { get; set; } = string.Empty;
    public decimal SubtotalAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal PaidAmount { get; set; }
    public decimal UnpaidAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime? CancelledAt { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<ImportVoucherItemDto> Items { get; set; } = new();
}
