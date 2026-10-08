namespace DebtManager.Application.DTOs.ExportVouchers;

public class CreateExportItemDto
{
    public int ProductId { get; set; }
    public decimal Quantity { get; set; }
    public decimal? SalePrice { get; set; }
}

public class CreateExportDto
{
    public int CustomerId { get; set; }
    public string Warehouse { get; set; } = "warehouse1";
    public DateTime? Date { get; set; }
    public decimal? DiscountPercent { get; set; }
    public decimal? DiscountValue { get; set; }
    public decimal PaidAmount { get; set; } = 0;
    public string? Notes { get; set; }
    public List<CreateExportItemDto> Items { get; set; } = new();
}

public class ExportVoucherItemDto
{
    public long Id { get; set; }
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public decimal Quantity { get; set; }
    public decimal UnitCost { get; set; }
    public decimal SalePrice { get; set; }
    public decimal LineTotal { get; set; }
}

public class ExportVoucherDto
{
    public long Id { get; set; }
    public string VoucherNumber { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public string Warehouse { get; set; } = string.Empty;
    public int CustomerId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public decimal SubtotalSale { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TotalSale { get; set; }
    public decimal PaidAmount { get; set; }
    public decimal UnpaidAmount { get; set; }
    public decimal TotalCost { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime? CancelledAt { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<ExportVoucherItemDto> Items { get; set; } = new();
}

public class UpdateVoucherStatusDto
{
    public string Action { get; set; } = "cancel"; // "cancel" | "restore"
}
