using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using SebzGscBridge.Commands;
using SharedLibraryCore.Interfaces;
using SharedLibraryCore.Interfaces.Events;

namespace SebzGscBridge;

public sealed class Plugin : IPluginV2
{
    private readonly ILogger<Plugin> _logger;

    public string Name => "Sebz GSC Bridge";

    public string Author => "Sebz";

    public string Version => "0.1.0";

    public Plugin(ILogger<Plugin> logger)
    {
        _logger = logger;
        IManagementEventSubscriptions.Load += OnLoad;
    }

    public static void RegisterDependencies(IServiceCollection serviceCollection)
    {
        serviceCollection.AddSingleton<IManagerCommand, EspCommand>();
        serviceCollection.AddSingleton<IManagerCommand, EspReferenceCommand>();
        serviceCollection.AddSingleton<IManagerCommand, EspReferenceClearCommand>();
        serviceCollection.AddSingleton<IManagerCommand, VisibilityCommand>();
        serviceCollection.AddSingleton<IManagerCommand, WatchCommand>();
    }

    private Task OnLoad(IManager manager, CancellationToken token)
    {
        _logger.LogInformation(
            "Sebz GSC Bridge loaded for IW4MAdmin {Version} with {ServerCount} server(s)",
            manager.Version,
            manager.GetServers().Count);
        return Task.CompletedTask;
    }

    public void Dispose()
    {
        IManagementEventSubscriptions.Load -= OnLoad;
        _logger.LogInformation("Sebz GSC Bridge unloaded");
    }
}
