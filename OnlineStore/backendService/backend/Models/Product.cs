using System.ComponentModel.DataAnnotations;

namespace OnlineShop.Models;

public class Product
{
    public int Id { get; set; }
    
    [Required]
    [StringLength(100)]
    public string Name { get; set; }
    
    [Required]
    public string Description { get; set; }
    
    [Required]
    [Range(0.01, double.MaxValue)]
    public decimal Price { get; set; }
    
    [Required]
    public int StockQuantity { get; set; }
    
    public int SellerId { get; set; }
    public User Seller { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
} 