using DebtManager.Application.DTOs.Auth;
using DebtManager.Application.DTOs.Customers;
using DebtManager.Application.DTOs.ExportVouchers;
using DebtManager.Application.DTOs.ImportVouchers;
using DebtManager.Application.DTOs.Owners;
using DebtManager.Application.DTOs.Payments;
using DebtManager.Application.DTOs.Products;
using DebtManager.Application.DTOs.Receipts;
using DebtManager.Application.DTOs.Reports;
using DebtManager.Application.DTOs.Suppliers;

namespace DebtManager.Application.Interfaces;

public interface IAuthService
{
    Task<LoginResponseDto> LoginAsync(LoginRequestDto request, CancellationToken ct = default);
}

public interface IProductService
{
    Task<List<ProductDto>> GetProductsAsync(string? search = null, int? supplierId = null, CancellationToken ct = default);
    Task<ProductDto> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ProductDto> CreateProductAsync(CreateProductDto dto, CancellationToken ct = default);
    Task<ProductDto> UpdateProductAsync(int id, UpdateProductDto dto, CancellationToken ct = default);
    Task<bool> AdjustStockAsync(int id, StockAdjustDto dto, CancellationToken ct = default);
    Task<List<StockHistoryDto>> GetStockHistoryAsync(int productId, string? month = null, CancellationToken ct = default);
}

public interface ICustomerService
{
    Task<List<CustomerDto>> GetCustomersAsync(string? search = null, CancellationToken ct = default);
    Task<CustomerDto> GetByIdAsync(int id, CancellationToken ct = default);
    Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto dto, CancellationToken ct = default);
    Task<CustomerDto> UpdateCustomerAsync(int id, UpdateCustomerDto dto, CancellationToken ct = default);
    Task<List<CustomerDebtHistoryDto>> GetDebtHistoryAsync(int customerId, CancellationToken ct = default);
    Task<bool> AdjustDebtAsync(int customerId, CustomerDebtAdjustDto dto, CancellationToken ct = default);
}

public interface ISupplierService
{
    Task<List<SupplierDto>> GetSuppliersAsync(string? search = null, CancellationToken ct = default);
    Task<SupplierDto> GetByIdAsync(int id, CancellationToken ct = default);
    Task<SupplierDto> CreateSupplierAsync(CreateSupplierDto dto, CancellationToken ct = default);
    Task<SupplierDto> UpdateSupplierAsync(int id, UpdateSupplierDto dto, CancellationToken ct = default);
    Task<List<SupplierDebtHistoryDto>> GetDebtHistoryAsync(int supplierId, CancellationToken ct = default);
    Task<bool> AdjustDebtAsync(int supplierId, SupplierDebtAdjustDto dto, CancellationToken ct = default);
}

public interface IExportService
{
    Task<List<ExportVoucherDto>> GetExportsAsync(int? customerId = null, string? month = null, CancellationToken ct = default);
    Task<ExportVoucherDto> GetByIdAsync(long id, CancellationToken ct = default);
    Task<ExportVoucherDto> CreateExportAsync(CreateExportDto dto, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(long id, string action, CancellationToken ct = default);
    Task<bool> DeleteExportAsync(long id, CancellationToken ct = default);
}

public interface IImportService
{
    Task<List<ImportVoucherDto>> GetImportsAsync(int? supplierId = null, string? month = null, CancellationToken ct = default);
    Task<ImportVoucherDto> GetByIdAsync(long id, CancellationToken ct = default);
    Task<ImportVoucherDto> CreateImportAsync(CreateImportDto dto, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(long id, string action, CancellationToken ct = default);
    Task<bool> DeleteImportAsync(long id, CancellationToken ct = default);
}

public interface IReceiptService
{
    Task<List<ReceiptDto>> GetReceiptsAsync(int? customerId = null, int? supplierId = null, string? search = null, CancellationToken ct = default);
    Task<ReceiptDto> GetByIdAsync(long id, CancellationToken ct = default);
    Task<ReceiptDto> CreateReceiptAsync(CreateReceiptDto dto, CancellationToken ct = default);
    Task<bool> DeleteReceiptAsync(long id, CancellationToken ct = default);
}

public interface IPaymentService
{
    Task<List<PaymentDto>> GetPaymentsAsync(int? supplierId = null, int? customerId = null, string? search = null, CancellationToken ct = default);
    Task<PaymentDto> GetByIdAsync(long id, CancellationToken ct = default);
    Task<PaymentDto> CreatePaymentAsync(CreatePaymentDto dto, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(long id, string action, CancellationToken ct = default);
    Task<bool> DeletePaymentAsync(long id, CancellationToken ct = default);
}

public interface IReportService
{
    Task<StockReportResponseDto> GetStockReportAsync(string? month = null, CancellationToken ct = default);
    Task<DebtReportResponseDto> GetDebtReportAsync(string? month = null, CancellationToken ct = default);
}

public interface IOwnerService
{
    Task<OwnerDto> GetOwnerInfoAsync(CancellationToken ct = default);
    Task<OwnerDto> UpdateOwnerInfoAsync(UpdateOwnerDto dto, CancellationToken ct = default);
}
