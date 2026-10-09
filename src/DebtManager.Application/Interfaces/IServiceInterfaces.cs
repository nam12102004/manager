using DebtManager.Application.Common;
using DebtManager.Application.DTOs.Audit;
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
using DebtManager.Application.DTOs.Users;

namespace DebtManager.Application.Interfaces;

public interface IAuthService
{
    Task<LoginResponseDto> LoginAsync(LoginRequestDto request, CancellationToken ct = default);
}

public interface IProductService
{
    Task<List<ProductDto>> GetProductsAsync(string? search = null, int? supplierId = null, CancellationToken ct = default);
    Task<ProductPagedResult> GetPagedProductsAsync(string? search = null, int? supplierId = null, string? warehouse = null, string? sortBy = null, int page = 1, int pageSize = 15, CancellationToken ct = default);
    Task<ProductDto> GetByIdAsync(int id, CancellationToken ct = default);
    Task<ProductDto> CreateProductAsync(CreateProductDto dto, CancellationToken ct = default);
    Task<ProductDto> UpdateProductAsync(int id, UpdateProductDto dto, CancellationToken ct = default);
    Task<bool> AdjustStockAsync(int id, StockAdjustDto dto, CancellationToken ct = default);
    Task<List<StockHistoryDto>> GetStockHistoryAsync(int productId, string? month = null, CancellationToken ct = default);
}

public interface ICustomerService
{
    Task<List<CustomerDto>> GetCustomersAsync(string? search = null, CancellationToken ct = default);
    Task<CustomerPagedResult> GetPagedCustomersAsync(string? search = null, string? region = null, string? sortBy = null, int page = 1, int pageSize = 15, CancellationToken ct = default);
    Task<List<string>> GetRegionsAsync(CancellationToken ct = default);
    Task<CustomerDto> GetByIdAsync(int id, CancellationToken ct = default);
    Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto dto, CancellationToken ct = default);
    Task<CustomerDto> UpdateCustomerAsync(int id, UpdateCustomerDto dto, CancellationToken ct = default);
    Task<List<CustomerDebtHistoryDto>> GetDebtHistoryAsync(int customerId, string? month = null, CancellationToken ct = default);
    Task<bool> AdjustDebtAsync(int customerId, CustomerDebtAdjustDto dto, CancellationToken ct = default);
}

public interface ISupplierService
{
    Task<List<SupplierDto>> GetSuppliersAsync(string? search = null, CancellationToken ct = default);
    Task<SupplierPagedResult> GetPagedSuppliersAsync(string? search = null, string? region = null, string? sortBy = null, int page = 1, int pageSize = 15, CancellationToken ct = default);
    Task<List<string>> GetRegionsAsync(CancellationToken ct = default);
    Task<SupplierDto> GetByIdAsync(int id, CancellationToken ct = default);
    Task<SupplierDto> CreateSupplierAsync(CreateSupplierDto dto, CancellationToken ct = default);
    Task<SupplierDto> UpdateSupplierAsync(int id, UpdateSupplierDto dto, CancellationToken ct = default);
    Task<List<SupplierDebtHistoryDto>> GetDebtHistoryAsync(int supplierId, string? month = null, CancellationToken ct = default);
    Task<bool> AdjustDebtAsync(int supplierId, SupplierDebtAdjustDto dto, CancellationToken ct = default);
}

