namespace DebtManager.Domain.Entities;

public class CustomerWarehouseDebt
{
    public long Id { get; set; }
    public int CustomerId { get; set; }
    public Customer Customer { get; set; } = null!;
    public string Warehouse { get; set; } = "warehouse1";
    public decimal Debt { get; set; } = 0;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
