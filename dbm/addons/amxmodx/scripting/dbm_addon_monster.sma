#include < amxmodx >
#include < cstrike >
#include < engine >
#include < hamsandwich >
#include < colorchat >
#include < dbm_api >
#include < round_terminator >

const TaskIdMonsterSpawned = 4320;

const Float:DisplayHUDInterval = 0.5;

const MaxMonsterTypes = 4;

new GlobalRound;
new GlobalMonsters;
new GlobalMonstersKilled;

new bool:RecentlyKilled;

new DisplayHUDThinkEntity;

new DefaultBuyTime;

new CvarMonster;
new CvarExperience;
new CvarRounds;

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Addon: Monster System", "0.0.1", "Xellath" );
	
	if( !is_plugin_loaded( "dbm_core.amxx", true ) )
	{
		set_fail_state( "[ Diablo Mod Monster System ] DBM Core needs to be loaded in order for this plugin to run correctly!" );
	}
	
	// number of monsters is definable by using the constant "MaxMonsterTypes"
	// monsters must be precached in monstermod - otherwise it will most likely crash
	// seperate monsters with a semicolon like the following:
	// monster1;monster2;monster3;monster4
	// note: when testing gargantua it crashes the server
	CvarMonster = register_cvar( "dbm_monster_type", "bullsquid;zombie;houndeye;islave" );
	CvarExperience = register_cvar( "dbm_monster_exp", "1500" );
	
	CvarRounds = register_cvar( "dbm_monster_round_interval", "10" );
	
	DisplayHUDThinkEntity = CreateThinkEntity( "hud_monster_think", DisplayHUDInterval );
	
	register_think( "hud_monster_think", "Forward_Engine_HUDMonsterThink" );
	
	register_logevent( "LogEvent_RoundStart", 2, "1=Round_Start" );
	register_logevent( "LogEvent_RoundEnd", 2, "1=Round_End" );
	
	RegisterHam( Ham_TakeDamage, "func_wall", "Forward_Ham_MTakeDamage_Pre" );
	RegisterHam( Ham_Killed, "func_wall", "Forward_Ham_Killed_Post", 1 );
	
	MaxPlayers = get_maxplayers( );
	
	register_dictionary_colored( "dbm_core_lang.txt" );
	register_dictionary_colored( "dbm_addon_lang.txt" );
	
	DefaultBuyTime = get_cvar_num( "mp_buytime" );
}

public plugin_natives( )
{
	register_native( "DBM_IsMonsterRound", "_DBM_IsMonsterRound" );
}

public bool:_DBM_IsMonsterRound( Plugin, Params )
{
	if( GlobalRound >= get_pcvar_num( CvarRounds ) 
	|| RecentlyKilled )
	{
		return true;
	}
	
	return false;
}

CreateThinkEntity( const ClassName[ ], const Float:Interval = 1.0 )
{
	new Entity = create_entity( "info_target" );
	entity_set_string( Entity, EV_SZ_classname, ClassName );
	
	entity_set_float( Entity, EV_FL_nextthink, get_gametime( ) + Interval );
	
	return Entity;
}

