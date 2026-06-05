using Data.Models.Client;
using SharedLibraryCore;
using SharedLibraryCore.Commands;
using SharedLibraryCore.Configuration;
using SharedLibraryCore.Interfaces;

namespace SebzGscBridge.Commands;

public sealed class EspReferenceCommand : Command
{
    private const string RequestDvarName = "sebz_esp_reference_request";

    public EspReferenceCommand(CommandConfiguration config, ITranslationLookup translationLookup)
        : base(config, translationLookup)
    {
        Name = "whref";
        Alias = "espref";
        Description = "Set the ESP team color reference player for yourself";
        Permission = EFClient.Permission.SeniorAdmin;
        RequiresTarget = true;
        Arguments =
        [
            new CommandArgument
            {
                Name = "player",
                Required = true
            }
        ];
    }

    public override async Task ExecuteAsync(GameEvent gameEvent)
    {
        if (gameEvent.Owner is null)
        {
            gameEvent.Origin.Tell("ESP reference is only available from an active game server.");
            return;
        }

        if (gameEvent.Target is null)
        {
            gameEvent.Origin.Tell("No target player was found.");
            return;
        }

        var originGuid = unchecked((ulong)gameEvent.Origin.NetworkId).ToString("x16");
        var targetGuid = unchecked((ulong)gameEvent.Target.NetworkId).ToString("x16");
        var request = string.Join(
            ':',
            DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(),
            originGuid,
            gameEvent.Origin.ClientNumber,
            "set",
            targetGuid,
            gameEvent.Target.ClientNumber);

        await gameEvent.Owner.ExecuteCommandAsync($"set {RequestDvarName} \"{request}\"", CancellationToken.None);
        gameEvent.Origin.Tell($"ESP reference sent for {gameEvent.Target.Name}.");
    }
}
