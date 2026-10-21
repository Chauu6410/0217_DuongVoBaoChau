using System.Security.Claims;
using duong_vo_bao_chau.Data;
using duong_vo_bao_chau.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace duong_vo_bao_chau.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin,Staff,Parent")]
public class DeviceController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    public DeviceController(ApplicationDbContext context) { _context = context; }

    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
    private bool CanManageAll => User.IsInRole("Admin") || User.IsInRole("Staff");

    private IQueryable<Device> AccessibleDevices()
    {
        return CanManageAll ? _context.Devices
            : _context.Devices.Where(d => d.UserId == CurrentUserId);
    }

    [HttpGet("parents")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<IActionResult> GetParents()
    {
        var parents = await (from user in _context.Users.AsNoTracking()
            join userRole in _context.UserRoles on user.Id equals userRole.UserId
            join role in _context.Roles on userRole.RoleId equals role.Id
            where role.Name == "Parent"
            orderby user.Email
            select new { user.Id, user.FullName, user.Email }).ToListAsync();
        return Ok(parents);
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Device>>> GetDevices()
    {
        return Ok(await AccessibleDevices().AsNoTracking().ToListAsync());
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<Device>> GetDeviceById(int id)
    {
        var device = await AccessibleDevices().AsNoTracking().FirstOrDefaultAsync(d => d.Id == id);
        if (device == null) return NotFound(new { Message = "Không tìm thấy thiết bị." });
        return Ok(device);
    }

    [HttpPost]
    public async Task<ActionResult<Device>> AddDevice(Device device)
    {
        if (!CanManageAll && device.UserId != CurrentUserId) return Forbid();
        if (!await _context.Users.AnyAsync(u => u.Id == device.UserId))
            return BadRequest(new { Message = "UserId không tồn tại." });
        device.Id = 0;
        // Vị trí được cập nhật riêng qua API update-location.
        device.Latitude = null;
        device.Longitude = null;
        device.LastUpdatedLocation = null;
        _context.Devices.Add(device);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetDeviceById), new { id = device.Id }, device);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> UpdateDevice(int id, Device model)
    {
        if (id != model.Id) return BadRequest(new { Message = "Id trên URL và dữ liệu không khớp." });
        var device = await AccessibleDevices().FirstOrDefaultAsync(d => d.Id == id);
        if (device == null) return NotFound(new { Message = "Không tìm thấy thiết bị." });
        if (!CanManageAll && model.UserId != CurrentUserId) return Forbid();
        if (!await _context.Users.AnyAsync(u => u.Id == model.UserId))
            return BadRequest(new { Message = "UserId không tồn tại." });
        device.DeviceName = model.DeviceName;
        device.BatteryLevel = model.BatteryLevel;
        device.IsLocked = model.IsLocked;
        device.UserId = model.UserId;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("update-location")]
    public async Task<IActionResult> UpdateLocation(UpdateLocationModel model)
    {
        var device = await AccessibleDevices().FirstOrDefaultAsync(d => d.Id == model.DeviceId);
        if (device == null) return NotFound(new { Message = "Không tìm thấy thiết bị." });

        device.Latitude = model.Latitude;
        device.Longitude = model.Longitude;
        device.LastUpdatedLocation = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(new
        {
            Status = true,
            device.Latitude,
            device.Longitude,
            device.LastUpdatedLocation
        });
    }

    [HttpGet("{id:int}/location")]
    public async Task<IActionResult> GetLocation(int id)
    {
        var location = await AccessibleDevices().AsNoTracking()
            .Where(d => d.Id == id)
            .Select(d => new { d.Latitude, d.Longitude, d.LastUpdatedLocation })
            .FirstOrDefaultAsync();

        if (location == null) return NotFound(new { Message = "Không tìm thấy thiết bị." });
        return Ok(location);
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> DeleteDevice(int id)
    {
        var device = await AccessibleDevices().FirstOrDefaultAsync(d => d.Id == id);
        if (device == null) return NotFound(new { Message = "Không tìm thấy thiết bị." });
        _context.Devices.Remove(device);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}