public Forward_Engine_HUDMonsterThink( Entity )
{
	if( is_valid_ent( Entity ) 
	&& DisplayHUDThinkEntity == Entity )
	{
		if( DBM_IsMonsterRound( ) )
		{
			new MonsterEntity = -1;
			new CurrentMonsters[ 18 ]; // 17 is max ( 1 + ( 32 / 2 ) )
			new Increment;
			new Flags;
			while( ( MonsterEntity = find_ent_by_class( MonsterEntity, "func_wall" ) ) )
			{
				Flags = entity_get_int( MonsterEntity, EV_INT_flags );
				if( Flags & FL_MONSTER )
				{
					CurrentMonsters[ Increment++ ] = MonsterEntity;
				}
			}
			
			new Message[ 512 ];
			new Len;
			for( new Client = 1, Monster = 0; Client <= MaxPlayers; Client++ )
			{	
				if( is_user_alive( Client ) )
				{
					Len = formatex( Message, charsmax( Message ) - Len, 
						"%L^n",
						Client,
						"MONSTER_HUD_KILLED",
						GlobalMonstersKilled,
						GlobalMonsters
						);
						
					for( Monster = 0; Monster < Increment; Monster++ )
					{
						Len += formatex( Message[ Len ], charsmax( Message ) - Len, 
							"%L %i %L: %i / %i^n", 
							Client,
							"MONSTER",
							Monster + 1,
							Client,
							"HEALTH",
							floatround( entity_get_float( CurrentMonsters[ Monster ], EV_FL_health ) ),
							floatround( entity_get_float( CurrentMonsters[ Monster ], EV_FL_max_health ) )
							);
					}
					
					set_hudmessage( 255, 255, 0, 0.56, 0.01, 1, 0.1, DisplayHUDInterval, 0.1, 0.1, -1 );
					show_hudmessage( Client, Message );
				}
			}
		}
		
		entity_set_float( Entity, EV_FL_nextthink, get_gametime( ) + DisplayHUDInterval );
	}
}

public LogEvent_RoundStart( )
{
	RecentlyKilled = false;

	if( ++GlobalRound >= get_pcvar_num( CvarRounds ) )
	{
		new Players = get_playersnum( );
		GlobalMonsters = 1 + ( Players / 2 );
		
		GlobalMonstersKilled = 0;
	
		InitiateMonsterSpawn( );
		
		set_cvar_num( "mp_buytime", DefaultBuyTime + 1 );
	}
}

public LogEvent_RoundEnd( )
{
	if( GlobalRound >= get_pcvar_num( CvarRounds ) )
	{
		new Entity = -1;
		new Flags;
		
		while( ( Entity = find_ent_by_class( Entity, "func_wall" ) ) )
		{
			Flags = entity_get_int( Entity, EV_INT_flags );
			if( Flags & FL_MONSTER )
			{
				remove_entity( Entity );
			}
		}
		
		GlobalRound = 0;
		
		RecentlyKilled = true;
		
		set_cvar_num( "mp_buytime", DefaultBuyTime );
	}
}

public Forward_Ham_MTakeDamage_Pre( Victim, Inflictor, Attacker, Float:Damage, Damagebits )
{
	if( 1 <= Attacker <= MaxPlayers
	&& is_user_connected( Attacker ) )
	{
		new Flags = entity_get_int( Victim, EV_INT_flags );
		if( Flags & FL_MONSTER )
		{
			new Class = DBM_GetClientClass( Attacker );
			new Experience = DBM_GetClassExperience( Attacker, Class );
			
			Experience += floatround( Damage );
		
			DBM_SetClassExperience( Attacker, Class, Experience );
		}
	}
}

