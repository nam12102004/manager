namespace DebtManager.Application.DTOs.Receipts;

public class CreateReceiptDto
{
    public DateTime? Date { get; set; }
    public int? CustomerId { get; set; }
    public int? SupplierId { get; set; }
    public decimal Amount { get; set; }
    public string? Method { get; set; }
    public string? RelatedVoucherType { get; set; }
    public string? RelatedVoucherId { get; set; }
    public string? Notes { get; set; }
}

public class ReceiptDto
{
    public long Id { get; set; }
    public string ReceiptNumber { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public int? CustomerId { get; set; }
    public string? CustomerName { get; set; }
    public int? SupplierId { get; set; }
    public string? SupplierName { get; set; }
    public decimal Amount { get; set; }
    public string? Method { get; set; }
    public string? RelatedVoucherType { get; set; }
    public string? RelatedVoucherId { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
}
