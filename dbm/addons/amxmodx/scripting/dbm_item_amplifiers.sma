#include < amxmodx >
#include < hamsandwich >
#include < dbm_api >

enum _:Amplifiers
{
	_Amplifier_Bronze,
	_Amplifier_Gold,
	_Amplifier_Silver
};

new ItemPointer[ Amplifiers ];

new bool:HasItem[ MaxSlots + 1 ][ Amplifiers ];

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Item: Amplifiers", "0.0.1", "Xellath" );
	
	ItemPointer[ _Amplifier_Bronze ] = DBM_RegisterItem(
		"ITEM_AMPLIFIER_BRONZE_NAME",
		"ITEM_AMPLIFIER_BRONZE_DESC",
		0,
		3,
		_Common,
		255
		);
	
	ItemPointer[ _Amplifier_Gold ] = DBM_RegisterItem(
		"ITEM_AMPLIFIER_GOLD_NAME",
		"ITEM_AMPLIFIER_GOLD_DESC",
		5,
		6,
		_Unique,
		75
		);
	
	ItemPointer[ _Amplifier_Silver ] = DBM_RegisterItem(
		"ITEM_AMPLIFIER_SILVER_NAME",
		"ITEM_AMPLIFIER_SILVER_DESC",
		0,
		9,
		_Rare,
		150
		);
	
	RegisterHam( Ham_TakeDamage, "player", "Forward_Ham_TakeDamage_Pre" );
	
	MaxPlayers = get_maxplayers( );
}

public client_disconnect( Client )
{
	for( new AmpIndex; AmpIndex < Amplifiers; AmpIndex++ )
	{
		HasItem[ Client ][ AmpIndex ] = false;
	}
}

public Forward_DBM_ItemReceived( const Client, const ItemIndex )
{
	for( new AmpIndex; AmpIndex < Amplifiers; AmpIndex++ )
	{
		if( ItemIndex == ItemPointer[ AmpIndex ] )
		{
			HasItem[ Client ][ AmpIndex ] = true;
			
			break;
		}
	}
}

public Forward_DBM_ItemDispatched( const Client, const ItemIndex )
{
	for( new AmpIndex; AmpIndex < Amplifiers; AmpIndex++ )
	{
		if( ItemIndex == ItemPointer[ AmpIndex ] )
		{
			HasItem[ Client ][ AmpIndex ] = false;
			
			break;
		}
	}
}

public Forward_Ham_TakeDamage_Pre( Victim, Inflictor, Attacker, Float:Damage, Damagebits )
{
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers )
	{
		for( new AmpIndex; AmpIndex < Amplifiers; AmpIndex++ )
		{
			if( HasItem[ Attacker ][ AmpIndex ] )
			{
				SetHamParamFloat( 4, Damage + float( DBM_GetItemStat( ItemPointer[ AmpIndex ] ) ) );
				
				break;
			}
		}
	}
}