using System.Diagnostics;
using Microsoft.Data.Sqlite;

namespace CodeQLDemo.Api;

public static class VulnerableEndpoints
{
    public static IResult SearchUsers(HttpRequest request)
    {
        var name = request.Query["name"].ToString();
        using var connection = new SqliteConnection("Data Source=demo.db");
        connection.Open();

        using var command = connection.CreateCommand();
        command.CommandText = $"SELECT Id, Name FROM Users WHERE Name = '{name}'";

        using var reader = command.ExecuteReader();
        var users = new List<object>();
        while (reader.Read())
        {
            users.Add(new { Id = reader.GetInt32(0), Name = reader.GetString(1) });
        }

        return Results.Ok(users);
    }

    public static IResult RunCommand(HttpRequest request)
    {
        var command = request.Query["command"].ToString();
        var startInfo = OperatingSystem.IsWindows()
            ? new ProcessStartInfo("cmd.exe", $"/c {command}")
            : new ProcessStartInfo("/bin/sh", $"-c \"{command}\"");

        startInfo.UseShellExecute = false;
        using var process = Process.Start(startInfo);
        process?.WaitForExit();

        return Results.Ok(new { exitCode = process?.ExitCode });
    }

    public static IResult ReadFile(HttpRequest request)
    {
        var path = request.Query["path"].ToString();
        return Results.Text(File.ReadAllText(path));
    }

    public static async Task<IResult> FetchUrlAsync(
        HttpRequest request,
        IHttpClientFactory httpClientFactory,
        CancellationToken cancellationToken)
    {
        var url = request.Query["url"].ToString();
        var client = httpClientFactory.CreateClient();
        var content = await client.GetStringAsync(url, cancellationToken);
        return Results.Text(content);
    }

    public static IResult RenderHtml(HttpRequest request)
    {
        var name = request.Query["name"].ToString();
        return Results.Content($"<h1>Hello, {name}</h1>", "text/html");
    }

    public static IResult Redirect(HttpRequest request)
    {
        var url = request.Query["url"].ToString();
        return Results.Redirect(url);
    }
}
