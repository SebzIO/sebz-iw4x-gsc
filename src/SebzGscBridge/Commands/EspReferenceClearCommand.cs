using Data.Models.Client;
using SharedLibraryCore;
using SharedLibraryCore.Commands;
using SharedLibraryCore.Configuration;
using SharedLibraryCore.Interfaces;

namespace SebzGscBridge.Commands;

public sealed class EspReferenceClearCommand : Command
{
    private const string RequestDvarName = "sebz_esp_reference_request";

    public EspReferenceClearCommand(CommandConfiguration config, ITranslationLookup translationLookup)
        : base(config, translationLookup)
    {
        Name = "whclear";
        Alias = "espclear";
        Description = "Clear your ESP team color reference player";
        Permission = EFClient.Permission.SeniorAdmin;
        RequiresTarget = false;
        Arguments = [];
    }

    public override async Task ExecuteAsync(GameEvent gameEvent)
    {
        if (gameEvent.Owner is null)
        {
            gameEvent.Origin.Tell("ESP reference is only available from an active game server.");
            return;
        }

        var originGuid = unchecked((ulong)gameEvent.Origin.NetworkId).ToString("x16");
        var request = string.Join(
            ':',
            DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(),
            originGuid,
            gameEvent.Origin.ClientNumber,
            "clear",
            "0",
            -1);

        await gameEvent.Owner.ExecuteCommandAsync($"set {RequestDvarName} \"{request}\"", CancellationToken.None);
        gameEvent.Origin.Tell("ESP reference clear sent.");
    }
}
