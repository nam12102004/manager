using DebtManager.Application.Interfaces.Repositories;
using DebtManager.Infrastructure.Data;
using DebtManager.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace DebtManager.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
    {
        var provider = configuration["DatabaseProvider"] ?? "Sqlite";

        services.AddDbContext<DebtManagerDbContext>(options =>
        {
            if (provider.Equals("PostgreSql", StringComparison.OrdinalIgnoreCase) || provider.Equals("Postgres", StringComparison.OrdinalIgnoreCase))
            {
                var connectionString = configuration.GetConnectionString("PostgresConnection") 
                    ?? configuration.GetConnectionString("DefaultConnection");
                options.UseNpgsql(connectionString);
            }
            else if (provider.Equals("SqlServer", StringComparison.OrdinalIgnoreCase))
            {
                var connectionString = configuration.GetConnectionString("SqlServerConnection") 
                    ?? configuration.GetConnectionString("DefaultConnection");
                options.UseSqlServer(connectionString);
            }
            else
            {
                var connectionString = configuration.GetConnectionString("SqliteConnection") ?? "Data Source=debtmanager.db";
                options.UseSqlite(connectionString);
            }
        });

        services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        return services;
    }
}
