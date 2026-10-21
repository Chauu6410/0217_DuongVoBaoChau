using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using duong_vo_bao_chau.Data;
using duong_vo_bao_chau.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.IdentityModel.Tokens;

namespace duong_vo_bao_chau.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthenticateController : ControllerBase
{
    private readonly UserManager<User> _userManager;
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly IWebHostEnvironment _environment;
    private readonly IMemoryCache _cache;

    public AuthenticateController(UserManager<User> userManager, ApplicationDbContext context,
        IConfiguration configuration, IWebHostEnvironment environment, IMemoryCache cache)
    {
        _userManager = userManager;
        _context = context;
        _configuration = configuration;
        _environment = environment;
        _cache = cache;
    }

    [AllowAnonymous]
    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterModel model)
    {
        // Cho phép chọn mọi role trong Development để làm bài Lab.
        if (!_environment.IsDevelopment() && model.Role != "Parent")
            return BadRequest(new { Message = "Chỉ được tự đăng ký vai trò Parent." });
        if (await _userManager.FindByEmailAsync(model.Email) != null)
            return BadRequest(new { Message = "Email đã được sử dụng." });

        await using var transaction = await _context.Database.BeginTransactionAsync();
        var user = new User { UserName = model.Email, Email = model.Email, FullName = model.FullName };
        var result = await _userManager.CreateAsync(user, model.Password);
        if (!result.Succeeded) return BadRequest(result.Errors);
        result = await _userManager.AddToRoleAsync(user, model.Role);
        if (!result.Succeeded) return BadRequest(result.Errors);
        await transaction.CommitAsync();
        return Ok(new
        {
            Status = true,
            Message = "Đăng ký thành công. Gọi generate-otp để lấy mã đăng nhập.",
            user.Id,
            Username = user.UserName,
            model.Role
        });
    }

    [AllowAnonymous]
    [HttpPost("generate-otp")]
    public async Task<IActionResult> GenerateOtp(GenerateOtpModel model)
    {
        // Direct OTP response is for the local lab only.
        if (!_environment.IsDevelopment()) return NotFound();
        Response.Headers.CacheControl = "no-store";
        var user = await _userManager.FindByNameAsync(model.Username.Trim());
        if (user == null || await _userManager.IsLockedOutAsync(user))
            return Unauthorized(new { Status = false, Message = "Thông tin không hợp lệ hoặc tài khoản bị khóa." });

        if (!await _userManager.CheckPasswordAsync(user, model.Password))
        {
            await _userManager.AccessFailedAsync(user);
            return Unauthorized(new { Status = false, Message = "Username hoặc mật khẩu không hợp lệ." });
        }

        // Mỗi tài khoản có một mã riêng. Sinh mã mới sẽ thay thế mã cũ.
        var otp = RandomNumberGenerator.GetInt32(100000, 1000000).ToString();
        _cache.Set($"OTP:{user.Id}", otp, TimeSpan.FromMinutes(5));

        // Trả trực tiếp OTP để làm bài Lab; ứng dụng thực tế nên gửi qua email/SMS.
        return Ok(new { Status = true, Otp = otp });
    }

    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginModel model)
    {
        var user = await _userManager.FindByNameAsync(model.Username.Trim());
        if (user == null || await _userManager.IsLockedOutAsync(user))
            return Unauthorized(new { Message = "Thông tin không hợp lệ hoặc tài khoản bị khóa." });

        var passwordValid = await _userManager.CheckPasswordAsync(user, model.Password);
        var otpKey = $"OTP:{user.Id}";
        var otpValid = passwordValid
            && _cache.TryGetValue<string>(otpKey, out var savedOtp)
            && savedOtp == model.OtpCode.Trim();
        if (!otpValid)
        {
            await _userManager.AccessFailedAsync(user);
            return Unauthorized(new { Message = "Username, mật khẩu hoặc OTP không hợp lệ." });
        }

        // Xóa sau khi dùng thành công, lần đăng nhập tiếp theo cần lấy mã mới.
        _cache.Remove(otpKey);
        await _userManager.ResetAccessFailedCountAsync(user);
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.Name, user.UserName!),
            new Claim(ClaimTypes.NameIdentifier, user.Id),
            new Claim("Username", user.UserName!),
            new Claim("UserId", user.Id),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };
        foreach (var role in await _userManager.GetRolesAsync(user))
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
            claims.Add(new Claim("Role", role));
        }

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));
        var expires = DateTime.UtcNow.AddMinutes(60);
        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"], audience: _configuration["Jwt:Audience"],
            claims: claims, expires: expires,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));
        return Ok(new { Token = new JwtSecurityTokenHandler().WriteToken(token), Expiration = expires });
    }
}
