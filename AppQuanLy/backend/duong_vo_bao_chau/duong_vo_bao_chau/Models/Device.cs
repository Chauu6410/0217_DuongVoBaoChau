using System.ComponentModel.DataAnnotations;

namespace duong_vo_bao_chau.Models;

public class Device
{
    public int Id { get; set; }
    [Required, StringLength(100)]
    public string DeviceName { get; set; } = string.Empty;
    [Range(0, 100)]
    public int BatteryLevel { get; set; }
    public bool IsLocked { get; set; }
    [Required]
    public string UserId { get; set; } = string.Empty;

    [Range(-90, 90)]
    public double? Latitude { get; set; }

    [Range(-180, 180)]
    public double? Longitude { get; set; }

    public DateTime? LastUpdatedLocation { get; set; }
}
