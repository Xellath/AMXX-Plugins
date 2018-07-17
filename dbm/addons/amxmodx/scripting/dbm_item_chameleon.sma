	#include < amxmodx >
#include < cstrike >
#include < fakemeta >
#include < dbm_api >

const MaxModelLen = 16;

new ItemPointer;

new const TeamModels[ CsTeams ][ 4 ][ ] =
{
	{ "", "", "", "" },
	{ "leet", "terror", "guerilla", "arctic" },
	{ "urban", "gsg6", "gign", "sas" },
	{ "", "", "", "" }
};

new CurrentModel[ MaxSlots + 1 ][ MaxModelLen ];

public plugin_init( )
{
	register_plugin( "Diablo Mod Item: Chameleon", "0.0.1", "Xellath" );
	
	ItemPointer = DBM_RegisterItem(
		"ITEM_CHAMELEON_NAME",
		"ITEM_CHAMELEON_DESC",
		0,
		0,
		_Rare,
		150
		);
		
	register_forward( FM_SetClientKeyValue, "Forward_FM_SetClientKeyValue" );
	register_message( get_user_msgid( "ClCorpse" ), "Message_ClCorpse" );
}

public client_disconnect( Client )
{
	CurrentModel[ Client ][ 0 ] = 0;
}

public Forward_DBM_ItemReceived( const Client, const ItemIndex )
{
	if( ItemIndex == ItemPointer )
	{
		switch( cs_get_user_team( Client ) )
		{
			case CS_TEAM_T:
			{
				copy( CurrentModel[ Client ], charsmax( CurrentModel[ ] ), TeamModels[ CS_TEAM_CT ][ random( 4 ) ] );
			}
			case CS_TEAM_CT:
			{
				copy( CurrentModel[ Client ], charsmax( CurrentModel[ ] ), TeamModels[ CS_TEAM_T ][ random( 4 ) ] );
			}
		}
	}
}

public Forward_DBM_ItemDispatched( const Client, const ItemIndex )
{
	if( ItemIndex == ItemPointer )
	{
		copy( CurrentModel[ Client ], charsmax( CurrentModel[ ] ), TeamModels[ cs_get_user_team( Client ) ][ random( 4 ) ] );
		//server_print( "team:model - %i:%s", _:cs_get_user_team( Client ), CurrentModel );
	}
}

public Forward_FM_SetClientKeyValue( Client, const InfoBuffer[ ], const Key[ ], const Value[ ] )
{
	if( equal( Key, "model" ) 
	&& is_user_connected( Client )
	&& CurrentModel[ Client ][ 0 ] )
	{
		set_user_info( Client, "model", CurrentModel[ Client ] );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public Message_ClCorpse( )
{
	new Client = get_msg_arg_int( 12 );
	if( CurrentModel[ Client ][ 0 ] )
	{
		set_msg_arg_string( 1, CurrentModel[ Client ] );
	}
}