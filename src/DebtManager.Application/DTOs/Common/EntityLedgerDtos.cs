namespace DebtManager.Application.DTOs.Common;

public class EntityLedgerItemDto
{
    public long Id { get; set; }
    public DateTime Date { get; set; }
    public string VoucherNumber { get; set; } = string.Empty;
    public string VoucherType { get; set; } = string.Empty; // "export" | "import" | "receipt" | "payment" | "adjust"
    public string VoucherTypeLabel { get; set; } = string.Empty; // "Phiếu xuất" | "Phiếu nhập" | "Phiếu thu" | "Phiếu chi" | "Điều chỉnh"
    public string? Warehouse { get; set; }
    public string? Description { get; set; }

    // 4 Distinct Columns
    public decimal ImportAmount { get; set; } // Cột NHẬP
    public decimal ExportAmount { get; set; } // Cột XUẤT
    public decimal ReceiptAmount { get; set; } // Cột THU
    public decimal PaymentAmount { get; set; } // Cột CHI

    // Additional quantities for products
    public decimal ImportQty { get; set; }
    public decimal ExportQty { get; set; }

    // Balance after transaction (dư nợ hoặc tồn kho)
    public decimal Balance { get; set; }
}

public class EntityLedgerResponseDto
{
    public int EntityId { get; set; }
    public string EntityCode { get; set; } = string.Empty;
    public string EntityName { get; set; } = string.Empty;
    public string? Warehouse { get; set; }
    public decimal TotalImport { get; set; }
    public decimal TotalExport { get; set; }
    public decimal TotalReceipt { get; set; }
    public decimal TotalPayment { get; set; }
    public decimal TotalImportQty { get; set; }
    public decimal TotalExportQty { get; set; }
    public decimal CurrentBalance { get; set; }
    public List<EntityLedgerItemDto> Items { get; set; } = new();
}