public Forward_Ham_Killed_Post( Entity, Killer, ShouldGib )
{
	new Flags = entity_get_int( Entity, EV_INT_flags );
	if( Flags & FL_MONSTER )
	{
		new Model[ 64 ];
		entity_get_string( Entity, EV_SZ_model, Model, charsmax( Model ) );
		if( equal( Model, "models/baby_headcrab.mdl" ) )
		{
			return HAM_IGNORED;
		}
		
		new KillerName[ MaxSlots ];
		get_user_name( Killer, KillerName, charsmax( KillerName ) );
		
		new Experience = get_pcvar_num( CvarExperience );
		new Party = DBM_GetClientParty( Killer );
		if( Party > 0 )
		{
			new Members;
			new MemberIds[ MaxPartyMembers + 1 ];
			for( new Player = 1; Player <= MaxPlayers; Player++ )
			{
				client_print_color( Player, DontChange, 
					"^4%L^3 %L",
					Player,
					"MOD_PREFIX",
					Player,
					"MONSTER_KILLED",
					KillerName, 
					Experience 
					);
					
				if( DBM_GetClientParty( Player ) == Party )
				{
					MemberIds[ Members++ ] = Player;
				}
			}
			
			new Exp = floatround( ( Experience * 1.15 ) / Members );
			new PartyPlayer;
			new Class;
			for( new Index = 0; Index < Members; Index++ )
			{
				PartyPlayer = MemberIds[ Index ];
				
				Class = DBM_GetClientClass( PartyPlayer );
				DBM_SetClassExperience( PartyPlayer, Class, ( DBM_GetClassExperience( PartyPlayer, DBM_GetClientClass( PartyPlayer ) ) + Exp ) );
				DBM_CheckLevel( PartyPlayer, Class );
			}
		}
		else
		{
			for( new Player = 1; Player <= MaxPlayers; Player++ )
			{
				client_print_color( Player, DontChange, 
				"^4%L^3 %L",
				Player,
				"MOD_PREFIX",
				Player,
				"MONSTER_KILLED",
				KillerName, 
				Experience 
				);
			}
			
			new Class = DBM_GetClientClass( Killer );
			DBM_SetClassExperience( Killer, Class, ( DBM_GetClassExperience( Killer, Class ) + Experience ) );
			DBM_CheckLevel( Killer, Class );
		}
		
		GlobalMonstersKilled++;
		
		if( GlobalMonstersKilled == GlobalMonsters )
		{
			GlobalRound = 0;
			
			RecentlyKilled = true;
			
			set_cvar_num( "mp_buytime", DefaultBuyTime );
			
			TerminateRound( RoundEndType_Draw );
		}
	}
	
	return HAM_IGNORED;
}

InitiateMonsterSpawn( )
{
	new Players[ MaxSlots ], PlayerCount;
	get_players( Players, PlayerCount, "a" );
	
	if( PlayerCount < 1 )
	{
		return;
	}

	new RandomPlayer = Players[ random( PlayerCount ) ];
	
	new Monster[ 256 ];
	get_pcvar_string( CvarMonster, Monster, charsmax( Monster ) );
	
	new Monsters[ MaxMonsterTypes + 1 ][ MaxSlots ];
	new Increment = 1;
	
	strtok( Monster, Monsters[ 0 ], charsmax( Monsters[ ] ), Monsters[ Increment ], charsmax( Monsters[ ] ), ';', .trimSpaces = 1 );
	
	do
	{
		strtok( Monsters[ Increment ], Monsters[ Increment ], charsmax( Monsters[ ] ), Monsters[ Increment + 1 ], charsmax( Monsters[ ] ), ';', .trimSpaces = 1 );
	}
	while( ++Increment < MaxMonsterTypes );
	
	new PlayerName[ MaxSlots ];
	get_user_name( RandomPlayer, PlayerName, charsmax( PlayerName ) );
	
	server_cmd( "monster ^"%s^" ^"%s^"", Monsters[ random( sizeof( Monsters ) ) ], PlayerName );
	
	set_task( 1.0, "TaskCheckMonsterSpawned", TaskIdMonsterSpawned );
}

public TaskCheckMonsterSpawned( TaskId )
{
	new Entity = -1;
	new Flags;
	new bool:Found;
	new MonstersCount = 0;
	
	while( ( Entity = find_ent_by_class( Entity, "func_wall" ) ) )
	{
		Flags = entity_get_int( Entity, EV_INT_flags );
		if( Flags & FL_MONSTER )
		{
			Found = true;
			
			MonstersCount++;
		}
	}
	
	if( !Found || ( Found && MonstersCount < GlobalMonsters ) )
	{
		InitiateMonsterSpawn( );
	}
	else
	{
		for( new Player = 1; Player <= MaxPlayers; Player++ )
		{
			client_print_color( Player, DontChange, 
				"^4%L^3 %L",
				Player,
				"MOD_PREFIX",
				Player,
				"MONSTER_SPAWNED"
				);
		}
	}
}