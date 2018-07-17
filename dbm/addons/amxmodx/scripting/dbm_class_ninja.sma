#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < fun >
#include < colorchat >
#include < dbm_api >
#include < cl_buy >

const m_pPlayer = 41;
const XTRA_LINUX_OFFS = 4;

const TaskIdSpeed = 4619;

new ClassPointer;

new bool:IsNinja[ MaxSlots + 1 ];
new bool:HasSpeed[ MaxSlots + 1 ];

new Float:Speed[ MaxSlots + 1 ];

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Class: Ninja", "0.0.1", "Xellath" );
	
	register_dictionary_colored( "dbm_class_lang.txt" );
	
	new StatData[ StatStruct ];
	StatData[ _Stat_Intelligence ] = 50;
	StatData[ _Stat_Stamina ] = 150;
	StatData[ _Stat_Dexterity ] = 200;
	StatData[ _Stat_Agility ] = 300;
	StatData[ _Stat_Regeneration ] = 100;
	
	ClassPointer = DBM_RegisterClass( 
		"CLASS_NINJA_NAME", 
		"CLASS_NINJA_DESC", 
		"ninja", 
		"CLASS_NINJA_ABI", 
		"CLASS_NINJA_ABI_DESC", 
		_Bronze, 
		6.0, 
		false, 
		StatData 
		);
	
	RegisterHam( Ham_Item_PreFrame, "player", "Forward_Ham_ItemPreFrame_Post", 1 );
	
	RegisterHam( Ham_Touch, "weaponbox", "Forward_Ham_WeaponboxTouch_Pre" );
	
	new WeaponName[ MaxSlots ];
	for( new WeaponIndex = CSW_P228; WeaponIndex <= CSW_P90; WeaponIndex++ )
	{
		if( WeaponIndex != 2 
		|| WeaponIndex != CSW_KNIFE 
		|| WeaponIndex != CSW_C4 )
		{
			get_weaponname( WeaponIndex, WeaponName, charsmax( WeaponName ) );
			
			RegisterHam( Ham_Weapon_PrimaryAttack, WeaponName, "Forward_Ham_PrimaryAttack_Pre" );
		}
	}
	
	MaxPlayers = get_maxplayers( );
}

public client_disconnect( Client )
{
	IsNinja[ Client ] = false;
}

public client_buy( Client, Item )
{
	if( IsNinja[ Client ]
	&& is_user_alive( Client ) 
	&& 1 <= Client <= MaxPlayers )
	{
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public Forward_DBM_ClassSelected( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsNinja[ Client ] = true;
		
		HasSpeed[ Client ] = false;
		
		Speed[ Client ] = 270.0;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_ClassChanged( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsNinja[ Client ] = false;
		
		HasSpeed[ Client ] = false;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_AbilityLoaded( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		HasSpeed[ Client ] = true;
		
		new Text[ MaxSlots * 2 ];
		formatex( Text, charsmax( Text ),
			"%L %L!",
			Client,
			"CLASS_NINJA_ABI",
			Client,
			"CLASS_ABILITY_READY"
			);
		
		DBM_SkillHudText( Client, 2.0, Text );
		
		DBM_SetClassAbility( Client, ClassIndex, true );
	}
}

public Forward_DBM_AbilityUse( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		new Text[ MaxSlots * 2 ];
		if( HasSpeed[ Client ] )
		{
			Speed[ Client ] = ( get_user_maxspeed( Client ) + 50.0 );
		
			set_user_maxspeed( Client, Speed[ Client ] );
			
			formatex( Text, charsmax( Text ),
				"%L %L^n%L: %0.1f",
				Client,
				"CLASS_NINJA_ABI",
				Client,
				"CLASS_ABILITY_USED",
				Client,
				"CLASS_NINJA_SPECIAL",
				Speed[ Client ]
				);
			
			DBM_SkillHudText( Client, 2.0, Text );
			
			HasSpeed[ Client ] = false;
			
			set_task( 5.0, "TaskRemoveSpeed", Client + TaskIdSpeed );
			
			DBM_SetClassAbility( Client, ClassIndex );
		}
		else
		{
			formatex( Text, charsmax( Text ),
				"%L",
				Client,
				"CLASS_ABILITY_NOT_READY"
				);
		
			DBM_SkillHudText( Client, 0.4, Text );
		}
	}
}

public TaskRemoveSpeed( TaskId )
{
	new Client = TaskId - TaskIdSpeed;
	
	Speed[ Client ] = 270.0;
	
	set_user_maxspeed( Client, Speed[ Client ] );
	
	new Text[ MaxSlots * 2 ];
	formatex( Text, charsmax( Text ),
		"%L %L^n%L: %0.1f",
		Client,
		"CLASS_NINJA_ABI",
		Client,
		"CLASS_ABILITY_ENDED",
		Client,
		"CLASS_NINJA_SPECIAL",
		Speed[ Client ]
		);
	
	DBM_SkillHudText( Client, 2.0, Text );
}

public Forward_Ham_ItemPreFrame_Post( Client )
{
	if( is_user_alive( Client ) 
	&& IsNinja[ Client ]
	&& !DBM_GetFreezetime( ) )
	{
		set_user_maxspeed( Client, Speed[ Client ] );
	}
}

public ResetRendering( Client )
{
	if( IsNinja[ Client ] )
	{
		set_user_rendering( Client, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 15 );
	}
}

public Forward_DBM_ClientSpawned( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		if( IsNinja[ Client ] )
		{
			set_user_health( Client, 170 );
			
			set_user_gravity( Client, 0.4 );
			
			set_user_rendering( Client, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 15 );
			
			if( user_has_weapon( Client, CSW_C4 ) )
			{
				strip_user_weapons( Client );
				give_item( Client, "weapon_knife" );
				
				give_item( Client, "weapon_c4" );
			}
			else
			{
				strip_user_weapons( Client );
				give_item( Client, "weapon_knife" );
			}
			
			Speed[ Client ] = 270.0;
		}
	}
}

public Forward_Ham_PrimaryAttack_Pre( Entity )
{
	new Client = get_pdata_cbase( Entity, m_pPlayer, XTRA_LINUX_OFFS );
	
	if( IsNinja[ Client ] )
	{
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public Forward_Ham_WeaponboxTouch_Pre( Entity, Client )
{
	if( !is_user_alive( Client )
	|| !is_valid_ent( Entity ) )
	{
		return HAM_IGNORED;
	}
	
	new ModelName[ MaxSlots ];
	entity_get_string( Entity, EV_SZ_model, ModelName, charsmax( ModelName ) );
	
	if( IsNinja[ Client ]
	&& !equal( ModelName, "models/w_backpack.mdl" ) )
	{
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}