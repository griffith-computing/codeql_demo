using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace CodeQLDemo.Api.Tests;

public sealed class ApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient client;

    public ApiTests(WebApplicationFactory<Program> factory)
    {
        client = factory.CreateClient();
    }

    [Fact]
    public async Task RootDescribesTheDemo()
    {
        var response = await client.GetAsync("/");
        var info = await response.Content.ReadFromJsonAsync<DemoInfo>();

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(info);
        Assert.Equal("CodeQL .NET 10 Demo", info.Name);
        Assert.Contains("Intentionally vulnerable", info.Warning);
    }

    [Fact]
    public async Task HealthEndpointIsAvailable()
    {
        var response = await client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
