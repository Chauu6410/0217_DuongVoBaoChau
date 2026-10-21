using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;

namespace duong_vo_bao_chau.Models;

public class User : IdentityUser
{
    [Required, StringLength(100)]
    public string FullName { get; set; } = string.Empty;
}
