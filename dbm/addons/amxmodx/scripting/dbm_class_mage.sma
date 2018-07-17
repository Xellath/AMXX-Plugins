#include < amxmodx >
#include < engine >
#include < cstrike >
#include < hamsandwich >
#include < fakemeta >
#include < fun >
#include < colorchat >
#include < dbm_api >

const TaskIdResetRendering = 3377;

const MaxFireballs = 2;

new const FireballModel[ ] = "models/rpgrocket.mdl";
new const FireballClassName[ ] = "dbm_fireball";

new Fireballs[ MaxSlots + 1 ];

new bool:IsMage[ MaxSlots + 1 ];
new bool:InFlashlight[ MaxSlots + 1 ];

new SpriteExplode;

new SpriteBloodDrop;
new SpriteBloodSpray;

new MaxPlayers;

new ClassPointer;

public plugin_init( )
{
	register_plugin( "Diablo Mod Class: Mage", "0.0.1", "Xellath" );
	
	register_dictionary_colored( "dbm_class_lang.txt" );
	
	new StatData[ StatStruct ];
	StatData[ _Stat_Intelligence ] = 300;
	StatData[ _Stat_Stamina ] = 100;
	StatData[ _Stat_Dexterity ] = 150;
	StatData[ _Stat_Agility ] = 50;
	StatData[ _Stat_Regeneration ] = 200;
	
	ClassPointer = DBM_RegisterClass( 
		"CLASS_MAGE_NAME", 
		"CLASS_MAGE_DESC", 
		"mage", 
		"CLASS_MAGE_ABI", 
		"CLASS_MAGE_ABI_DESC", 
		_Bronze, 
		4.0, 
		true, 
		StatData 
		);
	
	register_forward( FM_Touch, "Forward_FM_FireballTouch" );
	
	register_event( "Flashlight", "Event_Flashlight", "b" );
	
	MaxPlayers = get_maxplayers( );
}

public plugin_precache( )
{
	SpriteExplode = precache_model( "sprites/zerogxplode.spr" );
	
	SpriteBloodDrop = precache_model( "sprites/blood.spr" );
	SpriteBloodSpray = precache_model( "sprites/bloodspray.spr" );
	
	precache_model( FireballModel );
	
	set_cvar_num( "mp_flashlight", 1 );
}

