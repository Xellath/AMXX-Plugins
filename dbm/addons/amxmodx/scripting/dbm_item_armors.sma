#include < amxmodx >
#include < hamsandwich >
#include < dbm_api >

enum _:Armors
{
	_Armor_Iron,
	_Armor_Godly,
	_Armor_Mithril
};

new ItemPointer[ Armors ];

new bool:HasItem[ MaxSlots + 1 ][ Armors ];

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Item: Armors", "0.0.1", "Xellath" );
	
	ItemPointer[ _Armor_Iron ] = DBM_RegisterItem(
		"ITEM_ARMOR_IRON_NAME",
		"ITEM_ARMOR_IRON_DESC",
		0,
		3,
		_Common,
		255
		);
	
	ItemPointer[ _Armor_Godly ] = DBM_RegisterItem(
		"ITEM_ARMOR_GODLY_NAME",
		"ITEM_ARMOR_GODLY_DESC",
		5,
		6,
		_Unique,
		75
		);
	
	ItemPointer[ _Armor_Mithril ] = DBM_RegisterItem(
		"ITEM_ARMOR_MITHRIL_NAME",
		"ITEM_ARMOR_MITHRIL_DESC",
		0,
		9,
		_Rare,
		150
		);
	
	RegisterHam( Ham_TakeDamage, "player", "Forward_Ham_TakeDamage_Pre" );
	
	MaxPlayers = get_maxplayers( );
}

public Forward_DBM_ItemReceived( const Client, const ItemIndex )
{
	for( new ArmIndex; ArmIndex < Armors; ArmIndex++ )
	{
		if( ItemIndex == ItemPointer[ ArmIndex ] )
		{
			HasItem[ Client ][ ArmIndex ] = true;
			
			break;
		}
	}
}

public Forward_DBM_ItemDispatched( const Client, const ItemIndex )
{
	for( new ArmIndex; ArmIndex < Armors; ArmIndex++ )
	{
		if( ItemIndex == ItemPointer[ ArmIndex ] )
		{
			HasItem[ Client ][ ArmIndex ] = false;
			
			break;
		}
	}
}

public Forward_Ham_TakeDamage_Pre( Victim, Inflictor, Attacker, Float:Damage, Damagebits )
{
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers )
	{
		for( new ArmIndex; ArmIndex < Armors; ArmIndex++ )
		{
			if( HasItem[ Victim ][ ArmIndex ] )
			{
				new Float:FinalDamage = ( Damage - float( DBM_GetItemStat( ItemPointer[ ArmIndex ] ) ) );
				if( FinalDamage < 0.0 )
				{
					FinalDamage = 0.0;
				}
				
				SetHamParamFloat( 4, FinalDamage );
				
				break;
			}
		}
	}
}