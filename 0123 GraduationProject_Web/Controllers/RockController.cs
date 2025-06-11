using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Graduation_Project.Models;
using System.Text.Json;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text;
using System.IO;
using System.Linq;

namespace Graduation_Project.Controllers
{
    public class RockController : Controller
    {
        private readonly RockInfoContext RockInfoContext;
        private readonly IWebHostEnvironment webHostEnvironment;
        private readonly IHttpClientFactory _httpClientFactory;
        private const string FlaskApiUrl = "http://localhost:5000/api/mineral/detect";
        public RockController(RockInfoContext rockInfoContext, IWebHostEnvironment webHostEnvironment, IHttpClientFactory httpClientFactory)
        {
            RockInfoContext = rockInfoContext;
            this.webHostEnvironment = webHostEnvironment;
            _httpClientFactory = httpClientFactory;
        }

        [HttpGet]
        public IActionResult GetHomePage() => View("Home");

        [HttpPost]
        public async Task<IActionResult> AddImage(Information information)

        {
            //Information infoo = RockInfoContext.Information.FirstOrDefault(f=>new{ f.GeologicalOrigin, f.HistoricalContext, f.IndustrialUse } == information );
            if (information.ImageFile == null || information.ImageFile.Length == 0)
            {
                ModelState.AddModelError("ImageFile", "Please upload a valid image file.");
                return View("Index");
            }

            string imageFolder = Path.Combine(webHostEnvironment.WebRootPath, "Images");
            Directory.CreateDirectory(imageFolder); // Create if not exists

            string extension = Path.GetExtension(information.ImageFile.FileName);
            string uniqueName = $"{Guid.NewGuid()}{extension}";
            string imgPath = Path.Combine(imageFolder, uniqueName);
            string imgWebPath = $"/Images/{uniqueName}";

            // Save original image
            using (var stream = new FileStream(imgPath, FileMode.Create))
            {
                await information.ImageFile.CopyToAsync(stream);
            }

            try
            {

                byte[] imageBytes = await System.IO.File.ReadAllBytesAsync(imgPath);
                string base64Image = Convert.ToBase64String(imageBytes);

                var client = _httpClientFactory.CreateClient();
                var payload = new { image = base64Image };
                var content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

                var response = await client.PostAsync(FlaskApiUrl, content);

                if (response.IsSuccessStatusCode)
                {
                    using var responseStream = await response.Content.ReadAsStreamAsync();
                    var responseJson = await JsonDocument.ParseAsync(responseStream);

                    var root = responseJson.RootElement;

                    if (root.GetProperty("success").GetBoolean())
                    {
                        var detections = root.GetProperty("detections");
                        var resultImageBase64 = root.GetProperty("result_image").GetString();

                        string resultImgName = $"detected_{uniqueName}";
                        string resultImgPath = Path.Combine(imageFolder, resultImgName);
                        string resultImgWebPath = $"/Images/{resultImgName}";

                        byte[] resultBytes = Convert.FromBase64String(resultImageBase64);
                        await System.IO.File.WriteAllBytesAsync(resultImgPath, resultBytes);

                        var classNames = new List<string>();
                        foreach (var detection in detections.EnumerateArray())
                        {
                            if (detection.TryGetProperty("class", out var classProp))
                            {
                                classNames.Add(classProp.GetString());
                            }
                        }
                      
                    var DistinctClasses = classNames.Distinct().ToList();

                    if (DistinctClasses.Count > 1)
                    information.DetectedClasses = string.Join(", ", DistinctClasses);
                    else { information.Name = DistinctClasses.FirstOrDefault() ?? "No Detection"; }
                    information.ImagePath = imgWebPath;
                    information.ResultImagePath = resultImgWebPath;
                    RockInfoContext.Add(information);
                        //RockInfoContext.SaveChanges();
                        return View("Result", information);
                }
            }

                ModelState.AddModelError("", "Failed to process image.");
            return View("Home");
        }
            catch (Exception ex)
            {
                ModelState.AddModelError("", $"Error: {ex.Message}");
                return View("Home");
            }

        }
        public IActionResult DisplayMoreInformation(string Name) {
               
            Information information = RockInfoContext.Information.FirstOrDefault(n => n.Name == Name);

                return Json(new
                {
                    name = information.Name,
                    formula = information.ChemicalFormula,
                    color = information.Color,
                    density = information.Density,
                    hardness = information.Hardness,
                    historicalContext= information.HistoricalContext,
                    industrialUse= information.IndustrialUse,
                    geologicalOrigin= information.GeologicalOrigin,
                });
            }
    }
}
