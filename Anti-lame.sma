/* Plugin blocks so-called "lame flashes", when a player throws a flash in mid-air from a high surface.
Adjust LAME_VELOCITY and AIR_VELOCITY according to your needs. Plugin as of now works only in awp_rooftops map
Written by Tozaicevas 2017-04-13 <tozaicevas@gmail.com> */

#include <amxmodx>
#include <engine>
#include <csx>
#include <colorchat>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <amxmisc>

#pragma tabsize 0					// block "loose identation" warnings

#define PLUGIN "[Hns] AntiLameFlash"
#define VERSION "1.0"
#define AUTHOR "Tozaicevas"

#define SERVER_PREFIX "MyServer"

#define XO_WEAPON 4
#define m_pPlayer 41

#define LAME_VELOCITY 515			// velocity after which any thrown flash is destroyed
#define AIR_VELOCITY 175			// velocity after which plugin blocks throwing a flash

#define MAX_FLASH_POP 1.6			// max time from flash thrown to explosion
#define MAX_AIRTIME 2.5
#define MIN_HEIGHT 330

#define BLINDED_FULLY 255

#define IsOnLadder(%1) (entity_get_int(%1, EV_INT_movetype) == MOVETYPE_FLY)
#define IsPlayerOnPlayer(%1) ( ( entity_get_int( %1, EV_INT_flags ) & FL_ONGROUND ) \
&& is_user_alive( entity_get_edict( %1, EV_ENT_groundentity ) ) )

const XO_CBASEPLAYERWEAPON = 4;
const m_flNextPrimaryAttack = 46;

new integr[32]
new max_speed[32]
new bool:flashed[33]
new max_distance[32]
new bool:damaged[33]
new grenades[33]

/* BHOP */
new bool:bhopped[32]
new bool:bhop_check[32]

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_flashbang", "HamKnifePrimAttack", 0)

	register_forward(FM_PlayerPreThink, "fwdPlayerPreThink");		// bhop check
}

public grenade_throw(iPlayer, iGrenade, iGrenadeType) {
    if (!is_user_connected(iPlayer))
        return 0;
			new MapName[35]
	new roof[13] = "awp_rooftops"
	get_mapname(MapName, 34)
	if (!equali(roof, MapName) ) {
		return PLUGIN_HANDLED
	}
    if (iGrenadeType == CSW_FLASHBANG && !(get_entity_flags(iPlayer) & FL_ONGROUND) && !IsOnLadder(iPlayer) ) {
		new lameflasher[32]
		get_user_name(iPlayer, lameflasher, 31)
		integr[iPlayer-1] = 0
		max_speed[iPlayer-1] = 0
		max_distance[iPlayer-1] = 0
		bhopped[iPlayer-1] = false
		bhop_check[iPlayer-1] = true

		grenades[iPlayer-1] = iGrenade
		set_task(0.1,"InAir",iPlayer,_,_,"a",15)
	}

    return 1;
}

public InAir(iPlayer, retard[]) {
	new lameflasher[32]
	get_user_name(iPlayer, lameflasher, 31)

	if (entity_get_float(iPlayer, EV_FL_flFallVelocity) > float(max_speed[iPlayer-1]) && integr[iPlayer-1] > 0)
		max_speed[iPlayer-1] = floatround(entity_get_float(iPlayer, EV_FL_flFallVelocity))

	new Float:distanciation = distance_to_ground(iPlayer)
	new realdistance = floatround(distanciation)
	if (realdistance > max_distance[iPlayer-1])
		max_distance[iPlayer-1] = realdistance

	if ((get_entity_flags(iPlayer) & FL_ONGROUND)|| IsOnLadder(iPlayer) || IsPlayerOnPlayer(iPlayer) || bhopped[iPlayer-1]) {
		bhopped[iPlayer-1] = false
		remove_task(iPlayer)
		return PLUGIN_HANDLED;
	}
	if ( (max_speed[iPlayer-1] >= LAME_VELOCITY && max_distance[iPlayer-1] >= MIN_HEIGHT) || max_speed[iPlayer-1] >= LAME_VELOCITY * 1.5) {
		bhop_check[iPlayer-1] = false
		if(pev_valid(grenades[iPlayer-1])) {
			engfunc(EngFunc_RemoveEntity, grenades[iPlayer-1])			// destroy the flash
		}
		LameFlashed(iPlayer)
		remove_task(iPlayer)
	}

	if (integr[iPlayer-1] == 9)
		bhop_check[iPlayer-1] = false

	integr[iPlayer-1] += 1
	return PLUGIN_CONTINUE;
}

public LameFlashed(iPlayer) {
	new lameflasher[32]
	get_user_name(iPlayer, lameflasher, 31)
	client_print(iPlayer, print_center, "Don't throw flashes like that, mate!");
	ColorChat(0,RED,"^3[%s] ^4%s ^3threw a lameflash!", SERVER_PREFIX, lameflasher)

	flashed[iPlayer] = true
	set_task(MAX_FLASH_POP, "NobodyFlashed", iPlayer,_,_,"a", 1)
	damaged[iPlayer] = true

}

public NobodyFlashed(id) {
	flashed[id] = false
}

public HamKnifePrimAttack(iEnt) {
	static id

    // Find out player index
    id = get_pdata_cbase(iEnt, m_pPlayer, XO_WEAPON)
	if (!(get_entity_flags(id) & FL_ONGROUND)  && !IsOnLadder(id) && floatround(entity_get_float(id, EV_FL_flFallVelocity)) >= AIR_VELOCITY ) {
		return HAM_SUPERCEDE
	}
		return HAM_IGNORED
}

Float:distance_to_ground(id)
{
    new Float:start[3], Float:end[3], bool:bDucking;
    entity_get_vector(id, EV_VEC_origin, start);
    bDucking = !!(entity_get_int(id, EV_INT_flags) & FL_DUCKING);
    if( bDucking ) {
        start[2] += 18.0;
    }

    end[0] = start[0];
    end[1] = start[1];
    end[2] = start[2] - 9999.0;

    new ptr = create_tr2();
    engfunc(EngFunc_TraceHull, start, end, IGNORE_MONSTERS, HULL_HUMAN, id, ptr);
    new Float:distance;
    get_tr2(ptr, TR_flFraction, distance);
    free_tr2(ptr);

    distance *= 9999.0;

    return distance;
}

public fwdPlayerPreThink(id) {
	if (!is_user_alive(id) || is_user_bot(id) || bhopped[id-1])
		return FMRES_IGNORED;

	static iFlags, iButtons, iOldButtons;
	iFlags = pev(id, pev_flags);
	iButtons = pev(id, pev_button);
	iOldButtons = pev(id, pev_oldbuttons);

	static iGroundFrames[33]

	if (iFlags & FL_ONGROUND) {
		iGroundFrames[id]++;

		if (iGroundFrames[id] <= 5 && iButtons & IN_JUMP && ~iOldButtons & IN_JUMP) {
			bhopped[id-1] = true
		}
	}
		else {
			if (iGroundFrames[id])
				iGroundFrames[id] = 0;
		}
	return PLUGIN_HANDLED;
}
