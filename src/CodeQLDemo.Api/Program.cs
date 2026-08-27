using CodeQLDemo.Api;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddHttpClient();

var app = builder.Build();

app.MapGet("/", () => Results.Ok(new DemoInfo(
    "CodeQL .NET 10 Demo",
    "Intentionally vulnerable. Use the /demo routes for static analysis only.")));

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

var demo = app.MapGroup("/demo");
demo.MapGet("/sql", VulnerableEndpoints.SearchUsers);
demo.MapGet("/command", VulnerableEndpoints.RunCommand);
demo.MapGet("/file", VulnerableEndpoints.ReadFile);
demo.MapGet("/fetch", VulnerableEndpoints.FetchUrlAsync);
demo.MapGet("/html", VulnerableEndpoints.RenderHtml);
demo.MapGet("/redirect", VulnerableEndpoints.Redirect);

app.Run();

public sealed record DemoInfo(string Name, string Warning);

public partial class Program;
