using DebtManager.Application.DTOs.Customers;
using DebtManager.Application.DTOs.ExportVouchers;
using DebtManager.Application.DTOs.ImportVouchers;
using DebtManager.Application.DTOs.Payments;
using DebtManager.Application.DTOs.Products;
using DebtManager.Application.DTOs.Receipts;
using DebtManager.Application.DTOs.Suppliers;

namespace DebtManager.Application.Common;

public class CustomerPagedResult : PagedResult<CustomerDto>
{
    public decimal TotalReceivables { get; set; }
    public decimal TotalPayables { get; set; }
}

public class SupplierPagedResult : PagedResult<SupplierDto>
{
    public decimal TotalReceivables { get; set; }
    public decimal TotalPayables { get; set; }
}

public class ProductPagedResult : PagedResult<ProductDto>
{
    public decimal TotalStockQty { get; set; }
    public decimal TotalCostVal { get; set; }
    public decimal TotalWholesaleVal { get; set; }
    public decimal TotalRetailVal { get; set; }
}

public class ImportPagedResult : PagedResult<ImportVoucherDto>
{
    public decimal TotalAmount { get; set; }
    public decimal TotalPaid { get; set; }
    public decimal TotalDebt { get; set; }
}

public class ExportPagedResult : PagedResult<ExportVoucherDto>
{
    public decimal TotalSale { get; set; }
    public decimal TotalPaid { get; set; }
    public decimal TotalDebt { get; set; }
    public decimal TotalProfit { get; set; }
}

public class ReceiptPagedResult : PagedResult<ReceiptDto>
{
    public decimal TotalAmount { get; set; }
}

public class PaymentPagedResult : PagedResult<PaymentDto>
{
    public decimal TotalAmount { get; set; }
}
