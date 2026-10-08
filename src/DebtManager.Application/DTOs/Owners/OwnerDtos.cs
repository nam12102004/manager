namespace DebtManager.Application.DTOs.Owners;

public class OwnerDto
{
    public int Id { get; set; }
    public string Info { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class UpdateOwnerDto
{
    public string Info { get; set; } = string.Empty;
}
