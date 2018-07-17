#include < amxmodx >
#include < engine >
#include < fun >
#include < dbm_api >

new ItemPointer;

new bool:HasItem[ MaxSlots + 1 ];

public plugin_init( )
{
	register_plugin( "Diablo Mod Item: Stalker", "0.0.1", "Xellath" );
	
	ItemPointer = DBM_RegisterItem(
		"ITEM_STALKER_NAME",
		"ITEM_STALKER_DESC",
		0,
		0,
		_Rare,
		150
		);
}

public client_disconnect( Client ) 
{
	HasItem[ Client ] = false;
}

public Forward_DBM_ItemReceived( const Client, const ItemIndex )
{
	if( ItemIndex == ItemPointer )
	{
		HasItem[ Client ] = true;
		
		if( is_user_alive( Client ) )
		{
			new Float:Health = entity_get_float( Client, EV_FL_health );
			entity_set_float( Client, EV_FL_health, ( Health * 0.05 ) );
			
			set_user_rendering( Client, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 5 );
		}
	}
}

public Forward_DBM_ItemDispatched( const Client, const ItemIndex )
{
	if( ItemIndex == ItemPointer )
	{
		if( is_user_alive( Client ) )
		{
			new Float:Health = entity_get_float( Client, EV_FL_health );
			new Float:MaxHealth = entity_get_float( Client, EV_FL_max_health );
			if( ( Health + 15.0 ) < MaxHealth )
			{
				entity_set_float( Client, EV_FL_health, ( Health + 15.0 ) );
			}
			else
			{
				entity_set_float( Client, EV_FL_health, MaxHealth );
			}
		}
		
		set_user_rendering( Client );
		
		HasItem[ Client ] = false;
	}
}

public Forward_DBM_ClientSpawned( const Client, const ClassIndex )
{
	if( HasItem[ Client ] )
	{
		new Float:MaxHealth = entity_get_float( Client, EV_FL_max_health );
		entity_set_float( Client, EV_FL_health, ( MaxHealth * 0.05 ) );
		
		set_user_rendering( Client, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 5 );
	}
}