using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using OnlineShop.DTOs;
using OnlineShop.Services;
using System.Security.Claims;

namespace OnlineShop.Controllers;

/// <summary>
/// Controller for managing product-related operations such as listing, viewing, and creating products.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class ProductController : ControllerBase
{
    private readonly IProductService _productService;

    public ProductController(IProductService productService)
    {
        _productService = productService;
    }

    /// <summary>
    /// Retrieves all products in the system.
    /// </summary>
    /// <returns>A list of all products.</returns>
    /// <response code="200">Returns the list of products.</response>
    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<ActionResult<List<ProductResponseDTO>>> GetAllProducts()
    {
        try
        {
            var products = await _productService.GetAllProducts();
            return Ok(products);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    /// <summary>
    /// Retrieves a specific product by its ID.
    /// </summary>
    /// <param name="id">The ID of the product to retrieve.</param>
    /// <returns>The product information.</returns>
    /// <response code="200">Returns the requested product.</response>
    /// <response code="400">If the product is not found.</response>
    [HttpGet("{id}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ProductResponseDTO>> GetProduct(int id)
    {
        try
        {
            var product = await _productService.GetProductById(id);
            return Ok(product);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    /// <summary>
    /// Creates a new product in the system.
    /// </summary>
    /// <param name="productDto">The product data to create.</param>
    /// <returns>The created product information.</returns>
    /// <response code="200">Returns the newly created product.</response>
    /// <response code="400">If the product data is invalid.</response>
    /// <response code="401">If the user is not authenticated.</response>
    /// <response code="403">If the user is not a seller.</response>
    [Authorize(Roles = "Seller")]
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<ActionResult<ProductResponseDTO>> CreateProduct(ProductCreateDTO productDto)
    {
        try
        {
            var sellerId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value);
            var product = await _productService.CreateProduct(productDto, sellerId);
            return Ok(product);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }
} 