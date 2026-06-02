#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
    SetDvarIfUninitialized("sebz_esp_request", "");
    SetDvarIfUninitialized("sebz_esp_debug", 0);

    level.sebzEspLastRequest = "";
    level thread SebzEspMonitorRequests();
}

SebzEspMonitorRequests()
{
    for (;;)
    {
        request = getDvar("sebz_esp_request");

        if (request != "" && request != level.sebzEspLastRequest)
        {
            level.sebzEspLastRequest = request;
            level thread SebzEspHandleRequest(request);
            setDvar("sebz_esp_request", "");
        }

        wait 0.25;
    }
}

SebzEspHandleRequest(request)
{
    if (getDvarInt("sebz_esp_debug"))
        printLn("[sebz_esp] request " + request);

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

    player = SebzEspFindPlayerBySlot(slot);
    if (!isDefined(player))
        player = SebzEspFindPlayerByGuid(guid);

    if (isDefined(player))
    {
        if (getDvarInt("sebz_esp_debug"))
            printLn("[sebz_esp] matched " + player.name + " guid " + player.guid + " slot " + player getEntityNumber());

        player thread SebzEspToggle();
    }
    else if (getDvarInt("sebz_esp_debug"))
    {
        printLn("[sebz_esp] no player matched guid " + guid + " slot " + slot);
    }
}

SebzEspFindPlayerBySlot(slot)
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

SebzEspFindPlayerByGuid(guid)
{
    foreach (player in level.players)
    {
        if (isDefined(player.guid) && toLower(player.guid) == guid)
            return player;
    }

    return undefined;
}

SebzEspToggle()
{
    if (!isDefined(self.sebzEsp))
        self.sebzEsp = spawnStruct();

    if (!isDefined(self.sebzEsp.active) || !self.sebzEsp.active)
    {
        self SebzEspEnable();
        self.sebzEsp.active = true;
        if (getDvarInt("sebz_esp_debug"))
            self iPrintlnBold("^2ESP enabled");
    }
    else
    {
        self SebzEspDisable();
        self.sebzEsp.active = false;
        if (getDvarInt("sebz_esp_debug"))
            self iPrintlnBold("^1ESP disabled");
    }
}

SebzEspEnable()
{
    self SebzEspDisable();
    self.sebzEsp.icons = [];

    self thread SebzEspWatchDisable();
    self thread SebzEspWatchNewPlayers();
    self thread SebzEspWatchTeamChange();

    foreach (target in level.players)
    {
        self SebzEspAddTarget(target);
    }

    if (getDvarInt("sebz_esp_debug"))
        printLn("[sebz_esp] enabled for " + self.name + " with " + self.sebzEsp.icons.size + " icons");
}

SebzEspDisable()
{
    self notify("sebz_esp_disable");

    if (isDefined(self.sebzEsp) && isDefined(self.sebzEsp.icons))
    {
        foreach (icon in self.sebzEsp.icons)
        {
            if (isDefined(icon))
                icon destroy();
        }

        self.sebzEsp.icons = [];
    }
}

SebzEspWatchDisable()
{
    self endon("disconnect");

    self waittill("sebz_esp_disable");
}

SebzEspWatchNewPlayers()
{
    self endon("disconnect");
    self endon("sebz_esp_disable");

    for (;;)
    {
        level waittill("connected", player);
        if (player != self)
            self SebzEspAddTarget(player);
    }
}

SebzEspWatchTeamChange()
{
    self endon("disconnect");
    self endon("sebz_esp_disable");

    for (;;)
    {
        self SebzEspWaittillAny("joined_team", "joined_spectators");
        self SebzEspEnable();
    }
}

SebzEspAddTarget(target)
{
    if (!isDefined(target))
        return;

    icon = self createIcon("objpoint_default", 18, 18);
    icon.hidewheninmenu = true;
    icon.foreground = true;
    icon.archived = false;
    icon.sort = 10;
    icon.alpha = 0.9;
    icon.color = self SebzEspColorForTarget(target);
    icon setWaypoint(false, false);
    icon setTargetEnt(target);

    self.sebzEsp.icons[self.sebzEsp.icons.size] = icon;
    self thread SebzEspWatchTarget(icon, target);
}

SebzEspWatchTarget(icon, target)
{
    self endon("disconnect");
    self endon("sebz_esp_disable");
    target endon("disconnect");

    target SebzEspWaittillAny("joined_team", "joined_spectators");

    if (isDefined(icon))
        icon destroy();

    self SebzEspAddTarget(target);
}

SebzEspColorForTarget(target)
{
    if (target == self)
        return (0.17, 0.96, 1);

    if (self SebzEspIsTeammate(target))
        return (0.05, 0.79, 0.29);

    return (1, 0.29, 0.29);
}

SebzEspIsTeammate(player)
{
    if (!isDefined(player.team) || !isDefined(self.team))
        return false;

    if (self.team != "allies" && self.team != "axis")
        return false;

    if (player.team != "allies" && player.team != "axis")
        return false;

    if (!level.teamBased)
        return false;

    return player.team == self.team;
}

SebzEspWaittillAny(a, b)
{
    self endon(a);
    self endon(b);
    level waittill("sebz_esp_never");
}
