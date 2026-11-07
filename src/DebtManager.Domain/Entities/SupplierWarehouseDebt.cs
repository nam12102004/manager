namespace DebtManager.Domain.Entities;

public class SupplierWarehouseDebt
{
    public long Id { get; set; }
    public int SupplierId { get; set; }
    public Supplier Supplier { get; set; } = null!;
    public string Warehouse { get; set; } = "warehouse1";
    public decimal Debt { get; set; } = 0;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
