using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Entities;
using DebtManager.Infrastructure.Data;
using Microsoft.EntityFrameworkCore.Storage;

namespace DebtManager.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly DebtManagerDbContext _context;
    private IDbContextTransaction? _transaction;
    private readonly Dictionary<Type, object> _repositories = new();

    public UnitOfWork(DebtManagerDbContext context)
    {
        _context = context;
        Users = new Repository<User>(_context);
        Customers = new Repository<Customer>(_context);
        Suppliers = new Repository<Supplier>(_context);
        Products = new Repository<Product>(_context);
        StockHistories = new Repository<StockHistory>(_context);
        CustomerDebtHistories = new Repository<CustomerDebtHistory>(_context);
        SupplierDebtHistories = new Repository<SupplierDebtHistory>(_context);
        ExportVouchers = new Repository<ExportVoucher>(_context);
        ExportVoucherItems = new Repository<ExportVoucherItem>(_context);
        ImportVouchers = new Repository<ImportVoucher>(_context);
        ImportVoucherItems = new Repository<ImportVoucherItem>(_context);
        Receipts = new Repository<Receipt>(_context);
        Payments = new Repository<Payment>(_context);
        Owners = new Repository<Owner>(_context);
    }

    public IRepository<User> Users { get; }
    public IRepository<Customer> Customers { get; }
    public IRepository<Supplier> Suppliers { get; }
    public IRepository<Product> Products { get; }
    public IRepository<StockHistory> StockHistories { get; }
    public IRepository<CustomerDebtHistory> CustomerDebtHistories { get; }
    public IRepository<SupplierDebtHistory> SupplierDebtHistories { get; }
    public IRepository<ExportVoucher> ExportVouchers { get; }
    public IRepository<ExportVoucherItem> ExportVoucherItems { get; }
    public IRepository<ImportVoucher> ImportVouchers { get; }
    public IRepository<ImportVoucherItem> ImportVoucherItems { get; }
    public IRepository<Receipt> Receipts { get; }
    public IRepository<Payment> Payments { get; }
    public IRepository<Owner> Owners { get; }

    public IRepository<T> Repository<T>() where T : class
    {
        var type = typeof(T);
        if (!_repositories.TryGetValue(type, out var repo))
        {
            repo = new Repository<T>(_context);
            _repositories[type] = repo;
        }
        return (IRepository<T>)repo;
    }

    public async Task<int> SaveChangesAsync(CancellationToken ct = default)
    {
        return await _context.SaveChangesAsync(ct);
    }

    public async Task BeginTransactionAsync(CancellationToken ct = default)
    {
        _transaction = await _context.Database.BeginTransactionAsync(ct);
    }

    public async Task CommitAsync(CancellationToken ct = default)
    {
        if (_transaction != null)
        {
            await _transaction.CommitAsync(ct);
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public async Task RollbackAsync(CancellationToken ct = default)
    {
        if (_transaction != null)
        {
            await _transaction.RollbackAsync(ct);
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public void Dispose()
    {
        _transaction?.Dispose();
        _context.Dispose();
    }

    public async ValueTask DisposeAsync()
    {
        if (_transaction != null)
        {
            await _transaction.DisposeAsync();
        }
        await _context.DisposeAsync();
    }
}
