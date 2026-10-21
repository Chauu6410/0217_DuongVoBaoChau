using System.ComponentModel.DataAnnotations;
using System.Text.Json;
using duong_vo_bao_chau.Data;
using duong_vo_bao_chau.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

var options = new DbContextOptionsBuilder<ApplicationDbContext>()
    .UseSqlServer("Server=(localdb)\\MSSQLLocalDB;Database=LocationCheck;Trusted_Connection=True").Options;
using var context = new ApplicationDbContext(options);
if (context.Database.HasPendingModelChanges()) throw new Exception("Migration snapshot does not match model.");
var script = context.GetService<IMigrator>().GenerateScript("20261021164324_RemoveDeviceMac", "20261022000000_AddDeviceLocation");
foreach (var column in new[] { "Latitude", "Longitude", "LastUpdatedLocation" })
    if (!script.Contains($"ADD [{column}]")) throw new Exception("Missing column: " + column);

bool Valid(UpdateLocationModel value) => Validator.TryValidateObject(value, new ValidationContext(value), new List<ValidationResult>(), true);
if (!Valid(new() { DeviceId = 1, Latitude = 0, Longitude = 0 })) throw new Exception("Zero coordinates must be valid.");
if (!Valid(new() { DeviceId = 1, Latitude = -90, Longitude = 180 })) throw new Exception("Boundary coordinates must be valid.");
if (Valid(new() { DeviceId = 0, Latitude = 10, Longitude = 100 })) throw new Exception("Invalid device ID accepted.");
if (Valid(new() { DeviceId = 1, Latitude = 91, Longitude = 100 })) throw new Exception("Invalid latitude accepted.");
if (Valid(new() { DeviceId = 1, Latitude = 10, Longitude = -181 })) throw new Exception("Invalid longitude accepted.");
try
{
    JsonSerializer.Deserialize<UpdateLocationModel>("{\"deviceId\":1,\"latitude\":10}", new JsonSerializerOptions(JsonSerializerDefaults.Web));
    throw new Exception("Missing longitude accepted.");
}
catch (JsonException) { }
Console.WriteLine("PASS: migration snapshot, SQL columns, coordinate validation, required JSON fields.");
