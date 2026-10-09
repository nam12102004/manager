namespace DebtManager.Domain.Entities;

public class Supplier
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? ContactName { get; set; }
    public string? PhonesJson { get; set; }
    public string? Email { get; set; }
    public string? AddressesJson { get; set; }
    public string? Region { get; set; }
    public decimal Debt { get; set; } = 0;
    public decimal CreditLimit { get; set; } = 0;
    public string? BankAccount { get; set; }
    public string? TaxNumber { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<SupplierDebtHistory> DebtHistories { get; set; } = new List<SupplierDebtHistory>();
    public ICollection<ImportVoucher> ImportVouchers { get; set; } = new List<ImportVoucher>();
    public ICollection<Product> Products { get; set; } = new List<Product>();
    public ICollection<Receipt> Receipts { get; set; } = new List<Receipt>();
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
}
