#include < amxmodx >
#include < hamsandwich >
//#define UseSQL // uncomment to use mysql (database saving)
#if defined UseSQL
	#include < sqlvault >
	#include < sqlvault_ex >
#else
	#include < nfvault >
#endif

#define UseChatColor // comment to use regular chat text, without colors
#if defined UseChatColor
	#include < chatcolor >
#endif

//#define UseCZTutor // uncomment to use tutor messages instead of simple chat text messages
// NOTE: Will ONLY work if run on a CZ server, as copying the resources from CZ to CS 1.6 is illegal.

//#define DebugMode

const MaxClients = 32;
const MaxSteamIdChars = 35;

#if defined UseCZTutor
	const TaskIdRemoveTutor = 7563;
#endif

enum Status
{
	_In_Progress = 0,
	_Unlocked
};

enum _:AchievementsStruct
{
	_Name[ MaxClients ],
	_Description[ 256 ],
	Array:_Data
};

enum _:AchievementDataStruct
{
	_Save_Name[ MaxClients ],
	_Max_Value
};

new Array:Achievement;

new AchievementsCompleted[ MaxClients + 1 ];

new ForwardClientAchievement;
new ForwardAchievementReturn;

new bool:FirstSpawn[ MaxClients + 1 ];

#if defined UseSQL
	new SQLVault:VaultHandle;
#else
	new VaultFile[ 128 ];
#endif

#if defined UseCZTutor
	new MsgIdTutorText;
	new MsgIdTutorClose;
#endif

public plugin_init( )
{
	register_plugin( "Achievement API: Core", "0.0.4", "Xellath" );
	
	register_cvar( "api_author", "Xellath", FCVAR_SERVER | FCVAR_SPONLY );
	set_cvar_string( "api_author", "Xellath" ); 
	
	ForwardClientAchievement = CreateMultiForward( "Forward_ClientEarnedAchievement", ET_IGNORE, FP_CELL, FP_CELL );
	
	RegisterHam( Ham_Spawn, "player", "Forward_HamClientSpawn", 1 );
	
	Achievement = ArrayCreate( AchievementsStruct );
	
	#if defined UseCZTutor
		MsgIdTutorText = get_user_msgid( "TutorText" );
		MsgIdTutorClose = get_user_msgid( "TutorClose" );
	#endif
	
	#if defined UseSQL
		VaultHandle = sqlv_open_default( "achievement_api", false );
		sqlv_init_ex( VaultHandle );
	#else
		nfv_file( "achievement_api", VaultFile, charsmax( VaultFile ) );
	#endif
}

public plugin_end( )
{
	#if defined UseSQL
		sqlv_close( VaultHandle );
	#endif
	
	new TotalAchievements = ArraySize( Achievement );
	new AchievementData[ AchievementsStruct ];
	
	for( new Index = 0; Index < TotalAchievements; Index++ )
	{
		ArrayGetArray( Achievement, Index, AchievementData );
		
		ArrayDestroy( AchievementData[ _Data ] );
	}
	
	ArrayDestroy( Achievement );
}

public plugin_natives( )
{
	register_library( "achievement_api" );
	
	register_native( "RegisterAchievement", "_RegisterAchievement" );
	
	register_native( "ClientAchievementCompleted", "_ClientAchievementCompleted" );
	
	register_native( "GetClientAchievementStatus", "_GetClientAchievementStatus" );
	
	register_native( "GetClientAchievementsCompleted", "_GetClientAchievementsCompleted" );
	register_native( "GetMaxAchievements", "_GetMaxAchievements" );
	
	register_native( "GetAchievementName", "_GetAchievementName" );
	register_native( "GetAchievementDesc", "_GetAchievementDesc" );
	
	register_native( "GetAchievementSaveKey", "_GetAchievementSaveKey" );
	register_native( "GetAchievementMaxValue", "_GetAchievementMaxValue" );

	register_native( "SetAchievementData", "_SetAchievementData" );
	register_native( "GetAchievementData", "_GetAchievementData" );
}

