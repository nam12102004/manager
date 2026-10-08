namespace DebtManager.Domain.Entities;

public class ImportVoucher
{
    public long Id { get; set; }
    public string VoucherNumber { get; set; } = string.Empty;
    public DateTime Date { get; set; } = DateTime.UtcNow;
    public string Warehouse { get; set; } = "warehouse1";

    public int SupplierId { get; set; }
    public Supplier Supplier { get; set; } = null!;

    public decimal SubtotalAmount { get; set; } = 0;
    public decimal DiscountAmount { get; set; } = 0;
    public decimal TotalAmount { get; set; } = 0;
    public decimal PaidAmount { get; set; } = 0;
    public decimal UnpaidAmount { get; set; } = 0;

    public string Status { get; set; } = "confirmed"; // "confirmed" | "cancelled"
    public DateTime? CancelledAt { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<ImportVoucherItem> Items { get; set; } = new List<ImportVoucherItem>();
}
