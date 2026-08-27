using System.Threading.Tasks;

namespace QueryFixtures;

public sealed class BadExamples
{
    public async void SaveAsync()
    {
        await Task.Delay(1);
    }
}

