using System.ComponentModel.DataAnnotations;

namespace duong_vo_bao_chau.Models;

public class GenerateOtpModel
{
    [Required]
    public string Username { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;
}
