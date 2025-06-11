using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Graduation_Project.Migrations
{
    public partial class informationaboutminerals : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "EnvironmentalConsideration",
                table: "Information",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "GeologicalOrigin",
                table: "Information",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "HistoricalContext",
                table: "Information",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "IndustrialUse",
                table: "Information",
                type: "nvarchar(max)",
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "EnvironmentalConsideration",
                table: "Information");

            migrationBuilder.DropColumn(
                name: "GeologicalOrigin",
                table: "Information");

            migrationBuilder.DropColumn(
                name: "HistoricalContext",
                table: "Information");

            migrationBuilder.DropColumn(
                name: "IndustrialUse",
                table: "Information");
        }
    }
}
