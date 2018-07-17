#include < amxmodx >
#include < engine >
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
	"1337", // _Name[ MaxClients ]
	"Be online at 13:37", // _Description[ 256 ]
	"progress_1337", // _Save_Name[ MaxClients ]
	1 // _Max_Value
};

// pointer to achievement
new AchievementPointer;

// holder for client steamid
new SteamId[ MaxClients + 1 ][ MaxSteamIdChars ];

// pointer to thinking entity
new TimerEntity;

// variable for maxplayers
new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Achievement API: 1337", "0.0.1", "Xellath" );
	
	// register achievement to api
	AchievementPointer = RegisterAchievement( 
		AchievementInfo[ _Name ], /* achievement name */
		AchievementInfo[ _Description ], /* achievement description */
		AchievementInfo[ _Save_Name ], /* achievement save name */
		AchievementInfo[ _Max_Value ] /* achievement max value */
		);
		
	TimerEntity = create_entity( "info_target" );
	entity_set_string( TimerEntity, EV_SZ_classname, "timercheck" );
	entity_set_float( TimerEntity, EV_FL_nextthink, ( get_gametime( ) + 25.0 ) );
	
	register_think( "timercheck", "Forward_EntityTimerThink" );
	
	MaxPlayers = get_maxplayers( );
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
	new ObjectiveData;
	ObjectiveData = GetAchievementData( SteamId[ Client ] /* our key */, AchievementInfo[ _Save_Name ] /* save name for achievement */ );
	
	// debug
	#if defined DebugMode
		new SaveKey[ MaxClients ];
		GetAchievementSaveKey( AchievementPointer, SaveKey );
		client_print( Client, print_console, "debug: %i completed", ObjectiveData );
		client_print( Client, print_console, "debug: %i GetMaxAchievements", GetMaxAchievements( ) );
		client_print( Client, print_console, "debug: %i GetClientAchievementsCompleted", GetClientAchievementsCompleted( Client ) );
		client_print( Client, print_console, "debug: %s GetAchievementSaveKey", SaveKey );
		client_print( Client, print_console, "debug: %i GetAchievementMaxValue", GetAchievementMaxValue( AchievementPointer ) );
	#endif
	
	// check if client already completed achievement
	if( GetClientAchievementStatus( AchievementPointer, ObjectiveData ) == _In_Progress )
	{
		// achievement not completed
		
		// debug
		#if defined DebugMode
			client_print( Client, print_console, "debug: %i completed", ObjectiveData );
		#endif
		
		// save objective data to clients steamid
		SetAchievementData( SteamId[ Client ] /* our key */, AchievementInfo[ _Save_Name ] /* save name for achievement */, ObjectiveData /* data */ );
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

public Forward_EntityTimerThink( Entity )
{
	if( Entity != TimerEntity )
	{
		return;
	}
	
	new Time[ 6 ];
	get_time( "%H:%M", Time, charsmax( Time ) );
	
	// debug
	#if defined DebugMode
		client_print( 0, print_chat, "debug: %s", Time );
	#endif
	
	if( equali( Time, "13:37" ) )
	{
		for( new Player = 1; Player <= MaxPlayers; Player++ )
		{
			if( is_user_connected( Player ) )
			{
				// get data, 0 if not completed 1 if completed
				new ObjectiveData;
				ObjectiveData = GetAchievementData( SteamId[ Player ] /* our key */, AchievementInfo[ _Save_Name ] /* save name for achievement */ );
				if( GetClientAchievementStatus( AchievementPointer, ObjectiveData ) == _In_Progress )
				{
					// client does not have achievement
					
					// saving
					// using GetAchievementMaxValue to confirm that it's completed
					SetAchievementData( SteamId[ Player ] /* our key */, AchievementInfo[ _Save_Name ] /* save name for achievement */, GetAchievementMaxValue( AchievementPointer ) /* data */ );
			
					// send completed to api, announce
					ClientAchievementCompleted( Player, AchievementPointer, .Announce = true ); 
				}
			}
		}
	}
	
	entity_set_float( TimerEntity, EV_FL_nextthink, ( get_gametime( ) + 25.0 ) );
}