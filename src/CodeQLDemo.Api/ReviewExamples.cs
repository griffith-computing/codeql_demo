namespace CodeQLDemo.Api;

public sealed class ReviewExamples
{
    private int refreshCount;

    public async void RefreshCacheAsync()
    {
        await Task.Delay(10);
        refreshCount++;
    }

    public async Task RefreshCacheSafelyAsync(CancellationToken cancellationToken = default)
    {
        await Task.Delay(10, cancellationToken);
        Interlocked.Increment(ref refreshCount);
    }

    public int ReadRefreshCount()
    {
        lock (this)
        {
            return refreshCount;
        }
    }
}
