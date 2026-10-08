namespace DebtManager.Domain.Entities;

public class Payment
{
    public long Id { get; set; }
    public string PaymentNumber { get; set; } = string.Empty;
    public DateTime Date { get; set; } = DateTime.UtcNow;

    public int? SupplierId { get; set; }
    public Supplier? Supplier { get; set; }

    public int? CustomerId { get; set; }
    public Customer? Customer { get; set; }

    public decimal Amount { get; set; } = 0;
    public string? Method { get; set; }
    public string Status { get; set; } = "confirmed"; // "confirmed" | "cancelled"
    public DateTime? CancelledAt { get; set; }
    public string? RelatedVoucherType { get; set; }
    public string? RelatedVoucherId { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
