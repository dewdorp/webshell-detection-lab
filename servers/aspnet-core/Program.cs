using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

const string runtime = "aspnet";
var projectDir = Directory.GetCurrentDirectory();
var rootDir = Path.GetFullPath(Path.Combine(projectDir, "..", ".."));
var uploadDir = Path.Combine(projectDir, "uploads");
var logDir = Path.Combine(projectDir, "logs");
var commonDir = Path.Combine(rootDir, "common");
var uploadExecutable = UploadExecutableEnabled();

Directory.CreateDirectory(uploadDir);
Directory.CreateDirectory(logDir);
ApplyExecutableUploadPermissions(uploadDir, uploadExecutable);

static bool UploadExecutableEnabled()
{
    var value = Environment.GetEnvironmentVariable("LAB_UPLOAD_EXECUTABLE")?.ToLowerInvariant() ?? "0";
    return value is "1" or "true" or "yes" or "on";
}

static void ApplyExecutableUploadPermissions(string path, bool enabled)
{
    if (!enabled || OperatingSystem.IsWindows()) return;

    File.SetUnixFileMode(path,
        UnixFileMode.UserRead |
        UnixFileMode.UserWrite |
        UnixFileMode.UserExecute |
        UnixFileMode.GroupRead |
        UnixFileMode.GroupWrite |
        UnixFileMode.GroupExecute |
        UnixFileMode.OtherRead |
        UnixFileMode.OtherExecute);
}

static string CleanFilename(string filename)
{
    var name = Path.GetFileName(string.IsNullOrWhiteSpace(filename) ? "upload.bin" : filename);
    foreach (var invalid in Path.GetInvalidFileNameChars()) name = name.Replace(invalid, '_');
    return string.IsNullOrWhiteSpace(name) ? "upload.bin" : name;
}

static string Sha256(string path)
{
    using var stream = File.OpenRead(path);
    return Convert.ToHexString(SHA256.HashData(stream)).ToLowerInvariant();
}

static string TokenFor(string username)
{
    var payload = JsonSerializer.Serialize(new { username, issuedAt = DateTimeOffset.UtcNow });
    return Convert.ToBase64String(Encoding.UTF8.GetBytes(payload));
}

static string? UsernameFromToken(HttpContext context)
{
    var header = context.Request.Headers.Authorization.ToString();
    var token = header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) ? header[7..] : "";
    if (string.IsNullOrWhiteSpace(token)) return null;
    try
    {
        using var document = JsonDocument.Parse(Encoding.UTF8.GetString(Convert.FromBase64String(token)));
        return document.RootElement.GetProperty("username").GetString();
    }
    catch
    {
        return null;
    }
}

static async Task SendFile(HttpContext context, string path, string contentType)
{
    if (!File.Exists(path))
    {
        context.Response.StatusCode = StatusCodes.Status404NotFound;
        await context.Response.WriteAsync("Not found");
        return;
    }
    context.Response.ContentType = contentType;
    await context.Response.SendFileAsync(path);
}

app.MapGet("/", async context => await SendFile(context, Path.Combine(commonDir, "templates", "index.html"), "text/html; charset=utf-8"));
app.MapGet("/index.html", async context => await SendFile(context, Path.Combine(commonDir, "templates", "index.html"), "text/html; charset=utf-8"));
app.MapGet("/login.html", async context => await SendFile(context, Path.Combine(commonDir, "templates", "login.html"), "text/html; charset=utf-8"));
app.MapGet("/signup.html", async context => await SendFile(context, Path.Combine(commonDir, "templates", "signup.html"), "text/html; charset=utf-8"));
app.MapGet("/dashboard.html", async context => await SendFile(context, Path.Combine(commonDir, "templates", "dashboard.html"), "text/html; charset=utf-8"));
app.MapGet("/upload.html", async context => await SendFile(context, Path.Combine(commonDir, "templates", "upload.html"), "text/html; charset=utf-8"));
app.MapGet("/upload", async context => await SendFile(context, Path.Combine(commonDir, "templates", "upload.html"), "text/html; charset=utf-8"));

