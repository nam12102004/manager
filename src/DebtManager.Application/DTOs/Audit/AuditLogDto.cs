namespace DebtManager.Application.DTOs.Audit;

public class AuditLogDto
{
    public long Id { get; set; }
    public string Action { get; set; } = string.Empty;
    public string EntityName { get; set; } = string.Empty;
    public string EntityId { get; set; } = string.Empty;
    public string EntityDisplayName { get; set; } = string.Empty;
    public string? Details { get; set; }
    public string Username { get; set; } = string.Empty;
    public string? IpAddress { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateAuditLogDto
{
    public string Action { get; set; } = string.Empty;
    public string EntityName { get; set; } = string.Empty;
    public string EntityId { get; set; } = string.Empty;
    public string EntityDisplayName { get; set; } = string.Empty;
    public string? Details { get; set; }
    public string Username { get; set; } = "admin";
    public string? IpAddress { get; set; }
}
