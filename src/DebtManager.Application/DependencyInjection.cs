using DebtManager.Application.Interfaces;
using DebtManager.Application.Services;
using Microsoft.Extensions.DependencyInjection;

namespace DebtManager.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<ICustomerService, CustomerService>();
        services.AddScoped<ISupplierService, SupplierService>();
        services.AddScoped<IExportService, ExportService>();
        services.AddScoped<IImportService, ImportService>();
        services.AddScoped<IReceiptService, ReceiptService>();
        services.AddScoped<IPaymentService, PaymentService>();
        services.AddScoped<IReportService, ReportService>();
        services.AddScoped<IOwnerService, OwnerService>();

        return services;
    }
}
