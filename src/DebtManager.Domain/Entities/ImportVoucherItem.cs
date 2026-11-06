namespace DebtManager.Domain.Entities;

public class ImportVoucherItem
{
    public long Id { get; set; }
    public long ImportVoucherId { get; set; }
    public ImportVoucher ImportVoucher { get; set; } = null!;

    public int ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public string ProductName { get; set; } = string.Empty;
    public string Sku { get; set; } = string.Empty;
    public decimal Quantity { get; set; } = 0;
    public string? UnitName { get; set; }
    public decimal ConversionRate { get; set; } = 1;
    public decimal BaseQuantity { get; set; } = 0;
    public decimal UnitPrice { get; set; } = 0;
    public decimal LineTotal { get; set; } = 0;
}
