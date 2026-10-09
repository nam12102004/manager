namespace DebtManager.Domain.Entities;

public class LoginHistory
{
    public long Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public bool IsSuccess { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? Device { get; set; }
    public string? Note { get; set; }
    public DateTime LoginTime { get; set; } = DateTime.UtcNow;
}
