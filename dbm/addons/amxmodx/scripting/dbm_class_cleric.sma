#include < amxmodx >
#include < cstrike >
#include < engine >
#include < hamsandwich >
#include < fun >
#include < colorchat >
#include < dbm_api >

const TaskIdResolute = 7669;

new ClassPointer;

new bool:IsCleric[ MaxSlots + 1 ];
new bool:HasResolute[ MaxSlots + 1 ];

new CurrentLoop[ MaxSlots + 1 ];

new SpriteResolute;

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Class: Cleric", "0.0.1", "Xellath" );
	
	register_dictionary_colored( "dbm_class_lang.txt" );
	
	new StatData[ StatStruct ];
	StatData[ _Stat_Intelligence ] = 400;
	StatData[ _Stat_Stamina ] = 100;
	StatData[ _Stat_Dexterity ] = 100;
	StatData[ _Stat_Agility ] = 50;
	StatData[ _Stat_Regeneration ] = 300;
	
	ClassPointer = DBM_RegisterClass( 
		"CLASS_CLERIC_NAME", 
		"CLASS_CLERIC_DESC", 
		"cleric", 
		"CLASS_CLERIC_ABI", 
		"CLASS_CLERIC_ABI_DESC", 
		_Bronze, 
		20.0, 
		true, 
		StatData 
		);
	
	MaxPlayers = get_maxplayers( );
	
	RegisterHam( Ham_TakeDamage, "player", "Forward_Ham_TakeDamage_Pre" );
}

public plugin_precache( )
{
	SpriteResolute = precache_model( "sprites/white.spr" );
}

public Forward_DBM_ClassSelected( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsCleric[ Client ] = true;
		
		HasResolute[ Client ] = false;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_ClassChanged( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsCleric[ Client ] = false;
		
		HasResolute[ Client ] = false;
		
		remove_task( Client + TaskIdResolute );
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_AbilityLoaded( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		HasResolute[ Client ] = true;
	
		new Text[ TextLength ];
		formatex( Text, charsmax( Text ),
				"%L %L!",
				Client,
				"CLASS_CLERIC_ABI",
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
		if( HasResolute[ Client ] )
		{
			formatex( Text, charsmax( Text ),
				"%L %L!",
				Client,
				"CLASS_CLERIC_ABI",
				Client,
				"CLASS_ABILITY_ACTIVE"
				);
			
			DBM_SkillHudText( Client, 2.0, Text );
			
			HasResolute[ Client ] = false;
			
			CurrentLoop[ Client ] = 1;
			
			set_task( 1.0, "TaskLoopDivineResolute", Client + TaskIdResolute, _, _, "a", 15 );
			
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

public TaskLoopDivineResolute( TaskId )
{
	new Client = TaskId - TaskIdResolute;
	
	if( is_user_alive( Client ) )
	{		
		new Origin[ 3 ];
		get_user_origin( Client, Origin );

		message_begin( MSG_BROADCAST, SVC_TEMPENTITY, Origin );
		{
			write_byte( TE_BEAMCYLINDER );
			write_coord( Origin[ 0 ] );
			write_coord( Origin[ 1 ] );
			write_coord( Origin[ 2 ] );
			write_coord( Origin[ 0 ] );
			write_coord( Origin[ 1 ] + 500 );
			write_coord( Origin[ 2 ] + 500 );
			write_short( SpriteResolute );
			write_byte( 0 );
			write_byte( 0 );
			write_byte( 10 );
			write_byte( 120 );
			write_byte( 255 );
			write_byte( 255 );
			write_byte( 140 );
			write_byte( 0 );
			write_byte( 100 );
			write_byte( 4 );
		}
		message_end( );

		new Player = -1;
		new Float:FloatOrigin[ 3 ];
		IVecFVec( Origin, FloatOrigin );
		
		while( ( Player = find_ent_in_sphere( Player, FloatOrigin, 500.0 ) ) )
		{
			if( 1 <= Player <= MaxPlayers
			&& is_user_alive( Player ) 
			&& cs_get_user_team( Client ) == cs_get_user_team( Player ) )
			{
				new Float:MaxHealth = entity_get_float( Player, EV_FL_max_health );
				new Float:Health = entity_get_float( Player, EV_FL_health );
				new Float:GainedHealth = 15.0 + ( DBM_GetTotalStats( Client, _Stat_Intelligence ) * 0.2 );
				if( ( Health + GainedHealth ) < MaxHealth )
				{
					entity_set_float( Player, EV_FL_health, Health + GainedHealth );
				}
				else
				{
					entity_set_float( Player, EV_FL_health, MaxHealth );
				}
			}
		}
		
		CurrentLoop[ Client ]++;
		
		if( CurrentLoop[ Client ] == 15 )
		{
			new Text[ TextLength ];
			formatex( Text, charsmax( Text ),
				"%L %L!",
				Client,
				"CLASS_CLERIC_ABI",
				Client,
				"CLASS_ABILITY_ENDED"
				);
		
			DBM_SkillHudText( Client, 2.0, Text );
		}
	}
	else
	{
		remove_task( Client + TaskIdResolute );
	}
}

public Forward_Ham_TakeDamage_Pre( Victim, Inflictor, Attacker, Float:Damage, Damagebits )
{
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& cs_get_user_team( Attacker ) == cs_get_user_team( Victim )
	&& IsCleric[ Attacker ]
	&& Damagebits & ( DMG_BULLET | DMG_NEVERGIB ) )
	{
		new Float:CurHealth = entity_get_float( Victim, EV_FL_health );
		new Float:MaxHealth = entity_get_float( Victim, EV_FL_max_health );
		if( get_user_weapon( Attacker ) == CSW_KNIFE )
		{
			if( ( CurHealth + ( Damage * 0.15 ) ) <= MaxHealth )
			{
				entity_set_float( Victim, EV_FL_health, ( CurHealth + ( Damage * 0.15 ) ) );
			}
			else
			{
				entity_set_float( Victim, EV_FL_health, MaxHealth );
			}
		}
		else
		{
			if( ( CurHealth + ( Damage * 0.1 ) ) <= MaxHealth )
			{
				entity_set_float( Victim, EV_FL_health, ( CurHealth + ( Damage * 0.1 ) ) );
			}
			else
			{
				entity_set_float( Victim, EV_FL_health, MaxHealth );
			}
		}
	}
}