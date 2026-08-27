using System.Threading.Tasks;

namespace QueryFixtures;

public sealed class GoodExamples
{
    public async Task SaveAsync()
    {
        await Task.Delay(1);
    }

    private async void NotifyAsync()
    {
        await Task.Delay(1);
    }
}

