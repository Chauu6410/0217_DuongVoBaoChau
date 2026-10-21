using duong_vo_bao_chau.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace duong_vo_bao_chau.Controllers;

[ApiController]
[Route("api/Users")]
[Authorize(Roles = "Admin")]
public class UsersController : ControllerBase
{
    private readonly UserManager<User> _users;
    public UsersController(UserManager<User> users) { _users = users; }

    [HttpGet]
    public async Task<IActionResult> GetUsers([FromQuery] string? role)
    {
        if (role != null && role != "Admin" && role != "Staff" && role != "Parent")
            return BadRequest(new { Message = "Role không hợp lệ." });
        var accounts = role == null
            ? await _users.Users.AsNoTracking().OrderBy(u => u.Email).ToListAsync()
            : (await _users.GetUsersInRoleAsync(role)).OrderBy(u => u.Email).ToList();
        var result = new List<object>();
        foreach (var user in accounts)
            result.Add(new { user.Id, user.FullName, user.Email, Roles = await _users.GetRolesAsync(user) });
        return Ok(result);
    }
}