public interface IExportService
{
    Task<List<ExportVoucherDto>> GetExportsAsync(int? customerId = null, string? month = null, string? fromDate = null, string? toDate = null, CancellationToken ct = default);
    Task<ExportPagedResult> GetPagedExportsAsync(int? customerId = null, string? month = null, string? date = null, string? fromDate = null, string? toDate = null, string? search = null, int page = 1, int pageSize = 15, CancellationToken ct = default);
    Task<ExportVoucherDto> GetByIdAsync(long id, CancellationToken ct = default);
    Task<ExportVoucherDto> CreateExportAsync(CreateExportDto dto, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(long id, string action, CancellationToken ct = default);
    Task<bool> DeleteExportAsync(long id, CancellationToken ct = default);
}

public interface IImportService
{
    Task<List<ImportVoucherDto>> GetImportsAsync(int? supplierId = null, string? month = null, string? fromDate = null, string? toDate = null, CancellationToken ct = default);
    Task<ImportPagedResult> GetPagedImportsAsync(int? supplierId = null, string? month = null, string? date = null, string? fromDate = null, string? toDate = null, string? search = null, int page = 1, int pageSize = 15, CancellationToken ct = default);
    Task<ImportVoucherDto> GetByIdAsync(long id, CancellationToken ct = default);
    Task<ImportVoucherDto> CreateImportAsync(CreateImportDto dto, CancellationToken ct = default);
    Task<bool> UpdateStatusAsync(long id, string action, CancellationToken ct = default);
    Task<bool> DeleteImportAsync(long id, CancellationToken ct = default);
}

public interface IReceiptService
{
    Task<List<ReceiptDto>> GetReceiptsAsync(int? customerId = null, int? supplierId = null, string? search = null, CancellationToken ct = default);
    Task<ReceiptPagedResult> GetPagedReceiptsAsync(int? customerId = null, int? supplierId = null, string? search = null, string? month = null, string? date = null, string? fromDate = null, string? toDate = null, int page = 1, int pageSize = 15, CancellationToken ct = default);
    Task<ReceiptDto> GetByIdAsync(long id, CancellationToken ct = default);
    Task<ReceiptDto> CreateReceiptAsync(CreateReceiptDto dto, CancellationToken ct = default);
    Task<bool> DeleteReceiptAsync(long id, CancellationToken ct = default);
}

public interface IPaymentService
{
    Task<List<PaymentDto>> GetPaymentsAsync(int? supplierId = null, int? customerId = null, string? search = null, CancellationToken ct = default);
    Task<PaymentPagedResult> GetPagedPaymentsAsync(int? supplierId = null, int? customerId = null, string? search = null, string? month = null, string? date = null, string? fromDate = null, string? toDate = null, int page = 1, int pageSize = 15, CancellationToken ct = default);
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

public interface IAuditService
{
    Task<AuditLogDto> LogActivityAsync(string action, string entityName, string entityId, string entityDisplayName, string? details, string username = "admin", string? ipAddress = null, CancellationToken ct = default);
    Task<List<AuditLogDto>> GetAuditLogsAsync(string? entityName = null, string? action = null, string? username = null, string? q = null, DateTime? fromDate = null, DateTime? toDate = null, int limit = 100, CancellationToken ct = default);
    Task<PagedResult<AuditLogDto>> GetPagedAuditLogsAsync(string? entityName = null, string? action = null, string? username = null, string? q = null, DateTime? fromDate = null, DateTime? toDate = null, int page = 1, int pageSize = 15, CancellationToken ct = default);
    Task<LoginHistoryDto> LogLoginAsync(string username, bool isSuccess, string? ipAddress = null, string? userAgent = null, string? device = null, string? note = null, CancellationToken ct = default);
    Task<List<LoginHistoryDto>> GetLoginHistoriesAsync(string? username = null, bool? isSuccess = null, int limit = 100, CancellationToken ct = default);
    Task<PagedResult<LoginHistoryDto>> GetPagedLoginHistoriesAsync(string? username = null, bool? isSuccess = null, string? q = null, int page = 1, int pageSize = 15, CancellationToken ct = default);
}

public interface IUserService
{
    Task<List<UserDto>> GetUsersAsync(CancellationToken ct = default);
    Task<PagedResult<UserDto>> GetPagedUsersAsync(string? search = null, int page = 1, int pageSize = 15, CancellationToken ct = default);
    Task<UserDto> GetByIdAsync(int id, CancellationToken ct = default);
    Task<UserDto> CreateUserAsync(CreateUserDto dto, CancellationToken ct = default);
    Task<bool> ChangePasswordAsync(int id, ChangePasswordDto dto, CancellationToken ct = default);
    Task<bool> UpdateRoleAsync(int id, UpdateUserRoleDto dto, CancellationToken ct = default);
    Task<bool> DeleteUserAsync(int id, CancellationToken ct = default);
}
