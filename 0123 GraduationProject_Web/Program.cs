using Microsoft.EntityFrameworkCore;
using Graduation_Project.Models;
namespace Graduation_Project
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services to the container.
            builder.Services.AddHttpClient();
            builder.Services.AddControllersWithViews();
            builder.Services.AddDbContext<RockInfoContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("Database")));

            var app = builder.Build();

            // Configure the HTTP request pipeline.
            if (!app.Environment.IsDevelopment())
            {
                app.UseExceptionHandler("/Home/Error");
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            app.UseRouting();

            app.UseAuthorization();

            app.MapStaticAssets();
            app.MapControllerRoute(
                name: "default",
                pattern: "{controller=Rock}/{action=GetHomePage}/{id?}")
                .WithStaticAssets();

            app.Run();
        }
    }
}
