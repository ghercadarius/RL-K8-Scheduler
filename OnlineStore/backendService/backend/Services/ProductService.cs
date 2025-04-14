using AutoMapper;
using Microsoft.EntityFrameworkCore;
using OnlineShop.Data;
using OnlineShop.DTOs;
using OnlineShop.Models;

namespace OnlineShop.Services;

public interface IProductService
{
    Task<ProductResponseDTO> CreateProduct(ProductCreateDTO productDto, int sellerId);
    Task<List<ProductResponseDTO>> GetAllProducts();
    Task<ProductResponseDTO> GetProductById(int id);
}

public class ProductService : IProductService
{
    private readonly ApplicationDbContext _context;
    private readonly IMapper _mapper;

    public ProductService(ApplicationDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public async Task<ProductResponseDTO> CreateProduct(ProductCreateDTO productDto, int sellerId)
    {
        var seller = await _context.Users.FindAsync(sellerId);
        if (seller == null || seller.UserType != UserType.Seller)
            throw new Exception("Invalid seller");

        var product = _mapper.Map<Product>(productDto);
        product.SellerId = sellerId;

        _context.Products.Add(product);
        await _context.SaveChangesAsync();

        return await GetProductById(product.Id);
    }

    public async Task<List<ProductResponseDTO>> GetAllProducts()
    {
        var products = await _context.Products
            .Include(p => p.Seller)
            .ToListAsync();

        return _mapper.Map<List<ProductResponseDTO>>(products);
    }

    public async Task<ProductResponseDTO> GetProductById(int id)
    {
        var product = await _context.Products
            .Include(p => p.Seller)
            .FirstOrDefaultAsync(p => p.Id == id);

        if (product == null)
            throw new Exception("Product not found");

        return _mapper.Map<ProductResponseDTO>(product);
    }
} 