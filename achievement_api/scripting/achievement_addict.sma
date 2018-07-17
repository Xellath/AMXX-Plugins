#include < amxmodx >
#include < achievement_api >

const MaxClients = 32;
const MaxSteamIdChars = 35;

const TaskIdDelayConnect = 6729;

//#define DebugMode // uncomment to view debugs

// achievement structure
enum _:AchievementDataStruct
{
	_Name[ MaxClients ],
	_Description[ 256 ], // cannot exceed 255 chars - limit set in api
	_Save_Name[ MaxClients ],
	_Max_Value
};

new const AchievementInfo[ AchievementDataStruct ] = 
{
	"Addict", // _Name[ MaxClients ]
	"Connect 500 times", // _Description[ 256 ]
	"progress_addict", // _Save_Name[ MaxClients ]
	500 // _Max_Value
};

// pointer to achievement
new AchievementPointer;

// holder for client steamid
new SteamId[ MaxClients + 1 ][ MaxSteamIdChars ];

// our objective counter
new Connections[ MaxClients + 1 ];

public plugin_init( )
{
	register_plugin( "Achievement API: Addict", "0.0.1", "Xellath" );
	
	// register achievement to api
	AchievementPointer = RegisterAchievement( 
		AchievementInfo[ _Name ], /* achievement name */
		AchievementInfo[ _Description ], /* achievement description */
		AchievementInfo[ _Save_Name ], /* achievement save name */
		AchievementInfo[ _Max_Value ] /* achievement max value */
		);
		
	// debug
	#if defined DebugMode
		log_amx( "debug: %i AchievementPointer", AchievementPointer );
	#endif
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
	
	// first check if our client has objective data
	Connections[ Client ] = GetAchievementData( SteamId[ Client ] /* our key */, AchievementInfo[ _Save_Name ] /* save name for achievement */ );
	
	// debug
	#if defined DebugMode
		new SaveKey[ MaxClients ];
		GetAchievementSaveKey( AchievementPointer, SaveKey );
		client_print( Client, print_console, "debug: %i connections", Connections[ Client ] );
		client_print( Client, print_console, "debug: %i GetMaxAchievements", GetMaxAchievements( ) );
		client_print( Client, print_console, "debug: %i GetClientAchievementsCompleted", GetClientAchievementsCompleted( Client ) );
		client_print( Client, print_console, "debug: %s GetAchievementSaveKey", SaveKey );
		client_print( Client, print_console, "debug: %i GetAchievementMaxValue", GetAchievementMaxValue( AchievementPointer ) );
	#endif
	
	// check if client already completed achievement
	if( GetClientAchievementStatus( AchievementPointer, Connections[ Client ] ) == _In_Progress )
	{
		// achievement not completed
		
		// increment the objective variable
		Connections[ Client ]++;
		
		// debug
		#if defined DebugMode
			client_print( Client, print_console, "debug: %i connections", Connections[ Client ] );
		#endif
		
		// save objective data to clients steamid
		SetAchievementData( SteamId[ Client ] /* our key */, AchievementInfo[ _Save_Name ] /* save name for achievement */, Connections[ Client ] /* data */ );
		
		// check again if objective is done
		if( GetClientAchievementStatus( AchievementPointer, Connections[ Client ] ) == _Unlocked )
		{
			// client has done, in this case, 500 connections ( _Max_Value )
			// achievement completed
			
			// send completed to api, with announce
			ClientAchievementCompleted( Client, AchievementPointer, .Announce = true ); // default is true, but just to clarify
		}
	}
	else //if( GetClientAchievementStatus( AchievementPointer, Connections[ Client ] ) == _Unlocked )
	{
		// debug
		#if defined DebugMode
			client_print( Client, print_console, "debug: send completed to api, but don't announce" );
		#endif
		
		// client has achievement already
		// send completed to api, but don't announce
		ClientAchievementCompleted( Client, AchievementPointer, .Announce = false ); // set true to announce
		
		// debug
		#if defined DebugMode
			client_print( Client, print_console, "debug: %i GetClientAchievementsCompleted (Unlocked)", GetClientAchievementsCompleted( Client ) );
		#endif
	}
	
	// remove task
	remove_task( Client + TaskIdDelayConnect );
}

public client_disconnect( Client )
{
	// reset variable in case played indexes are magically switched and another client gets another set of connections
	Connections[ Client ] = 0;
}

public Forward_ClientEarnedAchievement( const AchiPointer, const Client )
{
	if( AchiPointer == AchievementPointer )
	{
		// this forward can be used to reward people stuff
		// perhaps a model or just something extra
		
		#if defined DebugMode
			client_print( Client, print_console, "debug: Forward_ClientEarnedAchievement" );
		#endif
	}
}