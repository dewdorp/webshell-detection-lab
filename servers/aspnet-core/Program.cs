using System.Security.Cryptography;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

const string runtime = "aspnet";
var projectDir = Directory.GetCurrentDirectory();
var rootDir = Path.GetFullPath(Path.Combine(projectDir, "..", ".."));
var uploadDir = Path.Combine(projectDir, "uploads");
var logDir = Path.Combine(projectDir, "logs");
var commonDir = Path.Combine(rootDir, "common");
Directory.CreateDirectory(uploadDir);
Directory.CreateDirectory(logDir);

static string CleanFilename(string filename) {
    var name = Path.GetFileName(string.IsNullOrWhiteSpace(filename) ? "upload.bin" : filename);
    foreach (var invalid in Path.GetInvalidFileNameChars()) name = name.Replace(invalid, '_');
    return string.IsNullOrWhiteSpace(name) ? "upload.bin" : name;
}
static string Sha256(string path) { using var stream = File.OpenRead(path); return Convert.ToHexString(SHA256.HashData(stream)).ToLowerInvariant(); }
static async Task SendFile(HttpContext context, string path, string contentType) { if (!File.Exists(path)) { context.Response.StatusCode = StatusCodes.Status404NotFound; await context.Response.WriteAsync("Not found"); return; } context.Response.ContentType = contentType; await context.Response.SendFileAsync(path); }

app.MapGet("/", async context => await SendFile(context, Path.Combine(commonDir, "templates", "index.html"), "text/html; charset=utf-8"));
app.MapGet("/static/{name}", async (HttpContext context, string name) => { var safeName = CleanFilename(name); var contentType = safeName.EndsWith(".css", StringComparison.OrdinalIgnoreCase) ? "text/css; charset=utf-8" : "application/javascript; charset=utf-8"; await SendFile(context, Path.Combine(commonDir, "public", safeName), contentType); });
app.MapGet("/uploads/{name}", async (HttpContext context, string name) => await SendFile(context, Path.Combine(uploadDir, CleanFilename(name)), "application/octet-stream"));
app.MapGet("/health", () => Results.Json(new { ok = true, runtime, uploadPath = uploadDir }));
app.MapPost("/upload", async (HttpContext context) => {
    var form = await context.Request.ReadFormAsync();
    var file = form.Files.GetFile("file");
    if (file is null) return Results.BadRequest(new { success = false, message = "file field is required" });
    var storedName = CleanFilename(file.FileName);
    var storedPath = Path.Combine(uploadDir, storedName);
    await using (var output = File.Create(storedPath)) await file.CopyToAsync(output);
    var uploadEvent = new { runtime, originalName = file.FileName, storedName, storedPath, size = new FileInfo(storedPath).Length, mimeType = file.ContentType, sha256 = Sha256(storedPath), uploadedAt = DateTimeOffset.UtcNow, remoteAddress = context.Connection.RemoteIpAddress?.ToString() ?? "" };
    await File.AppendAllTextAsync(Path.Combine(logDir, "upload-events.jsonl"), JsonSerializer.Serialize(uploadEvent) + Environment.NewLine);
    return Results.Json(new { success = true, file = uploadEvent });
});
app.MapGet("/files", () => { var files = Directory.GetFiles(uploadDir).Select(path => new FileInfo(path)).OrderBy(file => file.Name).Select(file => new { name = file.Name, size = file.Length, modifiedAt = file.LastWriteTimeUtc, url = $"/uploads/{Uri.EscapeDataString(file.Name)}" }); return Results.Json(new { runtime, files }); });
app.Run();
