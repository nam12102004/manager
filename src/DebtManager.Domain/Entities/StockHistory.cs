namespace DebtManager.Domain.Entities;

public class StockHistory
{
    public long Id { get; set; }
    public int ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public string Warehouse { get; set; } = "warehouse1";
    public string SourceType { get; set; } = "manual_adjustment";
    public string? ReferenceType { get; set; }
    public string? ReferenceId { get; set; }
    public string? Reason { get; set; }
    public string? Note { get; set; }

    public decimal BeforeWarehouseStock { get; set; }
    public decimal Delta { get; set; }
    public decimal AfterWarehouseStock { get; set; }
    public decimal BeforeTotalStock { get; set; }
    public decimal AfterTotalStock { get; set; }

    public DateTime ChangeDate { get; set; } = DateTime.UtcNow;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
