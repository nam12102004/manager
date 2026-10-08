using DebtManager.Application;
using DebtManager.Infrastructure;
using DebtManager.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "Debt Manager API",
        Version = "v1",
        Description = "API Quản lý Bán hàng, Kho hàng đa điểm, Công nợ và Thu chi (.NET 8 Clean Architecture)"
    });
});

// Configure CORS
builder.Services.AddCors(opts =>
{
    opts.AddDefaultPolicy(p =>
    {
        p.AllowAnyHeader()
         .AllowAnyMethod()
         .AllowCredentials()
         .SetIsOriginAllowed(_ => true);
    });
});

// Add Clean Architecture Services
builder.Services.AddInfrastructureServices(builder.Configuration);
builder.Services.AddApplicationServices();

var app = builder.Build();

// Ensure Database is created on startup
using (var scope = app.Services.CreateScope())
{
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    try
    {
        var db = scope.ServiceProvider.GetRequiredService<DebtManagerDbContext>();
        logger.LogInformation("Ensuring database is created...");
        await db.Database.EnsureCreatedAsync();
        logger.LogInformation("Database is ready.");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "An error occurred while creating/migrating database.");
    }
}

// Global Exception Handling Middleware
app.UseMiddleware<DebtManager.Api.Middlewares.ExceptionHandlingMiddleware>();

// Enable Swagger in Development and Docker
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Debt Manager API v1");
    c.RoutePrefix = "swagger";
});

app.UseCors();

// Redirect root URL to swagger
app.MapGet("/", () => Results.Redirect("/swagger"));

app.UseAuthorization();

app.MapControllers();

app.Run();
