#include < amxmodx >
#include < dbm_api >
#include < colorchat >

new const MessageTeammate[ ] = "1 %%c1: %%p2 - %s - %%h: %%i3%%%%";
new const MessageEnemy   [ ] = "1 %%c1: %%p2 - %s";

new Relation;

new MsgIdStatusText;

public plugin_init( )
{
	if( !is_plugin_loaded( "dbm_core.amxx", true ) )
	{
		set_fail_state( "[ Diablo Mod Aim Info ] DBM Core needs to be loaded in order for this plugin to run correctly!" );
	}
	
	register_plugin( "Diablo Mod Addon: Aim Info", "0.0.1", "Xellath" );
	
	register_event( "StatusValue", "EventStatusValue_Relation", "b", "1=1" );
	register_event( "StatusValue", "EventStatusValue_PlayerID", "b", "1=2", "2>0" );
	
	MsgIdStatusText = get_user_msgid( "StatusText" );
	
	register_dictionary_colored( "dbm_core_lang.txt" );
}

public EventStatusValue_Relation( const Client )
{
	Relation = read_data( 2 );
}

public EventStatusValue_PlayerID( const Client )
{
	if( !Relation )
	{
		return;
	}
	
	new Player = read_data( 2 );
	
	new ClassIndex = DBM_GetClientClass( Player );
	new ClassName[ MaxSlots ];
	new ClassLevel = DBM_GetClassLevel( Player, ClassIndex );
	DBM_GetClassName( ClassIndex, ClassName );
	
	new PlayerInfo[ 50 ];
	formatex( PlayerInfo, charsmax( PlayerInfo ),
		"%L : %L - %L : %i",
		Client,
		"CLASS",
		Client,
		ClassName,
		Client,
		"LEVEL",
		ClassLevel
		);
	
	new Message[ 90 ];
	formatex( Message, charsmax( Message ), Relation == 1 ? MessageTeammate : MessageEnemy, PlayerInfo );
	
	Relation = 0;
	
	message_begin( MSG_ONE, MsgIdStatusText, _, Client );
	{
		write_byte( 0 );
		write_string( Message );
	}
	message_end( );
}