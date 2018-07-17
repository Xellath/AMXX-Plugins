#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >
#include < dbm_api >

const NOCLIP_WPN_BS = ( ( 1 << 2 ) | ( 1 << CSW_HEGRENADE ) | ( 1 << CSW_SMOKEGRENADE ) | ( 1 << CSW_FLASHBANG ) | ( 1 << CSW_KNIFE ) | ( 1 << CSW_C4 ) );
const SHOTGUNS_BS = ( ( 1 << CSW_M3 ) | ( 1 << CSW_XM1014 ) );

const m_pPlayer = 41;
const m_iId = 43;
const m_flTimeWeaponIdle = 48;
const m_fInReload = 54;
const m_flNextAttack = 83;

new const Float:WeaponDelay[ CSW_P90 + 1 ] =
{
    0.00, 2.70, 0.00, 2.00, 0.00, 0.55, 0.00, 3.15, 3.30, 0.00, 4.50, 
	2.70, 3.50, 3.35, 2.45, 3.30, 2.70, 2.20, 2.50, 2.63, 4.70, 
	0.55, 3.05, 2.12, 3.50, 0.00, 2.20, 3.00, 2.45, 0.00, 3.40
};

enum _:Gloves
{
	Float:_Glove_Bronze,
	Float:_Glove_Gold,
	Float:_Glove_Silver
};

new const Float:WeaponReloadRatio[ Gloves ] =
{
	0.9,
	0.8,
	0.7
};

new ItemPointer[ Gloves ];

new bool:HasItem[ MaxSlots + 1 ][ Gloves ];

new MsgIdBarTime2;

public plugin_init( )
{
	register_plugin( "Diablo Mod Item: Gloves", "0.0.1", "Xellath" );
	
	ItemPointer[ _Glove_Bronze ] = DBM_RegisterItem(
		"ITEM_GLOVE_BRONZE_NAME",
		"ITEM_GLOVE_BRONZE_DESC",
		0,
		10,
		_Common,
		255
		);
	
	ItemPointer[ _Glove_Gold ] = DBM_RegisterItem(
		"ITEM_GLOVE_GOLD_NAME",
		"ITEM_GLOVE_GOLD_DESC",
		4,
		20,
		_Unique,
		75
		);
	
	ItemPointer[ _Glove_Silver ] = DBM_RegisterItem(
		"ITEM_GLOVE_SILVER_NAME",
		"ITEM_GLOVE_SILVER_DESC",
		0,
		30,
		_Rare,
		150
		);
	
	new Weapon[ 17 ];
	for( new WeaponIndex = 1; WeaponIndex <= CSW_P90; WeaponIndex++ )
	{
		if(	!( NOCLIP_WPN_BS & ( 1 << WeaponIndex ) )
		&& !( SHOTGUNS_BS & ( 1 << WeaponIndex ) )
		&& get_weaponname( WeaponIndex, Weapon, charsmax( Weapon ) ) )
		{
			RegisterHam( Ham_Weapon_Reload, Weapon, "Forward_Ham_Weapon_Reload", 1 );
			RegisterHam( Ham_Item_Holster, Weapon, "Forward_Ham_Item_Holster" );
			RegisterHam( Ham_Item_PostFrame, Weapon, "Forward_Ham_Item_PostFrame", 1 );
		}
	}
	
	MsgIdBarTime2 = get_user_msgid( "BarTime2" );
}

public client_disconnect( Client )
{
	for( new GloveIndex; GloveIndex < Gloves; GloveIndex++ )
	{
		HasItem[ Client ][ GloveIndex ] = false;
	}
}

public Forward_DBM_ItemReceived( const Client, const ItemIndex )
{
	for( new GloveIndex; GloveIndex < Gloves; GloveIndex++ )
	{
		if( ItemIndex == ItemPointer[ GloveIndex ] )
		{
			HasItem[ Client ][ GloveIndex ] = true;
			
			break;
		}
	}
}

public Forward_DBM_ItemDispatched( const Client, const ItemIndex )
{
	for( new GloveIndex; GloveIndex < Gloves; GloveIndex++ )
	{
		if( ItemIndex == ItemPointer[ GloveIndex ] )
		{
			HasItem[ Client ][ GloveIndex ] = false;
			
			break;
		}
	}
}

public Forward_Ham_Weapon_Reload( Entity )
{
	if( get_pdata_int( Entity, m_fInReload, 4 ) )
	{
		new Client = get_pdata_cbase( Entity, m_pPlayer, 4 );
		new Float:NextAttack = get_pdata_float( Client, m_flNextAttack, 5 );
		new Seconds;
		for( new GloveIndex; GloveIndex < Gloves; GloveIndex++ )
		{
			if( HasItem[ Client ][ GloveIndex ] )
			{
				NextAttack = get_pdata_float( Client, m_flNextAttack, 5 );
				Seconds = floatround( NextAttack, floatround_ceil );
				UTIL_BarTime2( Client, Seconds, 100 - floatround( ( NextAttack / Seconds ) * 100 ) );
			}
		}
	}
}

public Forward_Ham_Item_Holster( Entity )
{
	if( get_pdata_int( Entity, m_fInReload, 4 ) )
	{
		UTIL_BarTime2( get_pdata_cbase( Entity, m_pPlayer, 4 ), 0, 0 );
	}
}

public Forward_Ham_Item_PostFrame( Entity )
{    
	if( get_pdata_int( Entity, m_fInReload, 4 ) )
	{
		new Client = get_pdata_cbase( Entity, m_pPlayer, 4 );
		new Float:Delay = WeaponDelay[ get_pdata_int( Entity, m_iId, 4 ) ];
		for( new GloveIndex; GloveIndex < Gloves; GloveIndex++ )
		{
			if( HasItem[ Client ][ GloveIndex ] )
			{
				Delay = WeaponDelay[ get_pdata_int( Entity, m_iId, 4 ) ] * WeaponReloadRatio[ GloveIndex ];
				set_pdata_float( Client, m_flNextAttack, Delay, 5 );
				set_pdata_float( Entity, m_flTimeWeaponIdle, Delay + 0.5, 4 );
				
				break;
			}
		}
	}
}

UTIL_BarTime2( const Client, const Duration, const Percent )
{
	message_begin( MSG_ONE_UNRELIABLE, MsgIdBarTime2, _, Client );
	{
		write_byte( Duration );
		write_byte( Percent );
	}
	message_end( );
}