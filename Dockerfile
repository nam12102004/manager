# Multi-stage build for DebtManager ASP.NET Core API (.NET 8)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files for caching restore layer
COPY ["src/DebtManager.Domain/DebtManager.Domain.csproj", "src/DebtManager.Domain/"]
COPY ["src/DebtManager.Application/DebtManager.Application.csproj", "src/DebtManager.Application/"]
COPY ["src/DebtManager.Infrastructure/DebtManager.Infrastructure.csproj", "src/DebtManager.Infrastructure/"]
COPY ["src/DebtManager.Api/DebtManager.Api.csproj", "src/DebtManager.Api/"]

# Restore packages
RUN dotnet restore "src/DebtManager.Api/DebtManager.Api.csproj"

# Copy remaining source code and publish
COPY . .
WORKDIR "/src/src/DebtManager.Api"
RUN dotnet publish "DebtManager.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
EXPOSE 5050

ENV ASPNETCORE_URLS=http://+:5050 \
    ASPNETCORE_ENVIRONMENT=Production \
    DatabaseProvider=Sqlite \
    ConnectionStrings__SqliteConnection="Data Source=/app/data/debtmanager.db"

# Create directory for persistent data (SQLite db, files)
RUN mkdir -p /app/data

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "DebtManager.Api.dll"]
