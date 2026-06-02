#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
	logPrint("========== SEBZ RUST SNIPERS ONLY LOADED ==========" + "\n");
	SetDvarIfUninitialized("rso_default_sniper", "cheytac_xmags_mp");
	setDvar("scr_game_perks", "1");
	setDvar("scr_game_deathstreaks", "0");
	level thread rso_on_connect();
}

rso_on_connect()
{
	for (;;)
	{
		level waittill("connected", player);
		player.rsoSniper = getDvar("rso_default_sniper");
		player thread rso_spawn_loop();
		player thread rso_weapon_change_loop();
		player thread rso_ammo_lock_loop();
		player thread rso_perk_lock_loop();
	}
}

rso_spawn_loop()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("spawned_player");
		wait 0.20;

		if (!isAlive(self))
			continue;

		self rso_apply_loadout();
	}
}

rso_weapon_change_loop()
{
	self endon("disconnect");

	for (;;)
	{
		self waittill("weapon_change", weapon);
		wait 0.05;

		if (!isAlive(self))
			continue;

		self rso_enforce_weapon(weapon);
	}
}

rso_ammo_lock_loop()
{
	self endon("disconnect");

	for (;;)
	{
		wait 0.35;

		if (!isAlive(self))
			continue;

		self setWeaponAmmoClip("beretta_mp", 0);
		self setWeaponAmmoStock("beretta_mp", 0);
	}
}

rso_apply_loadout()
{
	selectedSniper = self rso_get_selected_sniper();

	if (isDefined(selectedSniper) && selectedSniper != "")
		self.rsoSniper = selectedSniper;
	else
		self.rsoSniper = getDvar("rso_default_sniper");

	self takeAllWeapons();
	self rso_enforce_perks();
	self giveWeapon(self.rsoSniper);
	self giveWeapon("beretta_mp");
	self switchToWeapon(self.rsoSniper);
	self setWeaponAmmoClip("beretta_mp", 0);
	self setWeaponAmmoStock("beretta_mp", 0);
}

rso_get_selected_sniper()
{
	primaries = self getWeaponsListPrimaries();

	for (i = 0; i < primaries.size; i++)
	{
		if (self rso_is_sniper(primaries[i]))
			return primaries[i];
	}

	currentWeapon = self getCurrentWeapon();

	if (isDefined(currentWeapon) && self rso_is_sniper(currentWeapon))
		return currentWeapon;

	return "";
}

rso_enforce_weapon(weapon)
{
	if (!isDefined(weapon) || weapon == "" || weapon == "none")
		return;

	if (self rso_is_sniper(weapon))
	{
		self.rsoSniper = weapon;
		return;
	}

	if (weapon == "beretta_mp")
	{
		self setWeaponAmmoClip("beretta_mp", 0);
		self setWeaponAmmoStock("beretta_mp", 0);
		return;
	}

	if (self rso_is_allowed_killstreak_or_equipment(weapon))
		return;

	logPrint("RSO WEAPON LOCK: player=" + self.name + " removed=" + weapon + "\n");
	self rso_apply_loadout();
}

rso_is_sniper(weapon)
{
	if (!isDefined(weapon))
		return false;

	parts = strTok(weapon, "_");

	if (parts.size <= 0)
		return false;

	base = parts[0];

	return base == "cheytac" || base == "barrett" || base == "wa2000" || base == "m21";
}

rso_perk_lock_loop()
{
	self endon("disconnect");

	for (;;)
	{
		wait 0.75;

		if (!isAlive(self))
			continue;

		self rso_enforce_perks();
	}
}

rso_enforce_perks()
{
	self setPerk("specialty_fastreload");
	self setPerk("specialty_bulletdamage");
	self rso_clear_deathstreak_perks();
}

rso_clear_deathstreak_perks()
{
	self unsetPerk("specialty_copycat");
	self unsetPerk("specialty_painkiller");
	self unsetPerk("specialty_grenadepulldeath");
	self unsetPerk("specialty_finalstand");
	self unsetPerk("specialty_laststand");
	self unsetPerk("specialty_c4death");
}

rso_is_allowed_killstreak_or_equipment(weapon)
{
	if (!isDefined(weapon))
		return false;

	if (isSubStr(weapon, "uav") || isSubStr(weapon, "airdrop") || isSubStr(weapon, "predator"))
		return true;

	if (isSubStr(weapon, "ac130") || isSubStr(weapon, "helicopter") || isSubStr(weapon, "harrier"))
		return true;

	if (isSubStr(weapon, "sentry") || isSubStr(weapon, "airstrike") || isSubStr(weapon, "emp"))
		return true;

	if (isSubStr(weapon, "nuke") || isSubStr(weapon, "remote") || isSubStr(weapon, "cobra"))
		return true;

	return false;
}
