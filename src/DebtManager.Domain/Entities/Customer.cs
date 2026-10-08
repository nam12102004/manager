namespace DebtManager.Domain.Entities;

public class Customer
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? ContactName { get; set; }
    public string? PhonesJson { get; set; }
    public string? Email { get; set; }
    public string? AddressesJson { get; set; }
    public decimal Debt { get; set; } = 0;
    public decimal CreditLimit { get; set; } = 0;
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<CustomerDebtHistory> DebtHistories { get; set; } = new List<CustomerDebtHistory>();
    public ICollection<ExportVoucher> ExportVouchers { get; set; } = new List<ExportVoucher>();
    public ICollection<Receipt> Receipts { get; set; } = new List<Receipt>();
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
}
