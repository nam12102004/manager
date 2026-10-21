using DebtManager.Application.Interfaces;

namespace DebtManager.Api.Services;

public class ExportBackgroundWorker : BackgroundService
{
    private readonly IBackgroundTaskQueue _taskQueue;
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<ExportBackgroundWorker> _logger;

    public ExportBackgroundWorker(
        IBackgroundTaskQueue taskQueue,
        IServiceProvider serviceProvider,
        ILogger<ExportBackgroundWorker> logger)
    {
        _taskQueue = taskQueue;
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Export Background Worker is starting.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                var workItem = await _taskQueue.DequeueAsync(stoppingToken);

                using var scope = _serviceProvider.CreateScope();
                await workItem(scope.ServiceProvider, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                // Normal shutdown
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred executing background export task.");
            }
        }

        _logger.LogInformation("Export Background Worker is stopping.");
    }
}
