#include < amxmodx >
#include < geoip >
#include < dbm_api >
#include < colorchat >

enum _:Data
{
	_Client_Name[ MaxSlots ],
	_Steam_ID[ MaxSteamIdChars ],
	_IP[ MaxSlots ],
	_City[ 46 ],
	_Country[ 46 ]
};

new ClientData[ MaxSlots + 1 ][ Data ];

new CvarChangeLang;

new MaxPlayers;

public plugin_init( )
{
	if( !is_plugin_loaded( "dbm_core.amxx", true ) )
	{
		set_fail_state( "[ Diablo Mod Connect Info ] DBM Core needs to be loaded in order for this plugin to run correctly!" );
	}
	
	register_plugin( "Diablo Mod Addon: Connect Info", "0.0.1", "Xellath" );
	
	CvarChangeLang = register_cvar( "dbm_change_lang", "1" ); // 0 to disable
	
	register_dictionary_colored( "dbm_core_lang.txt" );
	register_dictionary_colored( "dbm_addon_lang.txt" );
	
	MaxPlayers = get_maxplayers( );
}

public Forward_DBM_DelayConnect( const Client )
{
	if( !is_user_bot( Client ) )
	{
		Delay( 3000 );
		
		get_user_name( Client, ClientData[ Client ][ _Client_Name ], charsmax( ClientData[ ][ _Client_Name ] ) );
		get_user_authid( Client, ClientData[ Client ][ _Steam_ID ], charsmax( ClientData[ ][ _Steam_ID ] ) );
		get_user_ip( Client, ClientData[ Client ][ _IP ], charsmax( ClientData[ ][ _IP ] ), 1 );
		
		geoip_city( ClientData[ Client ][ _IP ], ClientData[ Client ][ _City ], charsmax( ClientData[ ][ _City ] ) );
		geoip_country( ClientData[ Client ][ _IP ], ClientData[ Client ][ _Country ], charsmax( ClientData[ ][ _Country ] ) );
		
		if( get_pcvar_num( CvarChangeLang )
		&& !( equali( ClientData[ Client ][ _Country ], "err" ) ) )
		{
			new CCode[ 3 ];
			geoip_code2_ex( ClientData[ Client ][ _IP ], CCode );
			
			for( new TextIndex = 0; TextIndex < 3; TextIndex++ )
			{
				CCode[ TextIndex ] = tolower( CCode[ TextIndex ] );
			}
			
			engclient_cmd( Client, "lang", CCode );
		}
		
		if( equali( ClientData[ Client ][ _Steam_ID ], "STEAM_ID_LAN" ) )
		{
			for( new Player = 1; Player <= MaxPlayers; Player++ )
			{
				if( is_user_connected( Player ) )
				{
					client_print_color( Player, DontChange, 
						"^4* ^3%s %L %s, %s. %L: %i/%i (^4%i%%^3)",
						ClientData[ Client ][ _Client_Name ],
						Player,
						"CONNECTED_FROM",
						ClientData[ Client ][ _City ],
						ClientData[ Client ][ _Country ],
						Player,
						"QUESTS_COMPLETED",
						DBM_GetQuestsCompleted( Client ),
						DBM_GetTotalQuests( ),
						( DBM_GetQuestsCompleted( Client ) / DBM_GetTotalQuests( ) / 100 )
						);
				}
			}
		}
		else
		{
			for( new Player = 1; Player <= MaxPlayers; Player++ )
			{
				if( is_user_connected( Player ) )
				{
					client_print_color( Player, DontChange, 
						"^4* ^3%s (^4%s^3) %L %s, %s. %L: %i/%i (^4%i%%^3)",
						ClientData[ Client ][ _Client_Name ],
						ClientData[ Client ][ _Steam_ID ],
						Player,
						"CONNECTED_FROM",
						ClientData[ Client ][ _City ],
						ClientData[ Client ][ _Country ],
						Player,
						"QUESTS_COMPLETED",
						DBM_GetQuestsCompleted( Client ),
						DBM_GetTotalQuests( ),
						( DBM_GetQuestsCompleted( Client ) / DBM_GetTotalQuests( ) / 100 )
						);
				}
			}
		}
	}
}

public client_disconnect( Client )
{
	if( !is_user_bot( Client ) )
	{
		if( equali( ClientData[ Client ][ _Steam_ID ], "STEAM_ID_LAN" ) )
		{
			for( new Player = 1; Player <= MaxPlayers; Player++ )
			{
				if( is_user_connected( Player ) )
				{
					client_print_color( Player, DontChange, 
						"^4* ^3%s %L %s, %s. %L: %i/%i (^4%i%%^3)",
						ClientData[ Client ][ _Client_Name ],
						Player,
						"DISCONNECTED_FROM",
						ClientData[ Client ][ _City ],
						ClientData[ Client ][ _Country ],
						Player,
						"QUESTS_COMPLETED",
						DBM_GetQuestsCompleted( Client ),
						DBM_GetTotalQuests( ),
						( DBM_GetQuestsCompleted( Client ) / DBM_GetTotalQuests( ) / 100 )
						);
				}
			}
		}
		else
		{
			for( new Player = 1; Player <= MaxPlayers; Player++ )
			{
				if( is_user_connected( Player ) )
				{
					client_print_color( Player, DontChange,
						"^4* ^3%s (^4%s^3) %L %s, %s. %L: %i/%i (^4%i%%^3)",
						ClientData[ Client ][ _Client_Name ],
						ClientData[ Client ][ _Steam_ID ],
						Player,
						"DISCONNECTED_FROM",
						ClientData[ Client ][ _City ],
						ClientData[ Client ][ _Country ],
						Player,
						"QUESTS_COMPLETED",
						DBM_GetQuestsCompleted( Client ),
						DBM_GetTotalQuests( ),
						( DBM_GetQuestsCompleted( Client ) / DBM_GetTotalQuests( ) / 100 )
						);
				}
			}
		}
			
		for( new DataType; DataType < Data; DataType++ )
		{
			ClientData[ Client ][ DataType ] = 0;
		}
	}
}

Delay( const Milliseconds )
{
	for( new Millisec = 0; Millisec <= Milliseconds; Millisec++ )
	{
		// the loop is just for delaying code (note that this is a sloppy way of delaying)
	}
}