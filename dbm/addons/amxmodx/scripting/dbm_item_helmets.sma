#include < amxmodx >
#include < fakemeta >
#include < cstrike >
#include < engine >
#include < dbm_api >

enum _:Helmets
{
	_Helmet_Giant,
	_Helmet_Colossus,
	_Helmet_Titan,
};

new ItemPointer[ Helmets ];

new bool:HasItem[ MaxSlots + 1 ][ Helmets ];

new MsgIdScreenShake;

new MaxPlayers;

public plugin_init()
{
	register_plugin( "Diablo Mod Item: Helmets", "0.0.1", "Xellath" );
	
	ItemPointer[ _Helmet_Giant ] = DBM_RegisterItem(
		"ITEM_HELMET_GIANT_NAME",
		"ITEM_HELMET_GIANT_DESC",
		0,
		20,
		_Common,
		255
		);
	
	ItemPointer[ _Helmet_Colossus ] = DBM_RegisterItem(
		"ITEM_HELMET_COLOSSUS_NAME",
		"ITEM_HELMET_COLOSSUS_DESC",
		9,
		50,
		_Unique,
		75
		);
	
	ItemPointer[ _Helmet_Titan ] = DBM_RegisterItem(
		"ITEM_HELMET_TITAN_NAME",
		"ITEM_HELMET_TITAN_DESC",
		0,
		75,
		_Rare,
		150
		);
	
	register_forward( FM_TraceLine, "Forward_FM_TraceLine_Post", 1 );
	
	MsgIdScreenShake = get_user_msgid( "ScreenShake" );
	
	MaxPlayers = get_maxplayers( );
}

public client_disconnect( Client )
{
	for( new HelmetIndex; HelmetIndex < Helmets; HelmetIndex++ )
	{
		HasItem[ Client ][ HelmetIndex ] = false;
	}
}

public Forward_DBM_ItemReceived( const Client, const ItemIndex )
{
	for( new HelmetIndex; HelmetIndex < Helmets; HelmetIndex++ )
	{
		if( ItemIndex == ItemPointer[ HelmetIndex ] )
		{
			HasItem[ Client ][ HelmetIndex ] = true;
			
			break;
		}
	}
}

public Forward_DBM_ItemDispatched( const Client, const ItemIndex )
{
	for( new HelmetIndex; HelmetIndex < Helmets; HelmetIndex++ )
	{
		if( ItemIndex == ItemPointer[ HelmetIndex ] )
		{
			HasItem[ Client ][ HelmetIndex ] = false;
			
			break;
		}
	}
}

public Forward_FM_TraceLine( Float:VectorStart[ 3 ], Float:VectorEnd[ 3 ], IgnoreMonsters, Client, TraceHandle )
{
	if( !is_user_alive( Client )
	|| is_user_bot( Client ) )
	{
		return FMRES_IGNORED;
	}
	
	new TraceHit = get_tr2( TraceHandle, TR_pHit );	
	if( !( entity_get_int( Client, EV_INT_button ) & IN_ATTACK )
	|| !( entity_get_int( Client, EV_INT_button ) & IN_ATTACK2 ) )
	{
		return FMRES_IGNORED;
	}
	
	if( 1 <= TraceHit <= MaxPlayers 
	&& is_user_alive( TraceHit ) )
	{
		for( new HelmetIndex; HelmetIndex < Helmets; HelmetIndex++ )
		{
			if( HasItem[ TraceHit ][ HelmetIndex ] )
			{
				if( random_num( 1, 100 ) <= DBM_GetItemStat( ItemPointer[ HelmetIndex ] ) )
				{
					set_tr2( TraceHandle, TR_iHitgroup, 8 );
					
					message_begin( MSG_ONE_UNRELIABLE, MsgIdScreenShake, _ , TraceHit );
					{
						write_short( 1<<14 );
						write_short( 1<<12 );
						write_short( 1<<14 );
					}
					message_end( );
				}
			}
		}
	}
	else if( is_valid_ent( TraceHit ) )
	{
		return FMRES_IGNORED;
	}
	
	return FMRES_IGNORED;
}