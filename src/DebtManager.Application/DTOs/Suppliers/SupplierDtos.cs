namespace DebtManager.Application.DTOs.Suppliers;

public class SupplierDto
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? ContactName { get; set; }
    public string? PhonesJson { get; set; }
    public string? Email { get; set; }
    public string? AddressesJson { get; set; }
    public decimal Debt { get; set; }
    public decimal CreditLimit { get; set; }
    public string? BankAccount { get; set; }
    public string? TaxNumber { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateSupplierDto
{
    public string? Code { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? ContactName { get; set; }
    public string? PhonesJson { get; set; }
    public string? Email { get; set; }
    public string? AddressesJson { get; set; }
    public decimal CreditLimit { get; set; } = 0;
    public decimal InitialDebt { get; set; } = 0;
    public string? BankAccount { get; set; }
    public string? TaxNumber { get; set; }
    public string? Notes { get; set; }
}

public class UpdateSupplierDto
{
    public string Name { get; set; } = string.Empty;
    public string? ContactName { get; set; }
    public string? PhonesJson { get; set; }
    public string? Email { get; set; }
    public string? AddressesJson { get; set; }
    public decimal CreditLimit { get; set; }
    public string? BankAccount { get; set; }
    public string? TaxNumber { get; set; }
    public string? Notes { get; set; }
}

public class SupplierDebtAdjustDto
{
    public decimal? Delta { get; set; }
    public decimal? NewDebt { get; set; }
    public string? Reason { get; set; }
    public string? Note { get; set; }
}

public class SupplierDebtHistoryDto
{
    public long Id { get; set; }
    public int SupplierId { get; set; }
    public string SourceType { get; set; } = string.Empty;
    public string? ReferenceType { get; set; }
    public string? ReferenceId { get; set; }
    public string? Reason { get; set; }
    public string? Note { get; set; }
    public decimal BeforeDebt { get; set; }
    public decimal Delta { get; set; }
    public decimal AfterDebt { get; set; }
    public DateTime CreatedAt { get; set; }
}