public _RegisterAchievement( Plugin, Params )
{
	new AchievementData[ AchievementsStruct ];
	get_string( 1, AchievementData[ _Name ], charsmax( AchievementData[ _Name ] ) );
	get_string( 2, AchievementData[ _Description ], charsmax( AchievementData[ _Description ] ) );
	
	AchievementData[ _Data ] = _:ArrayCreate( AchievementDataStruct );
	
	ArrayPushArray( Achievement, AchievementData );
	
	new CurrentAchievement = ArraySize( Achievement );
	
	new Data[ AchievementDataStruct ];
	get_string( 3, Data[ _Save_Name ], charsmax( Data[ _Save_Name ] ) );
	
	Data[ _Max_Value ] = get_param( 4 );
	
	ArrayPushArray( AchievementData[ _Data ], Data );
	
	#if defined DebugMode
		log_amx( "debug: %i CurrentAchievement", CurrentAchievement );
	#endif
	
	return ( CurrentAchievement - 1 );
}

public _ClientAchievementCompleted( Plugin, Params )
{
	new Client = get_param( 1 );
	new AchievementPointer = get_param( 2 );
	
	AchievementsCompleted[ Client ]++;
	
	if( get_param( 3 ) )
	{
		new AchievementData[ AchievementsStruct ];
		ArrayGetArray( Achievement, AchievementPointer, AchievementData );
		
		new Data[ AchievementDataStruct ];
		ArrayGetArray( AchievementData[ _Data ], 0, Data );
		
		#if defined UseCZTutor
			CreateTutorMessage( Client, random_num( 1, 4 ), 
				"Achievement Earned: %s",
				 AchievementData[ _Name ]
				);
		#endif
		
		new ClientName[ MaxClients ];
		get_user_name( Client, ClientName, charsmax( ClientName ) );
		
		#if defined UseChatColor
			client_print_color( 0, DontChange, 
				"^4[ Achievements API ]^3 %s unlocked achievement: ^4%s ^3- Progress: %i/%i",
				ClientName,
				AchievementData[ _Name ],
				AchievementsCompleted[ Client ],
				ArraySize( Achievement )
				);
		#else
			client_print( 0, print_chat, 
				"[ Achievements API ] %s unlocked achievement: %s - Progress: %i/%i",
				ClientName,
				AchievementData[ _Name ],
				AchievementsCompleted[ Client ],
				ArraySize( Achievement )
				);
		#endif
			
		ExecuteForward( ForwardClientAchievement, ForwardAchievementReturn, AchievementPointer, Client );
	}
}

public Status:_GetClientAchievementStatus( Plugin, Params )
{
	new AchievementPointer = get_param( 1 );
	
	#if defined DebugMode
		log_amx( "debug: %i AchievementPointer", AchievementPointer );
	#endif
	
	new AchievementData[ AchievementsStruct ];
	ArrayGetArray( Achievement, AchievementPointer, AchievementData );
	
	new Data[ AchievementDataStruct ];
	ArrayGetArray( AchievementData[ _Data ], 0, Data );
	
	if( get_param( 2 ) >= Data[ _Max_Value ] )
	{
		return _Unlocked;
	}
	
	return _In_Progress;
}

public _GetClientAchievementsCompleted( Plugin, Params )
{
	return AchievementsCompleted[ get_param( 1 ) ];
}

public _GetMaxAchievements( Plugin, Params )
{
	return ArraySize( Achievement );
}

public _GetAchievementName( Plugin, Params )
{
	new AchievementPointer = get_param( 1 );
	new AchievementData[ AchievementsStruct ];
	ArrayGetArray( Achievement, AchievementPointer, AchievementData );
	
	set_string( 2, AchievementData[ _Name ], charsmax( AchievementData[ _Name ] ) );
}

public _GetAchievementDesc( Plugin, Params )
{
	new AchievementPointer = get_param( 1 );
	new AchievementData[ AchievementsStruct ];
	ArrayGetArray( Achievement, AchievementPointer, AchievementData );
	
	set_string( 2, AchievementData[ _Description ], charsmax( AchievementData[ _Description ] ) );
}

public _GetAchievementSaveKey( Plugin, Params )
{
	new AchievementPointer = get_param( 1 );
	new AchievementData[ AchievementsStruct ];
	ArrayGetArray( Achievement, AchievementPointer, AchievementData );
	
	new Data[ AchievementDataStruct ];
	ArrayGetArray( AchievementData[ _Data ], 0, Data );
	
	set_string( 2, Data[ _Save_Name ], charsmax( Data[ _Save_Name ] ) );
}

