namespace DebtManager.Domain.Entities;

public class SupplierDebtHistory
{
    public long Id { get; set; }
    public int SupplierId { get; set; }
    public Supplier Supplier { get; set; } = null!;

    public string SourceType { get; set; } = string.Empty;
    public string? ReferenceType { get; set; }
    public string? ReferenceId { get; set; }
    public string? Reason { get; set; }
    public string? Note { get; set; }

    public decimal BeforeDebt { get; set; }
    public decimal Delta { get; set; }
    public decimal AfterDebt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
