using AutoMapper;
using OnlineShop.DTOs;
using OnlineShop.Models;

namespace OnlineShop.Mapping;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        // User mappings
        CreateMap<User, UserResponseDTO>();
        CreateMap<UserRegisterDTO, User>()
            .ForMember(dest => dest.PasswordHash, opt => opt.Ignore());

        // Product mappings
        CreateMap<Product, ProductResponseDTO>()
            .ForMember(dest => dest.SellerUsername, opt => opt.MapFrom(src => src.Seller.Username));
        CreateMap<ProductCreateDTO, Product>();
    }
} 