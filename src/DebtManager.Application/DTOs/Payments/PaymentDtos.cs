namespace DebtManager.Application.DTOs.Payments;

public class CreatePaymentDto
{
    public DateTime? Date { get; set; }
    public int? SupplierId { get; set; }
    public int? CustomerId { get; set; }
    public decimal Amount { get; set; }
    public string? Method { get; set; }
    public string? RelatedVoucherType { get; set; }
    public string? RelatedVoucherId { get; set; }
    public string? Notes { get; set; }
}

public class PaymentDto
{
    public long Id { get; set; }
    public string PaymentNumber { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public int? SupplierId { get; set; }
    public string? SupplierName { get; set; }
    public int? CustomerId { get; set; }
    public string? CustomerName { get; set; }
    public decimal Amount { get; set; }
    public string? Method { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime? CancelledAt { get; set; }
    public string? RelatedVoucherType { get; set; }
    public string? RelatedVoucherId { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
}
