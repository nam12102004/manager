namespace DebtManager.Application.DTOs.Users;

public class UserDto
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Role { get; set; } = "nv";
    public DateTime CreatedAt { get; set; }
}

public class CreateUserDto
{
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Role { get; set; } = "nv";
}

public class ChangePasswordDto
{
    public string NewPassword { get; set; } = string.Empty;
}

public class UpdateUserRoleDto
{
    public string Role { get; set; } = "nv";
}
