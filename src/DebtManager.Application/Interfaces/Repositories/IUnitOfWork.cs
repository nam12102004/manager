using DebtManager.Domain.Entities;

namespace DebtManager.Application.Interfaces.Repositories;

public interface IUnitOfWork : IDisposable, IAsyncDisposable
{
    IRepository<User> Users { get; }
    IRepository<Customer> Customers { get; }
    IRepository<Supplier> Suppliers { get; }
    IRepository<Product> Products { get; }
    IRepository<StockHistory> StockHistories { get; }
    IRepository<CustomerDebtHistory> CustomerDebtHistories { get; }
    IRepository<SupplierDebtHistory> SupplierDebtHistories { get; }
    IRepository<ExportVoucher> ExportVouchers { get; }
    IRepository<ExportVoucherItem> ExportVoucherItems { get; }
    IRepository<ImportVoucher> ImportVouchers { get; }
    IRepository<ImportVoucherItem> ImportVoucherItems { get; }
    IRepository<Receipt> Receipts { get; }
    IRepository<Payment> Payments { get; }
    IRepository<Owner> Owners { get; }
    IRepository<AuditLog> AuditLogs { get; }
    IRepository<LoginHistory> LoginHistories { get; }

    IRepository<T> Repository<T>() where T : class;

    Task<int> SaveChangesAsync(CancellationToken ct = default);
    Task BeginTransactionAsync(CancellationToken ct = default);
    Task CommitAsync(CancellationToken ct = default);
    Task RollbackAsync(CancellationToken ct = default);
}
