#include < amxmodx >
#include < hamsandwich >
#include < fun >
#include < engine >
#include < dbm_api >

enum _:Scepters
{
	_Scepter_Bronze,
	_Scepter_Gold,
	_Scepter_Silver
};

new ItemPointer[ Scepters ];

new bool:HasItem[ MaxSlots + 1 ][ Scepters ];

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Item: Vampiric Scepters", "0.0.1", "Xellath" );
	
	ItemPointer[ _Scepter_Bronze ] = DBM_RegisterItem(
		"ITEM_SCEPTER_BRONZE_NAME",
		"ITEM_SCEPTER_BRONZE_DESC",
		0,
		10,
		_Common,
		255
		);
	
	ItemPointer[ _Scepter_Gold ] = DBM_RegisterItem(
		"ITEM_SCEPTER_GOLD_NAME",
		"ITEM_SCEPTER_GOLD_DESC",
		5,
		15,
		_Unique,
		75
		);
	
	ItemPointer[ _Scepter_Silver ] = DBM_RegisterItem(
		"ITEM_SCEPTER_SILVER_NAME",
		"ITEM_SCEPTER_SILVER_DESC",
		0,
		20,
		_Rare,
		150
		);
	
	RegisterHam( Ham_TakeDamage, "player", "Forward_Ham_TakeDamage_Pre" );
	
	MaxPlayers = get_maxplayers( );
}

public client_disconnect( Client )
{
	for( new SceptIndex; SceptIndex < Scepters; SceptIndex++ )
	{
		HasItem[ Client ][ SceptIndex ] = false;
	}
}

public Forward_DBM_ItemReceived( const Client, const ItemIndex )
{
	for( new SceptIndex; SceptIndex < Scepters; SceptIndex++ )
	{
		if( ItemIndex == ItemPointer[ SceptIndex ] )
		{
			HasItem[ Client ][ SceptIndex ] = true;
			
			break;
		}
	}
}

public Forward_DBM_ItemDispatched( const Client, const ItemIndex )
{
	for( new SceptIndex; SceptIndex < Scepters; SceptIndex++ )
	{
		if( ItemIndex == ItemPointer[ SceptIndex ] )
		{
			HasItem[ Client ][ SceptIndex ] = false;
			
			break;
		}
	}
}

public Forward_Ham_TakeDamage_Pre( Victim, Inflictor, Attacker, Float:Damage, Damagebits )
{
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& is_user_connected( Attacker )
	&& is_user_connected( Victim ) )
	{
		for( new SceptIndex; SceptIndex < Scepters; SceptIndex++ )
		{
			if( HasItem[ Attacker ][ SceptIndex ] )
			{
				new Float:HealthGained = Damage * ( DBM_GetItemStat( ItemPointer[ SceptIndex ] ) / 100 );
				new Float:CurrentHealth = entity_get_float( Attacker, EV_FL_health ); 
				new Float:MaxHealth = entity_get_float( Attacker, EV_FL_max_health );
				if( ( CurrentHealth + HealthGained ) < MaxHealth )
				{
					entity_set_float( Attacker, EV_FL_health, CurrentHealth + HealthGained );
				}
				else if( ( CurrentHealth + HealthGained ) > MaxHealth )
				{
					entity_set_float( Attacker, EV_FL_health, MaxHealth );
				}
				
				break;
			}
		}
	}
}