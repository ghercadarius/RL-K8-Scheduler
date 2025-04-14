using AutoMapper;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using OnlineShop.Data;
using OnlineShop.DTOs;
using OnlineShop.Models;

namespace OnlineShop.Services;

public interface IUserService
{
    Task<UserResponseDTO> Register(UserRegisterDTO userDto);
    Task<string> Login(UserLoginDTO userDto);
    Task<UserResponseDTO> GetUserById(int id);
}

public class UserService : IUserService
{
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly IMapper _mapper;

    public UserService(ApplicationDbContext context, IConfiguration configuration, IMapper mapper)
    {
        _context = context;
        _configuration = configuration;
        _mapper = mapper;
    }

    public async Task<UserResponseDTO> Register(UserRegisterDTO userDto)
    {
        if (await _context.Users.AnyAsync(u => u.Username == userDto.Username))
            throw new Exception("Username already exists");

        if (await _context.Users.AnyAsync(u => u.Email == userDto.Email))
            throw new Exception("Email already exists");

        var user = _mapper.Map<User>(userDto);
        user.PasswordHash = HashPassword(userDto.Password);

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return _mapper.Map<UserResponseDTO>(user);
    }

    public async Task<string> Login(UserLoginDTO userDto)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(u => u.Username == userDto.Username);

        if (user == null || !VerifyPassword(userDto.Password, user.PasswordHash))
            throw new Exception("Invalid username or password");

        return GenerateJwtToken(user);
    }

    public async Task<UserResponseDTO> GetUserById(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
            throw new Exception("User not found");

        return _mapper.Map<UserResponseDTO>(user);
    }

    private string HashPassword(string password)
    {
        using var sha256 = SHA256.Create();
        var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
        return Convert.ToBase64String(hashedBytes);
    }

    private bool VerifyPassword(string password, string hash)
    {
        return HashPassword(password) == hash;
    }

    private string GenerateJwtToken(User user)
    {
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Role, user.UserType.ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.Now.AddDays(1),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
} 