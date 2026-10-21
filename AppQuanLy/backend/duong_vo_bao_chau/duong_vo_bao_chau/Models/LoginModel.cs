using System.ComponentModel.DataAnnotations;

namespace duong_vo_bao_chau.Models;

public class LoginModel
{
    [Required]
    public string Username { get; set; } = string.Empty;
    [Required]
    public string Password { get; set; } = string.Empty;
    [Required, RegularExpression(@"^\d{6}$")]
    public string OtpCode { get; set; } = string.Empty;
}
