/* Plugin let's you "dog" other players, so whenever they write something, their
message is changed to a random dog sound {Woof, Bark, Ruff, Arf, Wuff, Hav, Woaf, Gaff}
It also blocks other communication tools (radio commands, name changes)
Written by Tozaicevas <tozaicevas@gmail.com>
*/

#include <amxmodx>
#include <amxmisc>
#include <colorchat>
#include <engine>		// set_speak
#include <cellarray.inc>

#pragma semicolon 1     // requires semicolons

#define PLUGIN "Dog"
#define VERSION "0.1"
#define AUTHOR "Tozaicevas"

#define SERVER_PREFIX "MyServer"

#define FLEVEL ADMIN_LEVEL_F // flag "r"
#define MAX_PLAYERS 32

new bool:Dogged[33];

new g_szDogFile[ 64 ];
new g_szAuthid[ MAX_PLAYERS + 1 ][ 35 ];
new g_iDogged = 0;
new Array:g_aDogData;

new dog_sounds[8][5];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("say", "clcmd_Say");
    register_clcmd("say_team", "clcmd_SayTeam");
    register_clcmd("/dog", "clcmd_Dog", FLEVEL, "<nick, #userid, authid>");     // amount of dogs
    register_clcmd("/undog", "clcmd_UnDog", FLEVEL, "<nick, #userid, authid>");
    register_clcmd("amx_dog", "clcmd_Dog", FLEVEL, "<nick, #userid, authid>");
    register_clcmd("amx_undog", "clcmd_UnDog", FLEVEL, "<nick, #userid, authid>");
    register_clcmd("say /dogs", "clcmd_Dogs", FLEVEL);                          // amount of dogs

    // load dogs from file
    get_datadir( g_szDogFile, charsmax( g_szDogFile ) );
    add( g_szDogFile, charsmax( g_szDogFile ), "/dogs.txt" );

    register_message( get_user_msgid( "SayText" ), "MessageSayText" );		// blocks name change

    g_aDogData = ArrayCreate(35);									        // save steam ids
    copy( g_szAuthid[ 0 ], charsmax( g_szAuthid[ ] ), "SERVER" );

    /* RADIO COMMANDS: */
    register_clcmd( "radio1","radioblock");
    register_clcmd( "radio2","radioblock");
    register_clcmd( "radio3","radioblock");
    register_clcmd( "coverme","radioblock");
    register_clcmd( "takepoint","radioblock");
    register_clcmd( "holdpos","radioblock");
    register_clcmd( "regroup","radioblock");
    register_clcmd( "followme","radioblock");
    register_clcmd( "takingfire","radioblock");
    register_clcmd( "go","radioblock");
    register_clcmd( "fallback","radioblock");
    register_clcmd( "sticktog","radioblock");
    register_clcmd( "getinpos","radioblock");
    register_clcmd( "stormfront","radioblock");
    register_clcmd( "report","radioblock");
    register_clcmd( "roger","radioblock");
    register_clcmd( "enemyspot","radioblock");
    register_clcmd( "needbackup","radioblock");
    register_clcmd( "sectorclear","radioblock");
    register_clcmd( "inposition","radioblock");
    register_clcmd( "reportingin","radioblock");
    register_clcmd( "getout","radioblock");
    register_clcmd( "negative","radioblock");
    register_clcmd( "enemydown","radioblock");

}

public plugin_cfg( )
{
	GivingDogSounds( );
	LoadFromFile( );
}

public plugin_end( )
{
	ArrayDestroy( g_aDogData );
}

public client_authorized( id ) {
	get_user_authid( id, g_szAuthid[ id ], 34 );
}

public client_putinserver(id) {
    new data[35];
    for( new i = 0; i < g_iDogged; i++ ) {
    	ArrayGetString( g_aDogData, i, data, 34);
    	if (equali(g_szAuthid[id], data)) {
    		Dogged[id] = true;
    		set_speak( id, SPEAK_MUTED );
    		return PLUGIN_HANDLED;
    	}
    }
    return PLUGIN_HANDLED;
}

public client_disconnect(id) {
	new data[35];
	for(new i=0; i<g_iDogged; i++) {
		ArrayGetString( g_aDogData, i, data, 34);
		if (equali(g_szAuthid[id], data)) {
			Dogged[id] = false;
			break;
		}
	}
}

public clcmd_Say(id) {
	new Args[192];
	read_args(Args, charsmax(Args));
	remove_quotes(Args);

	if (Args[0] == '/' && Args[1] == 'd' && Args[2] == 'o' && Args[3] == 'g' && !Dogged[id] && Args[4] != 's') {
		client_cmd(id, Args);
		return PLUGIN_HANDLED;
	}
		else if (Args[0] == '/' && Args[1] == 'u' && Args[2] == 'n' && Args[3] == 'd'
        && Args[4] == 'o' && Args[5] == 'g' && !Dogged[id]) {
			client_cmd(id, Args);
			return PLUGIN_HANDLED;
		}
		else if (Dogged[id] && !CheckDogSound(Args)) {
			client_cmd(id, "say %s", dog_sounds[random_num(0, 7)]);
			return PLUGIN_HANDLED;
		}
	return PLUGIN_CONTINUE;
}

