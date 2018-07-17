#include < amxmodx >
#include < engine >
#include < hamsandwich >
#include < fun >
#include < colorchat >
#include < dbm_api >

const TaskIdMirror = 3246;

new ClassPointer;

new bool:IsMonk[ MaxSlots + 1 ];
new bool:HasMirror[ MaxSlots + 1 ];
new bool:AbilityActive[ MaxSlots + 1 ];

new SpriteBloodDrop;
new SpriteBloodSpray;

new MsgIdScreenShake;

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Class: Monk", "0.0.1", "Xellath" );
	
	register_dictionary_colored( "dbm_class_lang.txt" );
	
	new StatData[ StatStruct ];
	StatData[ _Stat_Intelligence ] = 100;
	StatData[ _Stat_Stamina ] = 350;
	StatData[ _Stat_Dexterity ] = 100;
	StatData[ _Stat_Agility ] = 200;
	StatData[ _Stat_Regeneration ] = 300;
	
	ClassPointer = DBM_RegisterClass( 
		"CLASS_MONK_NAME", 
		"CLASS_MONK_DESC", 
		"monk", 
		"CLASS_MONK_ABI", 
		"CLASS_MONK_ABI_DESC", 
		_Bronze, 
		20.0, 
		true, 
		StatData 
		);
	
	RegisterHam( Ham_TakeDamage, "player", "Forward_Ham_TakeDamage_Pre" );
	
	MsgIdScreenShake = get_user_msgid( "ScreenShake" );
	
	MaxPlayers = get_maxplayers( );
}

public plugin_precache( )
{
	SpriteBloodDrop = precache_model( "sprites/blood.spr" );
	SpriteBloodSpray = precache_model( "sprites/bloodspray.spr" );
}

public Forward_DBM_ClassSelected( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsMonk[ Client ] = true;
		
		HasMirror[ Client ] = false;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_ClassChanged( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsMonk[ Client ] = false;
		
		HasMirror[ Client ] = false;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_AbilityLoaded( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		HasMirror[ Client ] = true;
		
		new Text[ TextLength ];
		formatex( Text, charsmax( Text ),
			"%L %L!",
			Client,
			"CLASS_MONK_ABI",
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
		new Text[ TextLength ];
		if( HasMirror[ Client ] )
		{
			formatex( Text, charsmax( Text ),
				"%L %L!",
				Client,
				"CLASS_MONK_ABI",
				Client,
				"CLASS_ABILITY_ACTIVE"
				);
			
			DBM_SkillHudText( Client, 2.0, Text );
			
			HasMirror[ Client ] = false;
			
			AbilityActive[ Client ] = true;
			
			set_user_rendering( Client, kRenderFxGlowShell, 139, 137, 137, kRenderNormal, 75 ); 
			
			set_task( 5.0, "TaskEndMirror", Client + TaskIdMirror );
			
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

public TaskEndMirror( TaskId )
{
	new Client = TaskId - TaskIdMirror;
	
	AbilityActive[ Client ] = false;
	
	set_user_rendering( Client ); 
	
	new Text[ TextLength ];
	formatex( Text, charsmax( Text ),
		"%L %L!",
		Client,
		"CLASS_MONK_ABI",
		Client,
		"CLASS_ABILITY_ENDED"
		);
	
	DBM_SkillHudText( Client, 2.0, Text );
}

public Forward_Ham_TakeDamage_Pre( Victim, Inflictor, Attacker, Float:Damage, Damagebits )
{
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& IsMonk[ Victim ]
	&& AbilityActive[ Victim ] )
	{
		if( Damage >= entity_get_float( Attacker, EV_FL_health ) )
		{
			ExecuteHamB( Ham_Killed, Attacker, Victim, 2 );
		}
		else
		{
			ExecuteHamB( Ham_TakeDamage, Attacker, Inflictor, Victim, Damage, DMG_BULLET );
			
			UTIL_Bleed( Attacker, 248 );
			
			message_begin( MSG_ONE_UNRELIABLE, MsgIdScreenShake, _ , Attacker );
			{
				write_short( 1<<14 );
				write_short( 1<<12 );
				write_short( 1<<14 );
			}
			message_end( );
		}
		
		return HAM_SUPERCEDE;
	}
	
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& is_user_alive( Victim )
	&& IsMonk[ Attacker ]
	&& random_num( 1, 100 ) <= 20 )
	{
		new Weapons[ MaxSlots ];
		new WeaponName[ MaxSlots ];
		new WeaponCount;
		get_user_weapons( Victim, Weapons, WeaponCount );
		
		for( new WeaponIndex = 0; WeaponIndex < WeaponCount; WeaponIndex++ )
		{
			get_weaponname( Weapons[ WeaponIndex ], WeaponName, charsmax( WeaponName ) );
			engclient_cmd( Victim, "drop", WeaponName );
		}
		
		engclient_cmd( Victim, "weapon_knife" );
	}
	
	return HAM_IGNORED;
}

UTIL_Bleed( const Client, const Color )
{
	new Origin[ 3 ];
	get_user_origin( Client, Origin );
	
	new xCoord;
	new yCoord; 
	new zCoord;
	
	for( new Index = 0; Index < 3; Index++ ) 
	{
		xCoord = random_num( -15, 15 );
		yCoord = random_num( -15, 15 );
		zCoord = random_num( -20, 25 );
		
		for( new Multiplier = 0; Multiplier < 2; Multiplier++ ) 
		{
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
			{
				write_byte( TE_BLOODSPRITE );
				write_coord( Origin[ 0 ] + ( xCoord * Multiplier ) );
				write_coord( Origin[ 1 ] + ( yCoord * Multiplier ) );
				write_coord( Origin[ 2 ] + ( zCoord * Multiplier ) );
				write_short( SpriteBloodSpray );
				write_short( SpriteBloodDrop );
				write_byte( Color );
				write_byte( 8 );
			}
			message_end( );
		}
	}
}