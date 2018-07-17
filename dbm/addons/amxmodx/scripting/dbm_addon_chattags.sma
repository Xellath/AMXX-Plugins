#include < amxmodx > 
#include < amxmisc > 
#include < cstrike > 
#include < dbm_api > 
#include < colorchat >

new const TeamNames[ CsTeams ][ ] = 
{ 
    "Spectator", 
    "Terrorist", 
    "Counter-Terrorist", 
    "Spectator" 
}; 

new CvarAllTalk;

new MsgIdSayText; 

new MaxPlayers; 

public plugin_init( ) 
{ 
	register_plugin( "Diablo Mod Addon: Class/Level Chat Tag", "0.0.1", "Xellath" ); 
	
	register_dictionary_colored( "dbm_class_lang.txt" );
	
	register_clcmd( "say", "ClientCommand_SayChat" ); 
	register_clcmd( "say_team", "ClientCommand_SayTeamChat" ); 
	
	CvarAllTalk = register_cvar( "dbm_chat_alltalk", "0" );
	
	MsgIdSayText = get_user_msgid( "SayText" ); 
	
	MaxPlayers = get_maxplayers( ); 
} 

public ClientCommand_SayChat( Client ) 
{ 
	new Said[ TextLength ]; 
	read_args( Said, charsmax( Said ) ); 
	remove_quotes( Said ); 

	if( !IsValidMessage( Said ) ) 
	{
		return PLUGIN_HANDLED;
	}
	
	new Name[ MaxSlots ]; 
	get_user_name( Client, Name, charsmax( Name ) ); 

	new Alive = is_user_alive( Client );
	
	new Tag[ 9 ]; 
	if( cs_get_user_team( Client ) == CS_TEAM_SPECTATOR ) 
	{ 
		copy( Tag, charsmax( Tag ), "*SPEC* "); 
	} 
	else if( !Alive ) 
	{ 
		copy( Tag, charsmax( Tag ), "*DEAD* "); 
	} 

	new Class = DBM_GetClientClass( Client );
	new Level = DBM_GetClassLevel( Client, Class );
	new ClassName[ MaxSlots ];
	DBM_GetClassName( Class, ClassName );

	new Message[ TextLength ]; 
	formatex( Message, charsmax( Message ),
		"^1%s^4[^3%L^4][^3%i^4]^3 %s^1 :  %s", 
		Tag, 
		Client, 
		ClassName, 
		Level, 
		Name, 
		Said
		); 

	for( new Player = 1; Player <= MaxPlayers; Player++ ) 
	{ 
		if( !is_user_connected( Player ) ) continue;
		
		if( !get_pcvar_num( CvarAllTalk ) )
		{
			if( is_user_alive( Player ) != Alive ) continue;
		}
		
		message_begin( MSG_ONE_UNRELIABLE, MsgIdSayText, _, Player ); 
		write_byte( Client ); 
		write_string( Message ); 
		message_end( ); 
	} 

	return PLUGIN_HANDLED; 
} 

public ClientCommand_SayTeamChat( Client ) 
{ 
	new Said[ TextLength ]; 
	read_args( Said, charsmax( Said ) ); 
	remove_quotes( Said ); 

	if( !IsValidMessage( Said ) ) 
	{
		return PLUGIN_HANDLED;
	}

	new Name[ MaxSlots ]; 
	get_user_name( Client, Name, charsmax( Name ) ); 

	new Alive = is_user_alive( Client );

	new Tag[ 9 ]; 
	if( !Alive ) 
	{ 
		copy( Tag, charsmax( Tag ), "*DEAD* "); 
	}

	new CsTeams:Team = cs_get_user_team( Client );

	new Class = DBM_GetClientClass( Client );
	new Level = DBM_GetClassLevel( Client, Class );
	new ClassName[ MaxSlots ];
	DBM_GetClassName( Class, ClassName );

	new Message[ TextLength ]; 
	formatex( Message, charsmax( Message ),
		"^1 (^3%s^1) %s^4[^3%L^4][^3%i^4]^3 %s^1 :  %s", 
		TeamNames[ Team ], 
		Tag,
		Client, 
		ClassName, 
		Level, 
		Name, 
		Said
		); 

	for( new Player = 1; Player <= MaxPlayers; Player++ ) 
	{ 
		if( !is_user_connected( Player ) 
		|| cs_get_user_team( Player ) != Team ) continue;
		
		if( !get_pcvar_num( CvarAllTalk ) )
		{
			if( is_user_alive( Player ) != Alive ) continue;
		}
		
		message_begin( MSG_ONE_UNRELIABLE, MsgIdSayText, _, Player ); 
		write_byte( Client ); 
		write_string( Message ); 
		message_end( ); 
	} 

	return PLUGIN_HANDLED; 
} 

bool:IsValidMessage( const Said[ ] ) 
{ 
	for( new Index = 0; Said[ Index ]; Index++ ) 
	{ 
		if( Said[ Index ] != ' ' ) 
		{ 
			return true; 
		} 
	} 
	
	return false; 
} 