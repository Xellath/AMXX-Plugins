#include < amxmodx >
#include < hamsandwich >
#include < dbm_api >

const TaskIdRespawn = 8225;

enum _:RingType
{
	_Ring_Bronze,
	_Ring_Silver,
	_Ring_Gold
};

new ItemPointer[ RingType ];

new HasItem[ MaxSlots + 1 ][ RingType ];

public plugin_init( )
{
	register_plugin( "Diablo Mod Item: Sorcerer Rings", "0.0.1", "Xellath" );
	
	ItemPointer[ _Ring_Bronze ] = DBM_RegisterItem(
		"ITEM_RING_BRONZE_NAME",
		"ITEM_RING_BRONZE_DESC",
		0,
		20,
		_Common,
		255
		);
	
	ItemPointer[ _Ring_Gold ] = DBM_RegisterItem(
		"ITEM_RING_GOLD_NAME",
		"ITEM_RING_GOLD_DESC",
		10,
		25,
		_Unique,
		75
		);
	
	ItemPointer[ _Ring_Silver ] = DBM_RegisterItem(
		"ITEM_RING_SILVER_NAME",
		"ITEM_RING_SILVER_DESC",
		0,
		30,
		_Rare,
		150
		);
		
	RegisterHam( Ham_Killed, "player", "Forward_Ham_ClientKilled" );
}

public client_disconnect( Client )
{
	for( new RingIndex; RingIndex < RingType; RingIndex++ )
	{
		HasItem[ Client ][ RingIndex ] = false;
	}
}

public Forward_DBM_ItemReceived( const Client, const ItemIndex )
{
	for( new RingIndex; RingIndex < RingType; RingIndex++ )
	{
		if( ItemIndex == ItemPointer[ RingIndex ] )
		{
			HasItem[ Client ][ RingIndex ] = true;
			
			break;
		}
	}
}

public Forward_DBM_ItemDispatched( const Client, const ItemIndex )
{
	for( new RingIndex; RingIndex < RingType; RingIndex++ )
	{
		if( ItemIndex == ItemPointer[ RingIndex ] )
		{
			HasItem[ Client ][ RingIndex ] = false;
			
			break;
		}
	}
}

public Forward_Ham_ClientKilled( Client, Killer, ShouldGib )
{
	for( new RingIndex; RingIndex < RingType; RingIndex++ )
	{
		if( HasItem[ Client ][ RingIndex ] )
		{
			if( random_num( 1, 100 ) <= DBM_GetItemStat( ItemPointer[ RingIndex ] ) )
			{
				set_task( 1.0, "TaskDelayedRespawn", Client + TaskIdRespawn );
				
				break;
			}
		}
	}
}

public TaskDelayedRespawn( TaskId )
{
	new Client = TaskId - TaskIdRespawn;
	
	ExecuteHamB( Ham_Spawn, Client );
}