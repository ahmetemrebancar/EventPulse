using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace EventPulse.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSeedData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Events",
                columns: new[] { "Id", "Category", "City", "Description", "MaxCapacity", "StartDate", "Title" },
                values: new object[,]
                {
                    { 1, "Teknoloji", "İstanbul", ".NET 8 ve Flutter ile modern uygulama geliştirme pratikleri.", 200, new DateTime(2026, 5, 15, 14, 0, 0, 0, DateTimeKind.Utc), "Yazılım Mimari Zirvesi" },
                    { 2, "Müzik", "İzmir", "Sevilen rock gruplarıyla yaza merhaba diyoruz.", 5000, new DateTime(2026, 6, 20, 19, 30, 0, 0, DateTimeKind.Utc), "Açık Hava Rock Konseri" }
                });

            migrationBuilder.InsertData(
                table: "Comments",
                columns: new[] { "Id", "Content", "CreatedAt", "EventId", "UserId" },
                values: new object[] { 1, "Harika bir etkinlik, kesinlikle orada olacağım!", new DateTime(2026, 3, 1, 10, 0, 0, 0, DateTimeKind.Utc), 1, "test_user_1" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Comments",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Events",
                keyColumn: "Id",
                keyValue: 1);
        }
    }
}