public _GetAchievementMaxValue( Plugin, Params )
{
	new AchievementPointer = get_param( 1 );
	new AchievementData[ AchievementsStruct ];
	ArrayGetArray( Achievement, AchievementPointer, AchievementData );
	
	new Data[ AchievementDataStruct ];
	ArrayGetArray( AchievementData[ _Data ], 0, Data );
	
	return Data[ _Max_Value ];
}

public _SetAchievementData( Plugin, Params )
{
	new Key[ MaxSteamIdChars ], SaveName[ MaxClients ];
	get_string( 1, Key, charsmax( Key ) );
	get_string( 2, SaveName, charsmax( SaveName ) );
	
	#if defined UseSQL
		sqlv_connect( VaultHandle );
		
		sqlv_set_num_ex( VaultHandle, Key, SaveName, get_param( 3 ) );
		
		sqlv_disconnect( VaultHandle );
	#else
		nfv_set_num( VaultFile, Key, SaveName, get_param( 3 ) );
	#endif
}

public _GetAchievementData( Plugin, Params )
{
	new Key[ MaxSteamIdChars ], SaveName[ MaxClients ];
	get_string( 1, Key, charsmax( Key ) );
	get_string( 2, SaveName, charsmax( SaveName ) );
	
	#if defined UseSQL
		new Data;
		sqlv_connect( VaultHandle );
		
		Data = sqlv_get_num_ex( VaultHandle, Key, SaveName );
		
		sqlv_disconnect( VaultHandle );
		
		if( !Data )
		{
			return 0;
		}
		
		return Data;
	#else
		new Data[ 10 ];
		if( !nfv_get_data( VaultFile, Key, SaveName, Data, charsmax( Data ) ) )
		{
			return 0;
		}
		
		return str_to_num( Data );
	#endif
}

public client_connect( Client )
{
	AchievementsCompleted[ Client ] = 0;
	
	FirstSpawn[ Client ] = true;
}

public client_disconnect( Client )
{
	AchievementsCompleted[ Client ] = 0;
	
	FirstSpawn[ Client ] = true;
}

public Forward_HamClientSpawn( Client )
{
	if( is_user_alive( Client ) )
	{
		if( FirstSpawn[ Client ] )
		{
			FirstSpawn[ Client ] = false;
			
			return HAM_IGNORED;
		}
		
		#if defined UseCZTutor
			CreateTutorMessage( Client, random_num( 1, 4 ), 
				"This server is using Achievements API by Xellath^n^nYou have earned %i out of %i achievements",
				AchievementsCompleted[ Client ],
				ArraySize( Achievement )
				);
		#else
			#if defined UseChatColor
				client_print_color( Client, DontChange, 
					"^4[ Achievements API ] ^3This server is using Achievements API by ^4Xellath^3 - You have earned %i out of %i achievements",
					AchievementsCompleted[ Client ],
					ArraySize( Achievement )
					);
			#else
				client_print( Client, print_chat, 
					"[ Achievements API ] This server is using Achievements API by Xellath - You have earned %i out of %i achievements",
					AchievementsCompleted[ Client ],
					ArraySize( Achievement )
					);
			#endif
		#endif
	}
	
	return HAM_IGNORED;
}

#if defined UseCZTutor
	CreateTutorMessage( const Client, Color, Input[ ], any:... )
	{
		if( is_user_connected( Client ) )
		{
			if( task_exists( Client + TaskIdRemoveTutor ) )
			{
				message_begin( MSG_ONE_UNRELIABLE, MsgIdTutorClose, _, Client );
				message_end( );
				
				remove_task( Client + TaskIdRemoveTutor );
			}
			
			new Text[ 256 ];
			vformat( Text, charsmax( Text ), Input, 4 );
		
			message_begin( MSG_ONE_UNRELIABLE, MsgIdTutorText, _, Client );
			write_string( Text );
			write_byte( 0 );
			write_short( 0 );
			write_short( 0 );
			write_short( 1 << Color );
			message_end( );
		}
		
		set_task( 10.0, "RemoveTutorMessage", Client + TaskIdRemoveTutor );
	}

	public RemoveTutorMessage( TaskId )
	{
		new Client = TaskId - TaskIdRemoveTutor;

		message_begin( MSG_ONE_UNRELIABLE, MsgIdTutorClose, _, Client );
		message_end( );
	}
#endif