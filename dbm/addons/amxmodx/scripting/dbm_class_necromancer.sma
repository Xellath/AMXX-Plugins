#include < amxmodx >
#include < cstrike >
#include < engine >
#include < hamsandwich >
#include < fun >
#include < colorchat >
#include < dbm_api >

const TaskIdDevour = 6899;

new ClassPointer;

new bool:IsNecromancer[ MaxSlots + 1 ];

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Class: Necromancer", "0.0.1", "Xellath" );
	
	register_dictionary_colored( "dbm_class_lang.txt" );
	
	new StatData[ StatStruct ];
	StatData[ _Stat_Intelligence ] = 400;
	StatData[ _Stat_Stamina ] = 150;
	StatData[ _Stat_Dexterity ] = 300;
	StatData[ _Stat_Agility ] = 100;
	StatData[ _Stat_Regeneration ] = 300;
	
	ClassPointer = DBM_RegisterClass( 
		"CLASS_NECROMANCER_NAME", 
		"CLASS_NECROMANCER_DESC", 
		"necromancer", 
		"CLASS_NECROMANCER_ABI", 
		"CLASS_NECROMANCER_ABI_DESC", 
		_Bronze, 
		0.0, 
		false, 
		StatData 
		);
		
	register_event( "DeathMsg", "Event_DeathMsg", "a" );
	
	RegisterHam( Ham_TakeDamage, "player", "Forward_Ham_TakeDamage_Pre" );
	
	MaxPlayers = get_maxplayers( );
}

public Forward_DBM_ClassSelected( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsNecromancer[ Client ] = true;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_ClassChanged( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsNecromancer[ Client ] = false;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_AbilityUse( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		new Float:Origin[ 3 ];
		entity_get_vector( Client, EV_VEC_origin, Origin );
		
		new Text[ TextLength ];
		
		new TargetEntity = FindFakeCorpse( Origin );
		if( is_valid_ent( TargetEntity )
		&& TargetEntity != 0 )
		{
			new TargetPlayer = entity_get_edict( TargetEntity, EV_ENT_owner );
			new TargetPlayerTeam = entity_get_int( TargetEntity, EV_INT_iuser1 );
			if( 1 <= TargetPlayer <= MaxPlayers
			&& is_user_connected( TargetPlayer ) )
			{
				new PlayerName[ MaxSlots ];
				get_user_name( TargetPlayer, PlayerName, charsmax( PlayerName ) );
				
				formatex( Text, charsmax( Text ),
					"%L",
					Client,
					"CLASS_NECROMANCER_SPECIAL",
					PlayerName
					);
				
				DBM_SkillHudText( Client, 1.5, Text );
				
				set_entity_flags( Client, FL_FROZEN, 1 );	
				
				set_user_godmode( Client, 1 );
				set_user_rendering( Client, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 25 ); 
				
				remove_entity( TargetEntity );
				
				new Data[ 2 ];
				Data[ 0 ] = TargetPlayer;
				Data[ 1 ] = TargetPlayerTeam;
				set_task( 3.0, "TaskDevourFinished", Client + TaskIdDevour, Data, sizeof( Data ) );
			}
		}
		else
		{
			formatex( Text, charsmax( Text ),
				"%L",
				Client,
				"CLASS_NECROMANCER_SPECIAL2"
				);
		
			DBM_SkillHudText( Client, 0.4, Text );
		}
	}
}

public TaskDevourFinished( Data[ ], TaskId )
{
	new Client = TaskId - TaskIdDevour;
	set_entity_flags( Client, FL_FROZEN, 0 );
	
	set_user_godmode( Client );
	set_user_rendering( Client );
	
	new Player = Data[ 0 ];
	new PlayerTeam = Data[ 1 ];
	
	new Text[ TextLength ];
	
	new PlayerName[ MaxSlots ];
	get_user_name( Player, PlayerName, charsmax( PlayerName ) );
	if( CsTeams:PlayerTeam == cs_get_user_team( Client ) )
	{
		ExecuteHamB( Ham_Spawn, Player );
		
		formatex( Text, charsmax( Text ),
			"%L",
			Client,
			"CLASS_NECROMANCER_SPECIAL3",
			PlayerName
			);
		
		DBM_SkillHudText( Client, 1.5, Text );
	}
	else
	{
		new Class = DBM_GetClientClass( Client );
		new Experience = random_num( 40, 80 );
		DBM_SetClassExperience( Client, Class, ( DBM_GetClassExperience( Client, Class ) + Experience ) );
		
		formatex( Text, charsmax( Text ),
			"%L",
			Client,
			"CLASS_NECROMANCER_SPECIAL4",
			PlayerName,
			Experience
			);
		
		DBM_SkillHudText( Client, 1.5, Text );
	}
}

public Forward_Ham_TakeDamage_Pre( Victim, Inflictor, Attacker, Float:Damage, Damagebits )
{
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& is_user_connected( Attacker )
	&& is_user_connected( Victim )
	&& IsNecromancer[ Attacker ] )
	{
		new Float:HealthGained = Damage * random_float( 0.1, 0.3 );
		new Float:CurrentHealth = entity_get_float( Attacker, EV_FL_health ); 
		new Float:MaxHealth = entity_get_float( Attacker, EV_FL_max_health );
		if( ( CurrentHealth + HealthGained ) < MaxHealth )
		{
			entity_set_float( Attacker, EV_FL_health, CurrentHealth + HealthGained );
		}
		else if( ( CurrentHealth + HealthGained ) > MaxHealth )
		{
			entity_set_float( Attacker, EV_FL_health, MaxHealth );
		}
	}
}

public Event_DeathMsg( )
{
	new Victim = read_data( 2 );
	if( 1 <= Victim <= MaxPlayers
	&& is_user_connected( Victim ) )
	{
		new Float:Origin[ 3 ];
		entity_get_vector( Victim, EV_VEC_origin, Origin );
		
		DispatchFakeCorpse( Victim, Origin, cs_get_user_team( Victim ) );
	}
}

DispatchFakeCorpse( const Client, const Float:Origin[ 3 ], CsTeams:Team )
{
	new Entity = create_entity( "info_target" );
	entity_set_string( Entity, EV_SZ_classname, "fake_corpse" );
	
	entity_set_int( Entity, EV_INT_solid, SOLID_NOT );
	entity_set_int( Entity, EV_INT_movetype, MOVETYPE_NONE );
	
	entity_set_origin( Entity, Origin );
	
	new Float:Mins[ 3 ] = { -5.920000, -10.260000, -4.970000 };
	new Float:Maxs[ 3 ] = { 5.700000, 1.410000, 5.080000 };
	entity_set_size( Entity, Mins, Maxs );
	
	entity_set_edict( Entity, EV_ENT_owner, Client );
	entity_set_int( Entity, EV_INT_iuser1, _:Team );
}

FindFakeCorpse( const Float:Origin[ 3 ] )
{
	new Entity = -1;
	new Classname[ MaxSlots ];	
	while( ( Entity = find_ent_in_sphere( Entity, Origin, 75.0 ) ) != 0 ) 
	{
		entity_get_string( Entity, EV_SZ_classname, Classname, charsmax( Classname ) );
		if( equal( Classname, "fake_corpse" ) )
		{
			return Entity;
		}
	}
	
	return 0;
}