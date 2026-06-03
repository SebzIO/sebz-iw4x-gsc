using Data.Models.Client;
using SharedLibraryCore;
using SharedLibraryCore.Commands;
using SharedLibraryCore.Configuration;
using SharedLibraryCore.Interfaces;

namespace SebzGscBridge.Commands;

public sealed class VisibilityCommand : Command
{
    private const string RequestDvarName = "sebz_visibility_request";

    public VisibilityCommand(CommandConfiguration config, ITranslationLookup translationLookup)
        : base(config, translationLookup)
    {
        Name = "vis";
        Alias = "visibility";
        Description = "Toggle clear visibility mode for yourself";
        Permission = EFClient.Permission.User;
        RequiresTarget = false;
        Arguments = [];
    }

    public override async Task ExecuteAsync(GameEvent gameEvent)
    {
        if (gameEvent.Owner is null)
        {
            gameEvent.Origin.Tell("Visibility mode is only available from an active game server.");
            return;
        }

        var guid = unchecked((ulong)gameEvent.Origin.NetworkId).ToString("x16");
        var request = $"{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}:{guid}:{gameEvent.Origin.ClientNumber}";

        await gameEvent.Owner.ExecuteCommandAsync($"set {RequestDvarName} \"{request}\"", CancellationToken.None);
    }
}
