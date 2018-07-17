#include < amxmodx >
#include < achievement_api >

// NOTE: This plugin is NOT meant to be used as a plugin. 
// This is simply a demonstration of how to register 
// several achievements in the same plugin. It compiles and
// runs fine, but does not work as theres is no objectives.
// As said before, it's simply a demonstration of how the API works.

const MaxClients = 32;
const MaxSteamIdChars = 35;

const TaskIdDelayConnect = 6729;

#define DebugMode // uncomment to view debugs

// achievements
enum _:Achievements
{
	_Addict, // actual plugin posted in thread
	_1337, // actual plugin posted in thread
	_Bomb, // example
	_Trololol, // example
	_SPARTA // example
	/* ... */
};

// achievement structure
enum _:AchievementDataStruct
{
	_Name[ MaxClients ],
	_Description[ 256 ], // cannot exceed 255 chars - limit set in api
	_Save_Name[ MaxClients ],
	_Max_Value
};

// NOTE: Achievements CANNOT have the same Save_Name values, this will cause confusion and mishaps in the plugin.
new const AchievementInfo[ Achievements ][ AchievementDataStruct ] = 
{
	// _Addict
	{
		"Addict", // _Name[ MaxClients ]
		"Connect 500 times", // _Description[ 256 ]
		"progress_addict", // _Save_Name[ MaxClients ]
		500 // _Max_Value
	},
	// _1337
	{
		"1337", // _Name[ MaxClients ]
		"Be online at 13:37", // _Description[ 256 ]
		"progress_1337", // _Save_Name[ MaxClients ]
		1 // _Max_Value
	},
	// _Bomb
	{
		"Bomb", // _Name[ MaxClients ]
		"BOMBSITE A DESTROYED OVAR NINE THOUSAND TIMES", // _Description[ 256 ]
		"progress_bomb", // _Save_Name[ MaxClients ]
		9000 // _Max_Value
	},
	// _Trololol
	{
		"trolol", // _Name[ MaxClients ]
		"Connect 500 times", // _Description[ 256 ]
		"progress_trolol", // _Save_Name[ MaxClients ]
		1 // _Max_Value
	},
	// _SPARTA
	{
		"THIS IS SPARTA!!!!", // _Name[ MaxClients ]
		"sparta, eh?", // _Description[ 256 ]
		"progress_spaaartaaa", // _Save_Name[ MaxClients ]
		1 // _Max_Value
	}
};

// pointer to achievement
new AchievementPointer[ Achievements ];

// holder for client steamid
new SteamId[ MaxClients + 1 ][ MaxSteamIdChars ];

// our objective counter
new ObjectiveCounter[ Achievements ][ MaxClients + 1 ];

public plugin_init( )
{
	register_plugin( "Achievement API: Example", "0.0.1", "Xellath" );
	
	// loop through achievements
	for( new AchiIndex; AchiIndex < Achievements; AchiIndex++ )
	{
		// register achievement to api
		AchievementPointer[ AchiIndex ] = RegisterAchievement( 
			AchievementInfo[ AchiIndex ][ _Name ], /* achievement name */
			AchievementInfo[ AchiIndex ][ _Description ], /* achievement description */
			AchievementInfo[ AchiIndex ][ _Save_Name ], /* achievement save name */
			AchievementInfo[ AchiIndex ][ _Max_Value ] /* achievement max value */
			);
	}
}

public client_connect( Client )
{
	set_task( 10.0, "TaskDelayConnect", Client + TaskIdDelayConnect );
}

public TaskDelayConnect( TaskId )
{
	new Client = TaskId - TaskIdDelayConnect;
	
	// get steamid
	get_user_authid( Client, SteamId[ Client ], charsmax( SteamId ) );
	
	// loop through achievements
	for( new AchiIndex; AchiIndex < Achievements; AchiIndex++ )
	{
		// first check if our client has objective data
		ObjectiveCounter[ Client ][ AchiIndex ] = GetAchievementData( SteamId[ Client ] /* our key */, AchievementInfo[ AchiIndex ][ _Save_Name ] /* save name for achievement */ );
		
		// debug
		#if defined DebugMode
			new SaveKey[ MaxClients ];
			GetAchievementSaveKey( AchievementPointer[ AchiIndex ], SaveKey );
			client_print( Client, print_console, "debug: %i", ObjectiveCounter[ Client ][ AchiIndex ] );
			client_print( Client, print_console, "debug: %i GetMaxAchievements", GetMaxAchievements( ) );
			client_print( Client, print_console, "debug: %i GetClientAchievementsCompleted", GetClientAchievementsCompleted( Client ) );
			client_print( Client, print_console, "debug: %s GetAchievementSaveKey", SaveKey );
			client_print( Client, print_console, "debug: %i GetAchievementMaxValue", GetAchievementMaxValue( AchievementPointer[ AchiIndex ] ) );
		#endif
		
		// check if client already completed achievement
		if( GetClientAchievementStatus( AchievementPointer[ AchiIndex ], ObjectiveCounter[ Client ][ AchiIndex ] ) == _In_Progress )
		{
			// achievement not completed
			
			// increment objective variable
			//ObjectiveCounter[ Client ][ AchiIndex ]++;
			
			// debug
			#if defined DebugMode
				client_print( Client, print_console, "debug: %i", ObjectiveCounter[ Client ][ AchiIndex ] );
			#endif
			
			// save objective data to clients steamid
			SetAchievementData( SteamId[ Client ] /* our key */, AchievementInfo[ AchiIndex ][ _Save_Name ] /* save name for achievement */, ObjectiveCounter[ Client ][ AchiIndex ] /* data */ );
			
			// check again if objective is done
			if( GetClientAchievementStatus( AchievementPointer[ AchiIndex ], ObjectiveCounter[ Client ][ AchiIndex ] ) == _Unlocked )
			{
				// achievement completed
				
				// send completed to api, with announce
				ClientAchievementCompleted( Client, AchievementPointer[ AchiIndex ], .Announce = true ); // default is true, but just to clarify
			}
		}
		else //if( GetClientAchievementStatus( AchievementPointer[ AchiIndex ], ObjectiveCounter[ Client ][ AchiIndex ] ) == _Unlocked )
		{
			// debug
			#if defined DebugMode
				client_print( Client, print_console, "debug: send completed to api, but don't announce" );
			#endif
			
			// client has achievement already
			// send completed to api, but don't announce
			ClientAchievementCompleted( Client, AchievementPointer[ AchiIndex ], .Announce = false ); // set true to announce
			
			// debug
			#if defined DebugMode
				client_print( Client, print_console, "debug: %i GetClientAchievementsCompleted (Unlocked)", GetClientAchievementsCompleted( Client ) );
			#endif
		}
	}
	
	// remove task
	remove_task( Client + TaskIdDelayConnect );
}

public client_disconnect( Client )
{
	// loop through achievements
	for( new AchiIndex; AchiIndex < Achievements; AchiIndex++ )
	{
		// reset variable in case played indexes are magically switched and another client gets another set of connections
		ObjectiveCounter[ Client ][ AchiIndex ] = 0;
	}
}

public Forward_ClientEarnedAchievement( const AchiPointer, const Client )
{
	// loop through achievements
	for( new AchiIndex; AchiIndex < Achievements; AchiIndex++ )
	{
		if( AchiPointer == AchievementPointer[ AchiIndex ] )
		{
			// this forward can be used to reward people stuff
			// perhaps a model or just something extra
			
			#if defined DebugMode
				client_print( Client, print_console, "debug: Forward_ClientEarnedAchievement" );
			#endif
		}
	}
}