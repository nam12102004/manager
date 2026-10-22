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
        services.AddScoped<IEmployeeService, EmployeeService>();
        services.AddScoped<IExportService, ExportService>();
        services.AddScoped<IImportService, ImportService>();
        services.AddScoped<IReceiptService, ReceiptService>();
        services.AddScoped<IPaymentService, PaymentService>();
        services.AddScoped<IReportService, ReportService>();
        services.AddScoped<IOwnerService, OwnerService>();
        services.AddScoped<IAuditService, AuditService>();
        services.AddScoped<IUserService, UserService>();

        // Excel Export and Background Queue Services
        services.AddSingleton<IBackgroundTaskQueue, BackgroundTaskQueue>();
        services.AddSingleton<IExportJobManager, ExportJobManager>();
        services.AddScoped<IExcelExportService, ExcelExportService>();

        return services;
    }
}
