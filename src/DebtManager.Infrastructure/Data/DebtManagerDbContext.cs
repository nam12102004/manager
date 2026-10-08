using DebtManager.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace DebtManager.Infrastructure.Data;

public class DebtManagerDbContext : DbContext
{
    public DebtManagerDbContext(DbContextOptions<DebtManagerDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Supplier> Suppliers => Set<Supplier>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<StockHistory> StockHistories => Set<StockHistory>();
    public DbSet<CustomerDebtHistory> CustomerDebtHistories => Set<CustomerDebtHistory>();
    public DbSet<SupplierDebtHistory> SupplierDebtHistories => Set<SupplierDebtHistory>();
    public DbSet<ExportVoucher> ExportVouchers => Set<ExportVoucher>();
    public DbSet<ExportVoucherItem> ExportVoucherItems => Set<ExportVoucherItem>();
    public DbSet<ImportVoucher> ImportVouchers => Set<ImportVoucher>();
    public DbSet<ImportVoucherItem> ImportVoucherItems => Set<ImportVoucherItem>();
    public DbSet<Receipt> Receipts => Set<Receipt>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Owner> Owners => Set<Owner>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // 1. Users
        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("Users");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Username).HasMaxLength(50).IsRequired();
            entity.HasIndex(e => e.Username).IsUnique();
            entity.Property(e => e.PasswordHash).HasMaxLength(255).IsRequired();
            entity.Property(e => e.Role).HasMaxLength(30).HasDefaultValue("user");
        });

        // 2. Customers
        modelBuilder.Entity<Customer>(entity =>
        {
            entity.ToTable("Customers");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Code).HasMaxLength(30).IsRequired();
            entity.HasIndex(e => e.Code).IsUnique();
            entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
            entity.Property(e => e.ContactName).HasMaxLength(100);
            entity.Property(e => e.Email).HasMaxLength(100);
            entity.Property(e => e.Debt).HasPrecision(18, 2).HasDefaultValue(0);
            entity.Property(e => e.CreditLimit).HasPrecision(18, 2).HasDefaultValue(0);
            entity.Property(e => e.Notes).HasMaxLength(1000);
        });

        // 3. Suppliers
        modelBuilder.Entity<Supplier>(entity =>
        {
            entity.ToTable("Suppliers");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Code).HasMaxLength(30).IsRequired();
            entity.HasIndex(e => e.Code).IsUnique();
            entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
            entity.Property(e => e.ContactName).HasMaxLength(100);
            entity.Property(e => e.Email).HasMaxLength(100);
            entity.Property(e => e.Debt).HasPrecision(18, 2).HasDefaultValue(0);
            entity.Property(e => e.CreditLimit).HasPrecision(18, 2).HasDefaultValue(0);
            entity.Property(e => e.BankAccount).HasMaxLength(100);
            entity.Property(e => e.TaxNumber).HasMaxLength(50);
            entity.Property(e => e.Notes).HasMaxLength(1000);
        });

        // 4. Products
        modelBuilder.Entity<Product>(entity =>
        {
            entity.ToTable("Products");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Sku).HasMaxLength(50).IsRequired();
            entity.HasIndex(e => e.Sku).IsUnique();
            entity.Property(e => e.Name).HasMaxLength(255).IsRequired();
            entity.Property(e => e.Category).HasMaxLength(100);
            entity.Property(e => e.Uom).HasMaxLength(50);
            entity.Property(e => e.Barcode).HasMaxLength(100);

            entity.Property(e => e.UnitCost).HasPrecision(18, 2).HasDefaultValue(0);
            entity.Property(e => e.WholesalePrice).HasPrecision(18, 2).HasDefaultValue(0);
            entity.Property(e => e.RetailPrice).HasPrecision(18, 2).HasDefaultValue(0);

            entity.Property(e => e.StockWarehouse1).HasPrecision(18, 3).HasDefaultValue(0);
            entity.Property(e => e.StockWarehouse2).HasPrecision(18, 3).HasDefaultValue(0);
            entity.Property(e => e.StockWarehouse3).HasPrecision(18, 3).HasDefaultValue(0);
            entity.Property(e => e.TotalStock).HasPrecision(18, 3).HasDefaultValue(0);
            entity.Property(e => e.ReorderPoint).HasPrecision(18, 3).HasDefaultValue(0);

            entity.HasOne(e => e.Supplier)
                .WithMany(s => s.Products)
                .HasForeignKey(e => e.SupplierId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // 5. StockHistories
        modelBuilder.Entity<StockHistory>(entity =>
        {
            entity.ToTable("StockHistories");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Warehouse).HasMaxLength(20).IsRequired();
            entity.Property(e => e.SourceType).HasMaxLength(50).IsRequired();
            entity.Property(e => e.ReferenceType).HasMaxLength(50);
            entity.Property(e => e.ReferenceId).HasMaxLength(100);
            entity.Property(e => e.Reason).HasMaxLength(255);
            entity.Property(e => e.Note).HasMaxLength(500);

            entity.Property(e => e.BeforeWarehouseStock).HasPrecision(18, 3);
            entity.Property(e => e.Delta).HasPrecision(18, 3);
            entity.Property(e => e.AfterWarehouseStock).HasPrecision(18, 3);
            entity.Property(e => e.BeforeTotalStock).HasPrecision(18, 3);
            entity.Property(e => e.AfterTotalStock).HasPrecision(18, 3);

            entity.HasIndex(e => new { e.ProductId, e.ChangeDate });
            entity.HasIndex(e => e.Warehouse);

            entity.HasOne(e => e.Product)
                .WithMany(p => p.StockHistories)
                .HasForeignKey(e => e.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // 6. CustomerDebtHistories
        modelBuilder.Entity<CustomerDebtHistory>(entity =>
        {
            entity.ToTable("CustomerDebtHistories");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.SourceType).HasMaxLength(50).IsRequired();
            entity.Property(e => e.ReferenceType).HasMaxLength(50);
            entity.Property(e => e.ReferenceId).HasMaxLength(100);
            entity.Property(e => e.Reason).HasMaxLength(255);
            entity.Property(e => e.Note).HasMaxLength(500);

            entity.Property(e => e.BeforeDebt).HasPrecision(18, 2);
            entity.Property(e => e.Delta).HasPrecision(18, 2);
            entity.Property(e => e.AfterDebt).HasPrecision(18, 2);

            entity.HasIndex(e => new { e.CustomerId, e.CreatedAt });

            entity.HasOne(e => e.Customer)
                .WithMany(c => c.DebtHistories)
                .HasForeignKey(e => e.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // 7. SupplierDebtHistories
        modelBuilder.Entity<SupplierDebtHistory>(entity =>
        {
            entity.ToTable("SupplierDebtHistories");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.SourceType).HasMaxLength(50).IsRequired();
            entity.Property(e => e.ReferenceType).HasMaxLength(50);
            entity.Property(e => e.ReferenceId).HasMaxLength(100);
            entity.Property(e => e.Reason).HasMaxLength(255);
            entity.Property(e => e.Note).HasMaxLength(500);

            entity.Property(e => e.BeforeDebt).HasPrecision(18, 2);
            entity.Property(e => e.Delta).HasPrecision(18, 2);
            entity.Property(e => e.AfterDebt).HasPrecision(18, 2);

            entity.HasIndex(e => new { e.SupplierId, e.CreatedAt });

            entity.HasOne(e => e.Supplier)
                .WithMany(s => s.DebtHistories)
                .HasForeignKey(e => e.SupplierId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // 8. ExportVouchers & Items
        modelBuilder.Entity<ExportVoucher>(entity =>
        {
            entity.ToTable("ExportVouchers");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.VoucherNumber).HasMaxLength(50).IsRequired();
            entity.HasIndex(e => e.VoucherNumber).IsUnique();
            entity.Property(e => e.Warehouse).HasMaxLength(20).IsRequired();
            entity.Property(e => e.Status).HasMaxLength(20).HasDefaultValue("active");
            entity.Property(e => e.Notes).HasMaxLength(1000);

            entity.Property(e => e.SubtotalSale).HasPrecision(18, 2);
            entity.Property(e => e.DiscountAmount).HasPrecision(18, 2);
            entity.Property(e => e.TotalSale).HasPrecision(18, 2);
            entity.Property(e => e.PaidAmount).HasPrecision(18, 2);
            entity.Property(e => e.UnpaidAmount).HasPrecision(18, 2);
            entity.Property(e => e.TotalCost).HasPrecision(18, 2);

            entity.HasIndex(e => new { e.CustomerId, e.Date });

            entity.HasOne(e => e.Customer)
                .WithMany(c => c.ExportVouchers)
                .HasForeignKey(e => e.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<ExportVoucherItem>(entity =>
        {
            entity.ToTable("ExportVoucherItems");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Quantity).HasPrecision(18, 3);
            entity.Property(e => e.UnitCost).HasPrecision(18, 2);
            entity.Property(e => e.SalePrice).HasPrecision(18, 2);
            entity.Property(e => e.LineTotal).HasPrecision(18, 2);

            entity.HasOne(e => e.ExportVoucher)
                .WithMany(v => v.Items)
                .HasForeignKey(e => e.ExportVoucherId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Product)
                .WithMany(p => p.ExportVoucherItems)
                .HasForeignKey(e => e.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // 9. ImportVouchers & Items
        modelBuilder.Entity<ImportVoucher>(entity =>
        {
            entity.ToTable("ImportVouchers");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.VoucherNumber).HasMaxLength(50).IsRequired();
            entity.HasIndex(e => e.VoucherNumber).IsUnique();
            entity.Property(e => e.Warehouse).HasMaxLength(20).IsRequired();
            entity.Property(e => e.Status).HasMaxLength(20).HasDefaultValue("confirmed");
            entity.Property(e => e.Notes).HasMaxLength(1000);

            entity.Property(e => e.SubtotalAmount).HasPrecision(18, 2);
            entity.Property(e => e.DiscountAmount).HasPrecision(18, 2);
            entity.Property(e => e.TotalAmount).HasPrecision(18, 2);
            entity.Property(e => e.PaidAmount).HasPrecision(18, 2);
            entity.Property(e => e.UnpaidAmount).HasPrecision(18, 2);

            entity.HasIndex(e => new { e.SupplierId, e.Date });

            entity.HasOne(e => e.Supplier)
                .WithMany(s => s.ImportVouchers)
                .HasForeignKey(e => e.SupplierId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<ImportVoucherItem>(entity =>
        {
            entity.ToTable("ImportVoucherItems");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.ProductName).HasMaxLength(255).IsRequired();
            entity.Property(e => e.Sku).HasMaxLength(50).IsRequired();
            entity.Property(e => e.Quantity).HasPrecision(18, 3);
            entity.Property(e => e.UnitPrice).HasPrecision(18, 2);
            entity.Property(e => e.LineTotal).HasPrecision(18, 2);

            entity.HasOne(e => e.ImportVoucher)
                .WithMany(v => v.Items)
                .HasForeignKey(e => e.ImportVoucherId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Product)
                .WithMany(p => p.ImportVoucherItems)
                .HasForeignKey(e => e.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // 10. Receipts & Payments
        modelBuilder.Entity<Receipt>(entity =>
        {
            entity.ToTable("Receipts");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.ReceiptNumber).HasMaxLength(50).IsRequired();
            entity.HasIndex(e => e.ReceiptNumber).IsUnique();
            entity.Property(e => e.Amount).HasPrecision(18, 2);
            entity.Property(e => e.Method).HasMaxLength(50);
            entity.Property(e => e.RelatedVoucherType).HasMaxLength(50);
            entity.Property(e => e.RelatedVoucherId).HasMaxLength(100);
            entity.Property(e => e.Notes).HasMaxLength(500);

            entity.HasOne(e => e.Customer)
                .WithMany(c => c.Receipts)
                .HasForeignKey(e => e.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Supplier)
                .WithMany(s => s.Receipts)
                .HasForeignKey(e => e.SupplierId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.ToTable("Payments");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.PaymentNumber).HasMaxLength(50).IsRequired();
            entity.HasIndex(e => e.PaymentNumber).IsUnique();
            entity.Property(e => e.Amount).HasPrecision(18, 2);
            entity.Property(e => e.Method).HasMaxLength(50);
            entity.Property(e => e.Status).HasMaxLength(20).HasDefaultValue("confirmed");
            entity.Property(e => e.RelatedVoucherType).HasMaxLength(50);
            entity.Property(e => e.RelatedVoucherId).HasMaxLength(100);
            entity.Property(e => e.Notes).HasMaxLength(500);

            entity.HasOne(e => e.Supplier)
                .WithMany(s => s.Payments)
                .HasForeignKey(e => e.SupplierId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Customer)
                .WithMany(c => c.Payments)
                .HasForeignKey(e => e.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // 11. Owners
        modelBuilder.Entity<Owner>(entity =>
        {
            entity.ToTable("Owners");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Info).HasMaxLength(500).IsRequired();
        });
    }
}
