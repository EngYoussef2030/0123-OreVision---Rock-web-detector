using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Graduation_Project.Migrations
{
    /// <inheritdoc />
    public partial class modifydomainclassconfiguration : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DetectedClasses",
                table: "Information");

            migrationBuilder.DropColumn(
                name: "ImagePath",
                table: "Information");

            migrationBuilder.DropColumn(
                name: "ResultImagePath",
                table: "Information");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DetectedClasses",
                table: "Information",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ImagePath",
                table: "Information",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ResultImagePath",
                table: "Information",
                type: "nvarchar(max)",
                nullable: true);
        }
    }
}
