namespace DebtManager.Application.DTOs.Audit;

public class LoginHistoryDto
{
    public long Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public bool IsSuccess { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? Device { get; set; }
    public string? Note { get; set; }
    public DateTime LoginTime { get; set; }
}

public class CreateLoginHistoryDto
{
    public string Username { get; set; } = string.Empty;
    public bool IsSuccess { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? Device { get; set; }
    public string? Note { get; set; }
}
