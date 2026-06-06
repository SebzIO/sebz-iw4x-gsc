#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
    SetDvarIfUninitialized("sebz_visibility_request", "");
    SetDvarIfUninitialized("sebz_visibility_debug", 0);

    level.sebzVisibilityLastRequest = "";
    level thread SebzVisibilityMonitorRequests();
    level thread SebzVisibilityOnConnect();
}

SebzVisibilityOnConnect()
{
    for (;;)
    {
        level waittill("connected", player);
        player thread SebzVisibilitySetupPlayer();
    }
}

SebzVisibilitySetupPlayer()
{
    self endon("disconnect");

    if (!isDefined(self.sebzVisibility))
    {
        self.sebzVisibility = spawnStruct();
        self.sebzVisibility.active = false;
    }

    self notifyOnPlayerCommand("sebz_visibility_key", "+actionslot 4");
    self thread SebzVisibilityKeyMonitor();
    self thread SebzVisibilitySpawnMonitor();
}

SebzVisibilityKeyMonitor()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("sebz_visibility_key");
        self SebzVisibilityToggle();
        wait 0.35;
    }
}

SebzVisibilitySpawnMonitor()
{
    self endon("disconnect");

    for (;;)
    {
        self waittill("spawned_player");
        wait 0.20;

        if (isDefined(self.sebzVisibility) && self.sebzVisibility.active)
            self SebzVisibilityApplyClear();
    }
}

SebzVisibilityMonitorRequests()
{
    for (;;)
    {
        request = getDvar("sebz_visibility_request");

        if (request != "" && request != level.sebzVisibilityLastRequest)
        {
            level.sebzVisibilityLastRequest = request;
            level thread SebzVisibilityHandleRequest(request);
            setDvar("sebz_visibility_request", "");
        }

        wait 0.25;
    }
}

SebzVisibilityHandleRequest(request)
{
    if (getDvarInt("sebz_visibility_debug"))
        printLn("[sebz_visibility] request " + request);

    parts = strTok(request, ":");
    if (parts.size < 2)
        return;

    guid = toLower(parts[parts.size - 1]);
    slot = -1;
    if (parts.size >= 3)
    {
        guid = toLower(parts[1]);
        slot = int(parts[2]);
    }

    player = SebzVisibilityFindPlayerBySlot(slot);
    if (!isDefined(player))
        player = SebzVisibilityFindPlayerByGuid(guid);

    if (isDefined(player))
        player SebzVisibilityToggle();
    else if (getDvarInt("sebz_visibility_debug"))
        printLn("[sebz_visibility] no player matched guid " + guid + " slot " + slot);
}

SebzVisibilityFindPlayerBySlot(slot)
{
    if (slot < 0)
        return undefined;

    foreach (player in level.players)
    {
        if (player getEntityNumber() == slot)
            return player;
    }

    return undefined;
}

SebzVisibilityFindPlayerByGuid(guid)
{
    foreach (player in level.players)
    {
        if (isDefined(player.guid) && toLower(player.guid) == guid)
            return player;
    }

    return undefined;
}

SebzVisibilityToggle()
{
    if (!isDefined(self.sebzVisibility))
    {
        self.sebzVisibility = spawnStruct();
        self.sebzVisibility.active = false;
    }

    if (!self.sebzVisibility.active)
    {
        self.sebzVisibility.active = true;
        self SebzVisibilityApplyClear();
        self iPrintlnBold("^2Clear visibility enabled");
    }
    else
    {
        self.sebzVisibility.active = false;
        self SebzVisibilityApplyDefault();
        self iPrintlnBold("^1Clear visibility disabled");
    }
}

SebzVisibilityApplyClear()
{
    self setClientDvar("r_fog", "0");
    self setClientDvar("r_fullbright", "1");
    self setClientDvar("r_glow", "0");
    self setClientDvar("r_distortion", "0");
}

SebzVisibilityApplyDefault()
{
    self setClientDvar("r_fog", "1");
    self setClientDvar("r_fullbright", "0");
    self setClientDvar("r_glow", "1");
    self setClientDvar("r_distortion", "1");
}
