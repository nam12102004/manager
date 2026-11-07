using DebtManager.Application.Common.Exceptions;
using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Application.Common;

public static class DebtHelper
{
    public static string NormalizeWarehouse(string? warehouse)
    {
        if (string.IsNullOrWhiteSpace(warehouse) || warehouse.Equals("all", StringComparison.OrdinalIgnoreCase) || warehouse.Equals("overview", StringComparison.OrdinalIgnoreCase))
        {
            return "warehouse1";
        }
        return warehouse.Trim();
    }

    public static async Task<(decimal BeforeTotalDebt, decimal AfterTotalDebt, decimal BeforeWhDebt, decimal AfterWhDebt)>
        ApplyCustomerDebtAsync(IUnitOfWork uow, int customerId, string? warehouse, decimal delta, CancellationToken ct = default)
    {
        var customer = await uow.Customers.Query().FirstOrDefaultAsync(c => c.Id == customerId, ct)
            ?? throw new NotFoundException($"Không tìm thấy khách hàng ID {customerId}");

        var wh = NormalizeWarehouse(warehouse);
        var whDebt = await uow.CustomerWarehouseDebts.Query()
            .FirstOrDefaultAsync(w => w.CustomerId == customerId && w.Warehouse == wh, ct);

        decimal beforeWh = 0;
        if (whDebt == null)
        {
            whDebt = new CustomerWarehouseDebt
            {
                CustomerId = customerId,
                Warehouse = wh,
                Debt = delta,
                UpdatedAt = DateTime.UtcNow
            };
            await uow.CustomerWarehouseDebts.AddAsync(whDebt, ct);
        }
        else
        {
            beforeWh = whDebt.Debt;
            whDebt.Debt += delta;
            whDebt.UpdatedAt = DateTime.UtcNow;
            uow.CustomerWarehouseDebts.Update(whDebt);
        }

        decimal beforeTotal = customer.Debt;
        customer.Debt += delta;
        customer.UpdatedAt = DateTime.UtcNow;
        uow.Customers.Update(customer);

        return (beforeTotal, customer.Debt, beforeWh, whDebt.Debt);
    }

    public static async Task<(decimal Delta, decimal BeforeTotalDebt, decimal AfterTotalDebt, decimal BeforeWhDebt, decimal AfterWhDebt)>
        SetCustomerDebtAsync(IUnitOfWork uow, int customerId, string? warehouse, decimal targetWarehouseDebt, CancellationToken ct = default)
    {
        var customer = await uow.Customers.Query().FirstOrDefaultAsync(c => c.Id == customerId, ct)
            ?? throw new NotFoundException($"Không tìm thấy khách hàng ID {customerId}");

        var wh = NormalizeWarehouse(warehouse);
        var whDebt = await uow.CustomerWarehouseDebts.Query()
            .FirstOrDefaultAsync(w => w.CustomerId == customerId && w.Warehouse == wh, ct);

        decimal beforeWh = 0;
        decimal delta;

        if (whDebt == null)
        {
            delta = targetWarehouseDebt;
            whDebt = new CustomerWarehouseDebt
            {
                CustomerId = customerId,
                Warehouse = wh,
                Debt = targetWarehouseDebt,
                UpdatedAt = DateTime.UtcNow
            };
            await uow.CustomerWarehouseDebts.AddAsync(whDebt, ct);
        }
        else
        {
            beforeWh = whDebt.Debt;
            delta = targetWarehouseDebt - beforeWh;
            whDebt.Debt = targetWarehouseDebt;
            whDebt.UpdatedAt = DateTime.UtcNow;
            uow.CustomerWarehouseDebts.Update(whDebt);
        }

        decimal beforeTotal = customer.Debt;
        customer.Debt += delta;
        customer.UpdatedAt = DateTime.UtcNow;
        uow.Customers.Update(customer);

        return (delta, beforeTotal, customer.Debt, beforeWh, whDebt.Debt);
    }

    public static async Task<(decimal BeforeTotalDebt, decimal AfterTotalDebt, decimal BeforeWhDebt, decimal AfterWhDebt)>
        ApplySupplierDebtAsync(IUnitOfWork uow, int supplierId, string? warehouse, decimal delta, CancellationToken ct = default)
    {
        var supplier = await uow.Suppliers.Query().FirstOrDefaultAsync(s => s.Id == supplierId, ct)
            ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp ID {supplierId}");

        var wh = NormalizeWarehouse(warehouse);
        var whDebt = await uow.SupplierWarehouseDebts.Query()
            .FirstOrDefaultAsync(w => w.SupplierId == supplierId && w.Warehouse == wh, ct);

        decimal beforeWh = 0;
        if (whDebt == null)
        {
            whDebt = new SupplierWarehouseDebt
            {
                SupplierId = supplierId,
                Warehouse = wh,
                Debt = delta,
                UpdatedAt = DateTime.UtcNow
            };
            await uow.SupplierWarehouseDebts.AddAsync(whDebt, ct);
        }
        else
        {
            beforeWh = whDebt.Debt;
            whDebt.Debt += delta;
            whDebt.UpdatedAt = DateTime.UtcNow;
            uow.SupplierWarehouseDebts.Update(whDebt);
        }

        decimal beforeTotal = supplier.Debt;
        supplier.Debt += delta;
        supplier.UpdatedAt = DateTime.UtcNow;
        uow.Suppliers.Update(supplier);

        return (beforeTotal, supplier.Debt, beforeWh, whDebt.Debt);
    }

    public static async Task<(decimal Delta, decimal BeforeTotalDebt, decimal AfterTotalDebt, decimal BeforeWhDebt, decimal AfterWhDebt)>
        SetSupplierDebtAsync(IUnitOfWork uow, int supplierId, string? warehouse, decimal targetWarehouseDebt, CancellationToken ct = default)
    {
        var supplier = await uow.Suppliers.Query().FirstOrDefaultAsync(s => s.Id == supplierId, ct)
            ?? throw new NotFoundException($"Không tìm thấy nhà cung cấp ID {supplierId}");

        var wh = NormalizeWarehouse(warehouse);
        var whDebt = await uow.SupplierWarehouseDebts.Query()
            .FirstOrDefaultAsync(w => w.SupplierId == supplierId && w.Warehouse == wh, ct);

        decimal beforeWh = 0;
        decimal delta;

        if (whDebt == null)
        {
            delta = targetWarehouseDebt;
            whDebt = new SupplierWarehouseDebt
            {
                SupplierId = supplierId,
                Warehouse = wh,
                Debt = targetWarehouseDebt,
                UpdatedAt = DateTime.UtcNow
            };
            await uow.SupplierWarehouseDebts.AddAsync(whDebt, ct);
        }
        else
        {
            beforeWh = whDebt.Debt;
            delta = targetWarehouseDebt - beforeWh;
            whDebt.Debt = targetWarehouseDebt;
            whDebt.UpdatedAt = DateTime.UtcNow;
            uow.SupplierWarehouseDebts.Update(whDebt);
        }

        decimal beforeTotal = supplier.Debt;
        supplier.Debt += delta;
        supplier.UpdatedAt = DateTime.UtcNow;
        uow.Suppliers.Update(supplier);

        return (delta, beforeTotal, supplier.Debt, beforeWh, whDebt.Debt);
    }
}
