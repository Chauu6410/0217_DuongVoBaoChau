using System.ComponentModel.DataAnnotations;

namespace duong_vo_bao_chau.Models;

public class RegisterModel
{
    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;
    [Required, StringLength(100, MinimumLength = 6)]
    public string Password { get; set; } = string.Empty;
    [Required, StringLength(100)]
    public string FullName { get; set; } = string.Empty;
    [Required, RegularExpression("^(Admin|Staff|Parent)$")]
    public string Role { get; set; } = "Parent";
}