public clcmd_SayTeam(id) {
	new Args[192];
	read_args(Args, charsmax(Args));
	remove_quotes(Args);

	if (Dogged[id] && !CheckDogSound(Args) ) {
		client_cmd(id, "say_team %s", dog_sounds[random_num(0, 7)]);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public clcmd_Dog(id, level, cid) {
	if(!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	new arg[35];
	read_argv(1, arg, 34);

	new dog = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY);			// CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE);
	if (!dog) {
		ColorChat(id, RED, "^4[ADMIN]^1 Can't find the dog!");
		return PLUGIN_HANDLED;
	}

	if (Dogged[dog]) {
		ColorChat(id, RED, "^4[ADMIN]^1 He is already a dog");
		return PLUGIN_HANDLED;
	}

	Dogged[dog] = true;
	ColorChat(id, RED, "^4[ADMIN]^1 You've made him a dog :)");
	set_speak( dog, SPEAK_MUTED );
	AddID(dog);
	return PLUGIN_HANDLED;
}

public clcmd_UnDog(id, level, cid) {
	if(!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	new arg[35];
	read_argv(1, arg, 34);

	new human = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY);
	if (!human) {
		ColorChat(0, RED, "^4[ADMIN]^3 Can't find your upcoming human!");
		return PLUGIN_HANDLED;
	}

	if (Dogged[human]) {
		new data[35], tmp[35];									// player's steam id
		get_user_authid(human, data, 34);
		for (new i=0; i<g_iDogged; i++) {
			ArrayGetString( g_aDogData, i, tmp, 34);
			if (equali(tmp, data) ) {							// found a player with gagged's steam id
				Dogged[human] = false;
				ArrayDeleteItem(g_aDogData, i);
				ColorChat(id, RED, "^4[ADMIN]^1 You've undogged him :)");
				g_iDogged--;
				SaveToFile();
				break;
			}
		}
	}
		else {
			ColorChat(id, RED, "^4[ADMIN]^3 He is already a human!");
		}

	return PLUGIN_HANDLED;
}

public AddID(dog) {
	new data[35];
	copy(data, 34, g_szAuthid[dog]);
	ArrayPushString( g_aDogData, data );
	g_iDogged++;
	SaveToFile();
}

LoadFromFile( )
{
	new hFile = fopen( g_szDogFile, "rt" );

	if( hFile) {
		new szData[ 35 ];

		while( !feof( hFile ) ) {
			fgets( hFile, szData, charsmax( szData ) );
			trim( szData );

			if( !szData[ 0 ] ) {
                continue;
            }

			ArrayPushString( g_aDogData, szData );
			g_iDogged++;
		}
		fclose( hFile );
	}
}

SaveToFile( ) {
	new hFile = fopen( g_szDogFile, "wt" );

	if( hFile ) {
		new data[35];

		for(new i=0; i<g_iDogged; i++) {
			ArrayGetString( g_aDogData, i, data, 34);
			if (i != g_iDogged)
				fprintf( hFile, "%s^n", data);
			else
				fprintf( hFile, "%s", data);
		}

		fclose( hFile );
	}
}

public client_infochanged( id )
{
	if( !Dogged[id] ) {
		return;
	}

	static const name[ ] = "name";

	static szNewName[ 32 ], szOldName[ 32 ];
	get_user_info( id, name, szNewName, 31 );
	get_user_name( id, szOldName, 31 );

	if( !equal( szNewName, szOldName ) ) {
		set_user_info( id, name, szOldName );
		client_print(id, print_center, "Why so kinky? :)");
	}
}

public MessageSayText( )
{
	static const Cstrike_Name_Change[ ] = "#Cstrike_Name_Change";

	new szMessage[ sizeof( Cstrike_Name_Change ) + 1 ];
	get_msg_arg_string( 2, szMessage, charsmax( szMessage ) );

	if( equal( szMessage, Cstrike_Name_Change ) ) {
		new szName[ 32 ], id;
		for(new i=3; i<=4; i++) {
			get_msg_arg_string( i, szName, 31 );

			id = get_user_index( szName );

			if( is_user_connected( id ) ) {
				if( Dogged[id] ) {
					return PLUGIN_HANDLED;
				}

				break;
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public radioblock(id) {
    if (Dogged[id]) {
    	client_print(id, print_center, "Why so kinky? :)");
    }
    return PLUGIN_HANDLED;
}

public GivingDogSounds() {
	dog_sounds[0] = "Woof";
	dog_sounds[1] = "Bark";
	dog_sounds[2] = "Ruff";
	dog_sounds[3] = "Arf";
	dog_sounds[4] = "Wuff";
	dog_sounds[5] = "Hav";
	dog_sounds[6] = "Woaf";
	dog_sounds[7] = "Gaff";
}

public CheckDogSound(stringas[]) {
	for (new i=0; i<8; i++) {
		if (equali(stringas, dog_sounds[i]) ) {
			return true;
		}
	}
	return false;
}

public clcmd_Dogs(id, level, cid) {
    if(!cmd_access(id, level, cid, 1)) {
    	return PLUGIN_HANDLED;
    }
    ColorChat(0, RED, "[%s]^4 There are %d dogs.", SERVER_PREFIX, g_iDogged);
    return PLUGIN_HANDLED;
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
