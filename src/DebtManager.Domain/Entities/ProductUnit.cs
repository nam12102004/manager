namespace DebtManager.Domain.Entities;

public class ProductUnit
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public string UnitName { get; set; } = string.Empty;
    public decimal ConversionRate { get; set; } = 1;
    public bool IsBaseUnit { get; set; } = false;
    public string? Barcode { get; set; }
    public decimal RetailPrice { get; set; } = 0;
    public decimal WholesalePrice { get; set; } = 0;
    public bool CanSell { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
