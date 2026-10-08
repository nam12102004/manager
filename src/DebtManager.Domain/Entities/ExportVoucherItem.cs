namespace DebtManager.Domain.Entities;

public class ExportVoucherItem
{
    public long Id { get; set; }
    public long ExportVoucherId { get; set; }
    public ExportVoucher ExportVoucher { get; set; } = null!;

    public int ProductId { get; set; }
    public Product Product { get; set; } = null!;

    public decimal Quantity { get; set; } = 0;
    public decimal UnitCost { get; set; } = 0;
    public decimal SalePrice { get; set; } = 0;
    public decimal LineTotal { get; set; } = 0;
}
