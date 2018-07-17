#include < amxmodx >
#include < hamsandwich >
#include < dbm_api >

enum _:StatBoostType
{
	_Boost_Minor,
	_Boost_Major,
	_Boost_Super
};

new ItemPointer[ StatBoostType ];

new bool:BoostRecieved[ MaxSlots + 1 ];

public plugin_init( )
{
	register_plugin( "Diablo Mod Item: Stat Boosts", "0.0.1", "Xellath" );
	
	ItemPointer[ _Boost_Minor ] = DBM_RegisterItem(
		"ITEM_STATBOOST_MINOR_NAME",
		"ITEM_STATBOOST_MINOR_DESC",
		0,
		5,
		_Common,
		255
		);
	
	ItemPointer[ _Boost_Major ] = DBM_RegisterItem(
		"ITEM_STATBOOST_MAJOR_NAME",
		"ITEM_STATBOOST_MAJOR_DESC",
		10,
		10,
		_Unique,
		75
		);
	
	ItemPointer[ _Boost_Super ] = DBM_RegisterItem(
		"ITEM_STATBOOST_RARE_NAME",
		"ITEM_STATBOOST_RARE_DESC",
		0,
		15,
		_Rare,
		150
		);
}

public client_disconnect( Client )
{
	BoostRecieved[ Client ] = false;
}

public Forward_DBM_ItemReceived( const Client, const ItemIndex )
{
	for( new StatIndex; StatIndex < StatBoostType; StatIndex++ )
	{
		if( ItemIndex == ItemPointer[ StatIndex ] )
		{
			for( new Stat = _Stat_Intelligence; Stat <= _Stat_Regeneration; Stat++ )
			{
				DBM_StatBoost( Client, Stat, _Stat_Increase, DBM_GetItemStat( ItemPointer[ StatIndex ] ) );
			}
			
			BoostRecieved[ Client ] = true;
			
			break;
		}
	}
}

public Forward_DBM_ItemDispatched( const Client, const ItemIndex )
{
	for( new StatIndex; StatIndex < StatBoostType; StatIndex++ )
	{
		if( ItemIndex == ItemPointer[ StatIndex ] )
		{
			for( new Stat = _Stat_Intelligence; Stat <= _Stat_Regeneration; Stat++ )
			{
				DBM_StatBoost( Client, Stat, _Stat_Decrease, DBM_GetItemStat( ItemPointer[ StatIndex ] ) );
			}
			
			BoostRecieved[ Client ] = false;
			
			break;
		}
	}
}