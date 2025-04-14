namespace OnlineShop.DTOs;

public class ProductCreateDTO
{
    public string Name { get; set; }
    public string Description { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
}

public class ProductResponseDTO
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public int SellerId { get; set; }
    public string SellerUsername { get; set; }
    public DateTime CreatedAt { get; set; }
} 