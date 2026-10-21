using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace duong_vo_bao_chau.Models;

public class UpdateLocationModel
{
    [JsonRequired, Range(1, int.MaxValue)]
    public int DeviceId { get; set; }

    [JsonRequired, Range(-90, 90)]
    public double Latitude { get; set; }

    [JsonRequired, Range(-180, 180)]
    public double Longitude { get; set; }
}
