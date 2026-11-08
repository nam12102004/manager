namespace DebtManager.Domain.Entities;

public class ExportVoucher
{
    public long Id { get; set; }
    public string VoucherNumber { get; set; } = string.Empty;
    public DateTime Date { get; set; } = DateTime.UtcNow;
    public string Warehouse { get; set; } = "warehouse1";

    public string PartnerType { get; set; } = "customer"; // "customer" | "supplier"
    public int? CustomerId { get; set; }
    public Customer? Customer { get; set; }
    public int? SupplierId { get; set; }
    public Supplier? Supplier { get; set; }

    public int? EmployeeId { get; set; }
    public Employee? Employee { get; set; }
    public string? EmployeeName { get; set; }

    public decimal SubtotalSale { get; set; } = 0;
    public decimal DiscountAmount { get; set; } = 0;
    public decimal TotalSale { get; set; } = 0;
    public decimal PaidAmount { get; set; } = 0;
    public decimal UnpaidAmount { get; set; } = 0;
    public decimal TotalCost { get; set; } = 0;

    public string Status { get; set; } = "active"; // "active" | "cancelled"
    public DateTime? CancelledAt { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<ExportVoucherItem> Items { get; set; } = new List<ExportVoucherItem>();
}
