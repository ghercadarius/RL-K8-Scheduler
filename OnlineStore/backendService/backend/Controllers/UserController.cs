using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OnlineShop.DTOs;
using OnlineShop.Services;

namespace OnlineShop.Controllers;

/// <summary>
/// Controller for managing user-related operations such as registration, login, and profile retrieval.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class UserController : ControllerBase
{
    private readonly IUserService _userService;

    public UserController(IUserService userService)
    {
        _userService = userService;
    }

    /// <summary>
    /// Registers a new user in the system.
    /// </summary>
    /// <param name="userDto">The user registration data.</param>
    /// <returns>The created user's information.</returns>
    /// <response code="200">Returns the newly created user.</response>
    /// <response code="400">If the username or email is already taken.</response>
    [HttpPost("register")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<UserResponseDTO>> Register(UserRegisterDTO userDto)
    {
        try
        {
            var user = await _userService.Register(userDto);
            return Ok(user);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    /// <summary>
    /// Authenticates a user and returns a JWT token.
    /// </summary>
    /// <param name="userDto">The user login credentials.</param>
    /// <returns>A JWT token for authentication.</returns>
    /// <response code="200">Returns the JWT token.</response>
    /// <response code="400">If the credentials are invalid.</response>
    [HttpPost("login")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<string>> Login(UserLoginDTO userDto)
    {
        try
        {
            var token = await _userService.Login(userDto);
            return Ok(new { token });
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    /// <summary>
    /// Retrieves a user's profile by their ID.
    /// </summary>
    /// <param name="id">The ID of the user to retrieve.</param>
    /// <returns>The user's profile information.</returns>
    /// <response code="200">Returns the user's profile.</response>
    /// <response code="400">If the user is not found.</response>
    /// <response code="401">If the user is not authenticated.</response>
    [Authorize]
    [HttpGet("{id}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<UserResponseDTO>> GetUser(int id)
    {
        try
        {
            var user = await _userService.GetUserById(id);
            return Ok(user);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }
} 