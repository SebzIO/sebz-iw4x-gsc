#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
    SetDvarIfUninitialized("sebz_esp_request", "");
    SetDvarIfUninitialized("sebz_esp_reference_request", "");
    SetDvarIfUninitialized("sebz_esp_debug", 0);

    level.sebzEspLastRequest = "";
    level.sebzEspLastReferenceRequest = "";
    level thread SebzEspMonitorRequests();
    level thread SebzEspMonitorReferenceRequests();
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

SebzEspMonitorReferenceRequests()
{
    for (;;)
    {
        request = getDvar("sebz_esp_reference_request");

        if (request != "" && request != level.sebzEspLastReferenceRequest)
        {
            level.sebzEspLastReferenceRequest = request;
            level thread SebzEspHandleReferenceRequest(request);
            setDvar("sebz_esp_reference_request", "");
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

SebzEspHandleReferenceRequest(request)
{
    if (getDvarInt("sebz_esp_debug"))
        printLn("[sebz_esp] reference request " + request);

    parts = strTok(request, ":");
    if (parts.size < 6)
        return;

    observerGuid = toLower(parts[1]);
    observerSlot = int(parts[2]);
    action = parts[3];
    targetGuid = toLower(parts[4]);
    targetSlot = int(parts[5]);

    observer = SebzEspFindPlayer(observerSlot, observerGuid);
    if (!isDefined(observer))
        return;

    if (!isDefined(observer.sebzEsp))
        observer.sebzEsp = spawnStruct();

    if (action == "clear")
    {
        observer.sebzEsp.reference = undefined;
        observer iPrintlnBold("^1ESP reference cleared");
        return;
    }

    target = SebzEspFindPlayer(targetSlot, targetGuid);
    if (!isDefined(target))
    {
        observer iPrintlnBold("^1ESP reference target not found");
        return;
    }

    observer.sebzEsp.reference = target;
    observer iPrintlnBold("^2ESP reference: ^7" + target.name);
}

SebzEspFindPlayer(slot, guid)
{
    player = SebzEspFindPlayerBySlot(slot);
    if (isDefined(player))
        return player;

    return SebzEspFindPlayerByGuid(guid);
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
    self thread SebzEspDebugPanel();

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

    if (isDefined(self.sebzEsp) && isDefined(self.sebzEsp.debugPanel))
    {
        self.sebzEsp.debugPanel destroy();
        self.sebzEsp.debugPanel = undefined;
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

    for (;;)
    {
        if (!isDefined(icon))
            return;

        icon.color = self SebzEspColorForTarget(target);
        wait 0.25;
    }
}

SebzEspColorForTarget(target)
{
    if (target == self)
        return (0.17, 0.96, 1);

    reference = self SebzEspTeamReferencePlayer();

    if (isDefined(reference) && target == reference)
        return (0.17, 0.96, 1);

    if (self SebzEspIsTeammate(target, reference))
        return (0.05, 0.79, 0.29);

    return (1, 0.29, 0.29);
}

SebzEspTeamReferencePlayer()
{
    if (isDefined(self.sebzEsp) && isDefined(self.sebzEsp.reference))
        return self.sebzEsp.reference;

    if (isDefined(self.spectatorclient) && self.spectatorclient >= 0)
    {
        player = SebzEspFindPlayerBySlot(self.spectatorclient);
        if (isDefined(player) && player != self)
            return player;
    }

    return self;
}

SebzEspDebugPanel()
{
    self endon("disconnect");
    self endon("sebz_esp_disable");

    for (;;)
    {
        if (!getDvarInt("sebz_esp_debug"))
        {
            if (isDefined(self.sebzEsp.debugPanel))
            {
                self.sebzEsp.debugPanel destroy();
                self.sebzEsp.debugPanel = undefined;
            }

            wait 0.5;
            continue;
        }

        if (!isDefined(self.sebzEsp.debugPanel))
        {
            self.sebzEsp.debugPanel = self createFontString("objective", 1.15);
            self.sebzEsp.debugPanel setPoint("TOPLEFT", "TOPLEFT", 10, 110);
            self.sebzEsp.debugPanel.hidewheninmenu = true;
            self.sebzEsp.debugPanel.foreground = true;
            self.sebzEsp.debugPanel.archived = false;
            self.sebzEsp.debugPanel.sort = 30;
            self.sebzEsp.debugPanel.alpha = 0.9;
            self.sebzEsp.debugPanel.color = (1, 1, 1);
        }

        reference = self SebzEspTeamReferencePlayer();
        referenceText = "self";
        if (isDefined(reference) && reference != self)
            referenceText = reference.name + " #" + reference getEntityNumber() + " " + SebzEspFieldText(reference.team);

        self.sebzEsp.debugPanel setText(
            "^3ESP debug"
            + "\n^7team: ^5" + SebzEspFieldText(self.team)
            + " ^7session: ^5" + SebzEspFieldText(self.sessionstate)
            + "\n^7spectatorclient: ^5" + SebzEspFieldText(self.spectatorclient)
            + "\n^7reference: ^5" + referenceText);

        wait 0.25;
    }
}

SebzEspFieldText(value)
{
    if (!isDefined(value))
        return "undefined";

    return value;
}

SebzEspIsTeammate(player, reference)
{
    if (!isDefined(reference))
        reference = self;

    if (!isDefined(player.team) || !isDefined(reference.team))
        return false;

    if (reference.team != "allies" && reference.team != "axis")
        return false;

    if (player.team != "allies" && player.team != "axis")
        return false;

    if (!level.teamBased)
        return false;

    return player.team == reference.team;
}

SebzEspWaittillAny(a, b)
{
    self endon(a);
    self endon(b);
    level waittill("sebz_esp_never");
}