public Forward_DBM_ClassSelected( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsMage[ Client ] = true;
		
		Fireballs[ Client ] = 0;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_ClassChanged( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsMage[ Client ] = false;
		
		Fireballs[ Client ] = 0;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_AbilityLoaded( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		if( Fireballs[ Client ] < MaxFireballs )
		{
			Fireballs[ Client ]++;
			
			new Text[ TextLength ];
			
			new Language[ 3 ];
			get_user_info( Client, "lang", Language, charsmax( Language ) );
			if( equali( Language, "pl" ) )
			{
				new Plural[ 11 ];
				if( 2 <= Fireballs[ Client ] <= MaxFireballs )
				{
					formatex( Plural, charsmax( Plural ), "Kule Ognia" );
				}
				else if( Fireballs[ Client ] <= 1 )
				{
					formatex( Plural, charsmax( Plural ), "Kula Ognia" );
				}
				
				formatex( Text, charsmax( Text ),
					"%s: %i",
					Plural,
					Fireballs[ Client ]
					);
			}
			else
			{
				formatex( Text, charsmax( Text ),
					"%L: %i",
					Client,
					"CLASS_MAGE_ABI_PLURAL",
					Fireballs[ Client ]
					);
			}
			
			DBM_SkillHudText( Client, 0.4, Text );
		}
		else
		{
			DBM_SetClassAbility( Client, ClassIndex, true );
		}
	}
}

public Forward_DBM_AbilityUse( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		new Text[ TextLength ];
		if( Fireballs[ Client ] )
		{
			ShootFireball( Client );
			
			Fireballs[ Client ]--;
			
			new Language[ 3 ];
			get_user_info( Client, "lang", Language, charsmax( Language ) );
			if( equali( Language, "pl" ) )
			{
				new Plural[ 11 ];
				if( 2 <= Fireballs[ Client ] <= MaxFireballs )
				{
					formatex( Plural, charsmax( Plural ), "Kule Ognia" );
				}
				else if( Fireballs[ Client ] <= 1 )
				{
					formatex( Plural, charsmax( Plural ), "Kula Ognia" );
				}
				
				formatex( Text, charsmax( Text ),
					"%s: %i",
					Plural,
					Fireballs[ Client ]
					);
			}
			else
			{
				formatex( Text, charsmax( Text ),
					"%L: %i",
					Client,
					"CLASS_MAGE_ABI_PLURAL",
					Fireballs[ Client ]
					);
			}
			
			DBM_SkillHudText( Client, 0.4, Text );
				
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

public Forward_DBM_ClientSpawned( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		if( IsMage[ Client ] )
		{
			set_user_health( Client, 85 );
		}
	}
}

ShootFireball( const Client )
{
	new Float:ClientOrigin[ 3 ];
	entity_get_vector( Client, EV_VEC_origin, ClientOrigin );
	
	new Entity = create_entity( "info_target" );
	entity_set_model( Entity, FireballModel );
	
	entity_set_origin( Entity, ClientOrigin );
	
	entity_set_int( Entity, EV_INT_effects, EF_LIGHT );
	entity_set_string( Entity, EV_SZ_classname, FireballClassName );
	
	entity_set_int( Entity, EV_INT_solid, SOLID_BBOX );
	entity_set_int( Entity, EV_INT_movetype, MOVETYPE_FLY );
	
	entity_set_edict( Entity, EV_ENT_owner, Client );
	
	new Float:NewVelocity[ 3 ];
	VelocityByAim( Client, 825, NewVelocity );
	entity_set_vector( Entity, EV_VEC_velocity, NewVelocity );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	{
		write_byte( TE_BEAMFOLLOW );
		write_short( Entity );
		write_short( SpriteExplode );
		write_byte( 45 );
		write_byte( 4 );
		write_byte( 255 ); 
		write_byte( 0 );
		write_byte( 0 );
		write_byte( 25 );
	}
	message_end( );
}

public Forward_FM_FireballTouch( Entity, Client )
{
	if( Entity
	&& is_valid_ent( Entity ) )
	{
		new ClassName[ MaxSlots ];
		entity_get_string( Entity, EV_SZ_classname, ClassName, charsmax( ClassName ) );
		
		if( equal( ClassName, FireballClassName ) )
		{
			new Owner = entity_get_edict( Entity, EV_ENT_owner );
			
			new Float:Origin[ 3 ];
			entity_get_vector( Entity, EV_VEC_origin, Origin );
			
			UTIL_Explode( Owner, Entity, Origin, ( 15 + floatround( DBM_GetTotalStats( Owner, _Stat_Intelligence ) * 0.3 ) ), 150.0 );
			
			remove_entity( Entity );
		}
	}
}

public Event_Flashlight( Client )
{
	if( is_user_alive( Client )
	&& IsMage[ Client ] )
	{
		InFlashlight[ Client ] = !InFlashlight[ Client ];
	}
}

public client_PreThink( Client )
{
	if( is_user_alive( Client )
	&& is_plugin_loaded( "dbm_class_ninja.amxx" )
	&& IsMage[ Client ]
	&& InFlashlight[ Client ] )
	{
		new Target;
		new Body;
		get_user_aiming( Client, Target, Body );
		
		if( 1 <= Target <= MaxPlayers
		&& is_user_alive( Target ) 
		&& DBM_GetClientClass( Target ) == DBM_GetIdFromClassName( "CLASS_NINJA_NAME" ) )
		{
			set_user_rendering( Target );
			
			set_task( 5.0, "TaskResetRendering", Target + TaskIdResetRendering );
		}
	}
}

public TaskResetRendering( TaskId )
{
	new Target = TaskId - TaskIdResetRendering;
	
	callfunc_begin( "ResetRendering", "dbm_class_ninja.amxx" );
	{
		callfunc_push_int( Target );
	}
	callfunc_end( );
}

UTIL_Explode( const Client, const Inflictor, const Float:Origin[ 3 ], const Damage, const Float:Radius )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	{
		write_byte( TE_EXPLOSION );
		write_coord( floatround( Origin[ 0 ] ) );
		write_coord( floatround( Origin[ 1 ] ) );
		write_coord( floatround( Origin[ 2 ] ) );
		write_short( SpriteExplode );
		write_byte( 50 );
		write_byte( 15 );
		write_byte( 0 );
	}
	message_end( );
	
	new Entity = -1;
	while( ( Entity = find_ent_in_sphere( Entity, Origin, Radius ) ) )
	{
		if( 1 <= Entity <= MaxPlayers )
		{
			if( cs_get_user_team( Client ) != cs_get_user_team( Entity )
			&& is_user_alive( Entity ) )
			{
				if( float( Damage ) >= entity_get_float( Entity, EV_FL_health )
				&& !DBM_IsMonsterRound( ) )
				{
					ExecuteHamB( Ham_Killed, Entity, Client, 0 );
				}
				else
				{
					ExecuteHamB( Ham_TakeDamage, Entity, Inflictor, Client, float( Damage ), DMG_BLAST );
					
					UTIL_Bleed( Entity, 248 );
				}
			}
		}
		else
		{
			if( entity_get_int( Entity, EV_INT_flags ) & FL_MONSTER )
			{
				if( float( Damage ) >= entity_get_float( Entity, EV_FL_health ) )
				{
					ExecuteHamB( Ham_Killed, Entity, Client, 0 );
				}
				else
				{
					ExecuteHamB( Ham_TakeDamage, Entity, Inflictor, Client, float( Damage ), DMG_BLAST );
				}
			}
		}
	}
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