app.MapGet("/styles.css", async context => await SendFile(context, Path.Combine(commonDir, "public", "styles.css"), "text/css; charset=utf-8"));
app.MapGet("/secutrace.png", async context => await SendFile(context, Path.Combine(commonDir, "public", "secutrace.png"), "image/png"));
app.MapGet("/login.js", async context => await SendFile(context, Path.Combine(commonDir, "public", "login.js"), "application/javascript; charset=utf-8"));
app.MapGet("/signup.js", async context => await SendFile(context, Path.Combine(commonDir, "public", "signup.js"), "application/javascript; charset=utf-8"));
app.MapGet("/dashboard.js", async context => await SendFile(context, Path.Combine(commonDir, "public", "dashboard.js"), "application/javascript; charset=utf-8"));
app.MapGet("/upload.js", async context => await SendFile(context, Path.Combine(commonDir, "public", "upload.js"), "application/javascript; charset=utf-8"));
app.MapGet("/uploads/{name}", async (HttpContext context, string name) => await SendFile(context, Path.Combine(uploadDir, CleanFilename(name)), "application/octet-stream"));

app.MapGet("/health", () => Results.Json(new { ok = true, runtime, uploadPath = uploadDir, uploadExecutable }));

app.MapPost("/api/signup", async (HttpContext context) =>
{
    var body = await JsonSerializer.DeserializeAsync<Dictionary<string, string>>(context.Request.Body) ?? new();
    var username = body.GetValueOrDefault("username", "").Trim();
    if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(body.GetValueOrDefault("password", "")))
    {
        return Results.BadRequest(new { success = false, message = "Username and password are required." });
    }
    return Results.Json(new { success = true, message = "Signup complete" });
});

app.MapPost("/api/login", async (HttpContext context) =>
{
    var body = await JsonSerializer.DeserializeAsync<Dictionary<string, string>>(context.Request.Body) ?? new();
    var username = body.GetValueOrDefault("username", "").Trim();
    if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(body.GetValueOrDefault("password", "")))
    {
        return Results.BadRequest(new { success = false, message = "Username and password are required." });
    }
    return Results.Json(new { success = true, token = TokenFor(username) });
});

app.MapGet("/api/dashboard", (HttpContext context) =>
{
    var username = UsernameFromToken(context);
    if (string.IsNullOrWhiteSpace(username))
    {
        return Results.Json(new { success = false, message = "Authentication required" }, statusCode: StatusCodes.Status401Unauthorized);
    }
    return Results.Json(new { success = true, username });
});

app.MapPost("/upload", async (HttpContext context) =>
{
    var form = await context.Request.ReadFormAsync();
    var file = form.Files.GetFile("file");
    if (file is null) return Results.BadRequest(new { success = false, message = "file field is required" });

    var storedName = CleanFilename(file.FileName);
    var storedPath = Path.Combine(uploadDir, storedName);
    await using (var output = File.Create(storedPath)) await file.CopyToAsync(output);
    ApplyExecutableUploadPermissions(storedPath, uploadExecutable);

    var uploadEvent = new
    {
        runtime,
        originalName = file.FileName,
        storedName,
        storedPath,
        size = new FileInfo(storedPath).Length,
        mimeType = file.ContentType,
        sha256 = Sha256(storedPath),
        uploadedAt = DateTimeOffset.UtcNow,
        remoteAddress = context.Connection.RemoteIpAddress?.ToString() ?? "",
    };

    await File.AppendAllTextAsync(Path.Combine(logDir, "upload-events.jsonl"), JsonSerializer.Serialize(uploadEvent) + Environment.NewLine);
    return Results.Json(new { success = true, file = uploadEvent });
});

app.MapGet("/files", () =>
{
    var files = Directory.GetFiles(uploadDir)
        .Select(path => new FileInfo(path))
        .OrderBy(file => file.Name)
        .Select(file => new
        {
            name = file.Name,
            size = file.Length,
            modifiedAt = file.LastWriteTimeUtc,
            url = $"/uploads/{Uri.EscapeDataString(file.Name)}",
        });
    return Results.Json(new { runtime, files });
});

app.Run();
