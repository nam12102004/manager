namespace DebtManager.Domain.Entities;

public class AuditLog
{
    public long Id { get; set; }
    public string Action { get; set; } = string.Empty; // "CREATE", "UPDATE", "DELETE", "ADJUST", "CANCEL"
    public string EntityName { get; set; } = string.Empty; // "Product", "Customer", "Supplier", "ExportVoucher", "ImportVoucher", "Receipt", "Payment", "Owner"
    public string EntityId { get; set; } = string.Empty;
    public string EntityDisplayName { get; set; } = string.Empty;
    public string? Details { get; set; }
    public string Username { get; set; } = "admin";
    public string? IpAddress { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
