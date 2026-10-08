namespace DebtManager.Domain.Entities;

public class Owner
{
    public int Id { get; set; }
    public string Info { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
