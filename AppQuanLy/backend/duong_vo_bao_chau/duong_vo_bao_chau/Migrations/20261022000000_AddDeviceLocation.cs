using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace duong_vo_bao_chau.Migrations;

public partial class AddDeviceLocation : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<double>(
            name: "Latitude", table: "Devices", type: "float", nullable: true);
        migrationBuilder.AddColumn<double>(
            name: "Longitude", table: "Devices", type: "float", nullable: true);
        migrationBuilder.AddColumn<DateTime>(
            name: "LastUpdatedLocation", table: "Devices", type: "datetime2", nullable: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(name: "Latitude", table: "Devices");
        migrationBuilder.DropColumn(name: "Longitude", table: "Devices");
        migrationBuilder.DropColumn(name: "LastUpdatedLocation", table: "Devices");
    }
}
