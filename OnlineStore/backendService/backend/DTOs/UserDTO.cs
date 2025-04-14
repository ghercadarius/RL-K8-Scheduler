using OnlineShop.Models;

namespace OnlineShop.DTOs;

public class UserRegisterDTO
{
    public string Username { get; set; }
    public string Email { get; set; }
    public string Password { get; set; }
    public UserType UserType { get; set; }
}

public class UserLoginDTO
{
    public string Username { get; set; }
    public string Password { get; set; }
}

public class UserResponseDTO
{
    public int Id { get; set; }
    public string Username { get; set; }
    public string Email { get; set; }
    public UserType UserType { get; set; }
    public DateTime CreatedAt { get; set; }
} 