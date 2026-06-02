using Data.Models.Client;
using SharedLibraryCore;
using SharedLibraryCore.Commands;
using SharedLibraryCore.Configuration;
using SharedLibraryCore.Interfaces;

namespace SebzGscBridge.Commands;

public sealed class EspCommand : Command
{
    private const string RequestDvarName = "sebz_esp_request";

    public EspCommand(CommandConfiguration config, ITranslationLookup translationLookup)
        : base(config, translationLookup)
    {
        Name = "esp";
        Alias = "wh";
        Description = "Toggle the Sebz ESP observer overlay for yourself";
        Permission = EFClient.Permission.SeniorAdmin;
        RequiresTarget = false;
        Arguments = [];
    }

    public override async Task ExecuteAsync(GameEvent gameEvent)
    {
        if (gameEvent.Owner is null)
        {
            gameEvent.Origin.Tell("ESP is only available from an active game server.");
            return;
        }

        var guid = unchecked((ulong)gameEvent.Origin.NetworkId).ToString("x16");
        var request = $"{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}:{guid}:{gameEvent.Origin.ClientNumber}";

        await gameEvent.Owner.ExecuteCommandAsync($"set {RequestDvarName} \"{request}\"", CancellationToken.None);
        gameEvent.Origin.Tell("ESP toggle sent.");
    }
}
