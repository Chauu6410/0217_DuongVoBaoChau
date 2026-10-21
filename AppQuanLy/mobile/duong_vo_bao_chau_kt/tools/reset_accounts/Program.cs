using duong_vo_bao_chau.Data;
using duong_vo_bao_chau.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

// Công cụ xóa dữ liệu: chỉ chạy khi người dùng yêu cầu rõ ràng.
if (args.Length != 1 || args[0] != "--reset-all-accounts")
    throw new InvalidOperationException("Cần --reset-all-accounts để xác nhận phạm vi.");
var configuration = new ConfigurationBuilder()
    .AddJsonFile("C:/Users/Admin/source/repos/duong_vo_bao_chau/duong_vo_bao_chau/appsettings.json")
    .AddJsonFile("C:/Users/Admin/source/repos/duong_vo_bao_chau/duong_vo_bao_chau/appsettings.Development.json", optional: true)
    .Build();
var services = new ServiceCollection();
services.AddLogging();
services.AddDataProtection();
services.AddDbContext<ApplicationDbContext>(o =>
    o.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));
services.AddIdentityCore<User>().AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>().AddDefaultTokenProviders();
await using var provider = services.BuildServiceProvider();
await using var scope = provider.CreateAsyncScope();
var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
var users = scope.ServiceProvider.GetRequiredService<UserManager<User>>();
var roles = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
await using var transaction = await db.Database.BeginTransactionAsync();
// Không xóa dây chuyền thiết bị nếu dữ liệu đã thay đổi từ lúc kiểm tra.
if (await db.Devices.AnyAsync())
    throw new InvalidOperationException("Có thiết bị liên quan; dừng để bảo toàn dữ liệu.");
foreach (var role in new[] { "Admin", "Staff", "Parent" })
{
    if (!await roles.RoleExistsAsync(role)) Check(await roles.CreateAsync(new IdentityRole(role)));
}
var oldUsers = await users.Users.ToListAsync();
foreach (var user in oldUsers) Check(await users.DeleteAsync(user));
foreach (var account in new[] {
    ("admin@example.com", "Quan tri vien", "Admin", "Admin123!"),
    ("staff@example.com", "Nhan vien", "Staff", "Staff123!"),
    ("parent@example.com", "Phu huynh", "Parent", "Parent123!")
})
{
    var user = new User { UserName = account.Item1, Email = account.Item1, FullName = account.Item2 };
    Check(await users.CreateAsync(user, account.Item4));
    Check(await users.AddToRoleAsync(user, account.Item3));
    Check(await users.ResetAuthenticatorKeyAsync(user));
    if (!await users.CheckPasswordAsync(user, account.Item4))
        throw new InvalidOperationException("Kiểm tra mật khẩu thất bại.");
    Console.WriteLine($"Created {account.Item1}: {account.Item3}");
}
await transaction.CommitAsync();
Console.WriteLine($"Removed {oldUsers.Count} old accounts. Total accounts: {await users.Users.CountAsync()}.");

static void Check(IdentityResult result)
{
    if (!result.Succeeded)
        throw new InvalidOperationException(string.Join("; ", result.Errors.Select(e => e.Description)));
}
