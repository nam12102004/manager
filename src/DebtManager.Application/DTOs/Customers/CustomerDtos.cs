namespace DebtManager.Application.DTOs.Customers;

public class CustomerDto
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
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateCustomerDto
{
    public string? Code { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? ContactName { get; set; }
    public string? PhonesJson { get; set; }
    public string? Email { get; set; }
    public string? AddressesJson { get; set; }
    public decimal CreditLimit { get; set; } = 0;
    public decimal InitialDebt { get; set; } = 0;
    public string? Notes { get; set; }
}

public class UpdateCustomerDto
{
    public string Name { get; set; } = string.Empty;
    public string? ContactName { get; set; }
    public string? PhonesJson { get; set; }
    public string? Email { get; set; }
    public string? AddressesJson { get; set; }
    public decimal CreditLimit { get; set; }
    public string? Notes { get; set; }
}

public class CustomerDebtAdjustDto
{
    public decimal? Delta { get; set; }
    public decimal? NewDebt { get; set; }
    public string? Reason { get; set; }
    public string? Note { get; set; }
}

public class CustomerDebtHistoryDto
{
    public long Id { get; set; }
    public int CustomerId { get; set; }
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
