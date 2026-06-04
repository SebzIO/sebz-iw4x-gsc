#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
    SetDvarIfUninitialized("sebz_watch_request", "");
    SetDvarIfUninitialized("sebz_watch_debug", 0);

    level.sebzWatchLastRequest = "";
    level thread SebzWatchMonitorRequests();
}

SebzWatchMonitorRequests()
{
    for (;;)
    {
        request = getDvar("sebz_watch_request");

        if (request != "" && request != level.sebzWatchLastRequest)
        {
            level.sebzWatchLastRequest = request;
            level thread SebzWatchHandleRequest(request);
            setDvar("sebz_watch_request", "");
        }

        wait 0.25;
    }
}

SebzWatchHandleRequest(request)
{
    if (getDvarInt("sebz_watch_debug"))
        printLn("[sebz_watch] request " + request);

    parts = strTok(request, ":");
    if (parts.size < 5)
        return;

    observerGuid = toLower(parts[1]);
    observerSlot = int(parts[2]);
    targetGuid = toLower(parts[3]);
    targetSlot = int(parts[4]);

    observer = SebzWatchFindPlayer(observerSlot, observerGuid);
    target = SebzWatchFindPlayer(targetSlot, targetGuid);

    if (!isDefined(observer) || !isDefined(target))
    {
        if (getDvarInt("sebz_watch_debug"))
            printLn("[sebz_watch] player match failed for request " + request);

        return;
    }

    observer thread SebzWatchToggleTarget(target);
}

SebzWatchFindPlayer(slot, guid)
{
    player = SebzWatchFindPlayerBySlot(slot);
    if (isDefined(player))
        return player;

    return SebzWatchFindPlayerByGuid(guid);
}

SebzWatchFindPlayerBySlot(slot)
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

SebzWatchFindPlayerByGuid(guid)
{
    foreach (player in level.players)
    {
        if (isDefined(player.guid) && toLower(player.guid) == guid)
            return player;
    }

    return undefined;
}

SebzWatchToggleTarget(target)
{
    if (!isDefined(self.sebzWatch))
        self.sebzWatch = spawnStruct();

    if (isDefined(self.sebzWatch.active) && self.sebzWatch.active &&
        isDefined(self.sebzWatch.target) && self.sebzWatch.target == target)
    {
        self SebzWatchDisable();
        self iPrintlnBold("^1Spectator toolkit disabled");
        return;
    }

    self SebzWatchEnable(target);
    self iPrintlnBold("^2Spectator toolkit: ^7" + target.name);
}

SebzWatchEnable(target)
{
    self SebzWatchDisable();

    self.sebzWatch.active = true;
    self.sebzWatch.target = target;
    self.sebzWatch.marker = self createIcon("objpoint_default", 24, 24);
    self.sebzWatch.marker.hidewheninmenu = true;
    self.sebzWatch.marker.foreground = true;
    self.sebzWatch.marker.archived = false;
    self.sebzWatch.marker.sort = 20;
    self.sebzWatch.marker.alpha = 1;
    self.sebzWatch.marker.color = (1, 0.86, 0.08);
    self.sebzWatch.marker setWaypoint(false, false);
    self.sebzWatch.marker setTargetEnt(target);

    self.sebzWatch.panel = self createFontString("objective", 1.35);
    self.sebzWatch.panel setPoint("TOPRIGHT", "TOPRIGHT", -10, 82);
    self.sebzWatch.panel.hidewheninmenu = true;
    self.sebzWatch.panel.foreground = true;
    self.sebzWatch.panel.archived = false;
    self.sebzWatch.panel.sort = 21;
    self.sebzWatch.panel.alpha = 0.95;
    self.sebzWatch.panel.color = (1, 1, 1);

    self thread SebzWatchUpdateLoop(target);
    self thread SebzWatchTargetDisconnect(target);
}

SebzWatchDisable()
{
    self notify("sebz_watch_disable");

    if (isDefined(self.sebzWatch))
    {
        self.sebzWatch.active = false;

        if (isDefined(self.sebzWatch.marker))
            self.sebzWatch.marker destroy();

        if (isDefined(self.sebzWatch.panel))
            self.sebzWatch.panel destroy();

        self.sebzWatch.target = undefined;
        self.sebzWatch.marker = undefined;
        self.sebzWatch.panel = undefined;
    }
}

SebzWatchUpdateLoop(target)
{
    self endon("disconnect");
    self endon("sebz_watch_disable");
    target endon("disconnect");

    for (;;)
    {
        if (!isDefined(self.sebzWatch) || !isDefined(self.sebzWatch.panel))
            return;

        if (!isDefined(target))
        {
            self SebzWatchDisable();
            return;
        }

        self.sebzWatch.panel _setText(self SebzWatchPanelText(target));
        wait 0.5;
    }
}

SebzWatchTargetDisconnect(target)
{
    self endon("disconnect");
    self endon("sebz_watch_disable");
    target waittill("disconnect");

    self SebzWatchDisable();
    self iPrintlnBold("^1Spectator toolkit target disconnected");
}

SebzWatchPanelText(target)
{
    text = "^3WATCH^7 " + target.name;
    text += "\n^7Team: ^5" + SebzWatchTeamName(target);
    text += "\n^7State: ^5" + SebzWatchLifeState(target);
    text += "\n^7Weapon: ^5" + SebzWatchWeaponName(target);
    text += "\n^7Health: ^5" + SebzWatchHealthText(target);

    return text;
}

SebzWatchTeamName(player)
{
    if (!isDefined(player.team))
        return "unknown";

    return player.team;
}

SebzWatchLifeState(player)
{
    if (isAlive(player))
        return "alive";

    if (isDefined(player.sessionstate))
        return player.sessionstate;

    return "dead";
}

SebzWatchWeaponName(player)
{
    weapon = player getCurrentWeapon();

    if (!isDefined(weapon) || weapon == "")
        return "none";

    return weapon;
}

SebzWatchHealthText(player)
{
    if (!isDefined(player.health))
        return "unknown";

    return player.health;
}

_setText(text)
{
    self setText(text);
    self.string = text;
}
