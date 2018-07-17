#include < amxmodx >
#include < chr_engine >
#include < engine >
#include < colorchat >
#include < dbm_api >

const MaxPets = 12;

new const PetName[ MaxPets ][ MaxSlots ] =
{
	"PET_NAME_HEADCRAB",
	"PET_NAME_RAT",
	"PET_NAME_BAT",
	"PET_NAME_FROG",
	"PET_NAME_FLOATER",
	"PET_NAME_COCKROACH",
	"PET_NAME_HYPERBAT",
	//"PET_NAME_MOM",
	//"PET_NAME_GRUNT",
	"PET_NAME_FISH",
	"PET_NAME_BABYHEADCRAB",
	"PET_NAME_ROACH",
	//"PET_NAME_GARGANTUAN",
	"PET_NAME_BULLSQUID",
	"PET_NAME_HOUNDEYE"//,
	//"PET_NAME_LOADINGMACHINE",
	//"PET_NAME_CONTROLLER"
};

new const PetModel[ MaxPets ][ MaxSlots ] =
{
	"models/headcrab.mdl",
	"models/bigrat.mdl",
	"models/boid.mdl",
	"models/chumtoad.mdl",
	"models/floater.mdl",
	"models/roach.mdl",
	"models/stukabat.mdl",
	//"models/big_mom.mdl",
	//"models/agrunt.mdl",
	"models/archer.mdl",
	"models/baby_headcrab.mdl",
	"models/roach.mdl",
	//"models/garg.mdl",
	"models/bullsquid.mdl",
	"models/houndeye.mdl"//,
	//"models/loader.mdl",
	//"models/controller.mdl"
};

new const PetIdle[ MaxPets ] =
{
	0,
	1,
	0,
	0,
	0,
	1,
	13,
	//0,
	//0,
	0,
	1,
	0,
	//7,
	1,
	1//,
	//3,
	//3
};

new const Float:PetIdleSpeed[ MaxPets ] =
{
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	1.0,
	0.5,
	//1.0,
	//1.0,
	1.0,
	1.0,
	1.0,
	//1.0,
	1.0,
	1.0//,
	//1.0,
	//1.0
};

new const PetRun[ MaxPets ] =
{
	4,
	4,
	0,
	5,
	0,
	0,
	13,
	//3,
	//3,
	6,
	4,
	0,
	//4,
	0,
	3//,
	//2,
	//9
};

new const Float:PetRunSpeed[ MaxPets ] =
{
	2.0,
	6.0,
	3.0,
	0.75,
	1.0,
	1.0,
	13.0,
	//1.0,
	//1.0,
	0.6,
	0.6,
	1.0,
	//1.0,
	2.0,
	1.0//,
	//0.4,
	//1.0
};

new const PetDieAnim[ MaxPets ] =
{
	7,
	7,
	0,
	12,
	0,
	0,
	5,
	//4,
	//22,
	9,
	7,
	1,
	//14,
	16,
	6//,
	//5,
	//18
};

new const Float:PetDieLength[ MaxPets ] =
{
	2.4,
	2.4,
	0.1,
	3.0,
	0.1,
	0.1,
	3.0,
	//5.0,
	//5.0,
	3.0,
	3.0,
	1.0,
	//6.0,
	2.5,
	2.5//,
	//7.0,
	//7.0
};

new const Float:PetMinusStandingZ[ MaxPets ] =
{
	36.0,
	36.0,
	5.0,
	36.0,
	5.0,
	36.0,
	10.0,
	//36.0,
	//36.0,
	20.0,
	36.0,
	36.0,
	//36.0,
	36.0,
	36.0//,
	//36.0,
	//0.0
};

new const Float:PetMinusCrouchingZ[ MaxPets ] =
{
	16.0,
	16.0,
	6.0,
	16.0,
	6.0,
	16.0,
	11.0,
	//16.0,
	//16.0,
	30.0,
	16.0,
	16.0,
	//16.0,
	16.0,
	16.0//,
	//16.0,
	//0.0
};

new const Float:PetMaxDistance[ MaxPets ] =
{
	300.0,
	300.0,
	300.0,
	300.0,
	300.0,
	300.0,
	300.0,
	//1000.0,
	//600.0,
	300.0,
	300.0,
	300.0,
	//800.0,
	400.0,
	400.0//,
	//1000.0,
	//800.0
};

new const Float:PetMinDistance[ MaxPets ] =
{
	80.0,
	80.0,
	80.0,
	80.0,
	80.0,
	80.0,
	80.0,
	//300.0,
	//200.0,
	80.0,
	80.0,
	80.0,
	//250.0,
	100.0,
	100.0//,
	//300.0,
	//200.0
};

new Pet[ MaxSlots + 1 ];
new PetType[ MaxSlots + 1 ];

new PetStat[ MaxSlots + 1 ];
new PetValue[ MaxSlots + 1 ];

new CvarPetCost;

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod: Pet Followers (GHW)", "0.0.1", "GHW_Chronic & Xellath" );

	if( !is_plugin_loaded( "dbm_core.amxx", true ) )
	{
		set_fail_state( "[ Diablo Mod Pet Followers ] DBM Core needs to be loaded in order for this plugin to run correctly!" );
	}

	register_event( "DeathMsg", "Event_DeathMsg", "a" );
	
	register_forward( FM_Think, "Forward_FM_Think" );

	CvarPetCost = register_cvar( "dbm_petfollower_cost", "3" );
	
	MaxPlayers = get_maxplayers( );
	
	register_dictionary_colored( "dbm_core_lang.txt" );
	register_dictionary_colored( "dbm_addon_lang.txt" );
	
	DBM_RegisterMenuAddon( "PETS", "ClientCommand_PetMenu", "dbm_addon_petfollowers.amxx" );
	
	DBM_RegisterCommand( "PET_COMMAND", "ClientCommand_Pet" );
	DBM_RegisterCommandToList( "PET_COMMAND", "ClientCommand_Pet", "COMMANDLIST_PET" );
	
	DBM_RegisterCommand( "PETS_COMMAND", "ClientCommand_PetMenu" );
	DBM_RegisterCommandToList( "PETS_COMMAND", "ClientCommand_PetMenu", "COMMANDLIST_PET" );
}

public plugin_natives( )
{
	register_native( "DBM_GetPetName", "_DBM_GetPetName" );
}

public _DBM_GetPetName( Plugin, Params )
{
	new Client = get_param( 1 );
	new Data[ 64 ];
	if( Pet[ Client ] )
	{
		formatex( Data, charsmax( Data ),
			"%L [+%i %L]",
			Client,
			PetName[ PetType[ Client ] ],
			PetValue[ Client ],
			Client,
			StatName[ PetStat[ Client ] ][ _Short ]
			);
	}
	else
	{
		formatex( Data, charsmax( Data ), 
			"%L",
			Client,
			"NONE"
			);
	}
	
	set_string( 2, Data, charsmax( Data ) );
}

public plugin_precache( )
{
	for( new PetIndex = 0; PetIndex < MaxPets; PetIndex++) 
	{
		precache_model( PetModel[ PetIndex ] );
	}
}

public client_disconnect( Client )
{
	HandleDeathMsg( Client );
}

public Event_DeathMsg( ) 
{
	HandleDeathMsg( read_data( 2 ) );
}

HandleDeathMsg( const Client )
{
	if( Pet[ Client ] && pev_valid( Pet[ Client ] ) )
	{
		DBM_StatBoost( Client, PetStat[ Client ], _Stat_Decrease, PetValue[ Client ] );
		
		set_pev( Pet[ Client ], pev_animtime, 100.0 );
		set_pev( Pet[ Client ], pev_framerate, 1.0 );
		set_pev( Pet[ Client ], pev_sequence, PetDieAnim[ PetType[ Client ] ] );
		set_pev( Pet[ Client ], pev_gaitsequence, PetDieAnim[ PetType[ Client ] ] );
		
		set_task( PetDieLength[ PetType[ Client ] ], "TaskRemovePet", Pet[ Client ] );
	}
	
	Pet[ Client ] = 0;
}

public TaskRemovePet( Entity ) 
{
	engfunc( EngFunc_RemoveEntity, Entity );
	
	remove_task( Entity );
}

public ClientCommand_Pet( Client )
{
	HandlePetCommand( Client, random_num( 0, MaxPets - 1 ) );
	
	return PLUGIN_HANDLED;
}

public ClientCommand_PetMenu( Client )
{
	new Title[ 256 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"PETS",
		Client,
		"MENU"
		);
	
	new Menu = menu_create( Title, "PetsMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L\R%i^n",
		Client,
		"PET_PURCHASE_RANDOM",
		get_pcvar_num( CvarPetCost )
		);
	
	menu_additem( Menu, Title, "1" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"PET_VIEW_AVAILABLE"
		);
	
	menu_additem( Menu, Title, "2" );
	
	formatex( Title, charsmax( Title ),
		"%L",
		Client,
		"EXIT"
		);

	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
	
	return PLUGIN_HANDLED;
}

public PetsMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	switch( Info[ 0 ] )
	{
		case '1':
		{
			HandlePetCommand( Client, random_num( 0, MaxPets - 1 ) );
		}
		case '2':
		{
			new Title[ 256 ];
			formatex( Title, charsmax( Title ), 
				"%L^n\w%L %L^n^n",
				Client,
				"MENU_PREFIX",
				Client,
				"PET_AVAILABLE",
				Client,
				"MENU"
				);
			
			new Menu = menu_create( Title, "ViewPetsMenuHandler" );
			
			for( new PetIndex = 0; PetIndex < MaxPets; PetIndex++ )
			{
				formatex( Title, charsmax( Title ), 
					"%L",
					Client,
					PetName[ PetIndex ]
					);
			
				menu_additem( Menu, Title, "0" );
			}
			
			formatex( Title, charsmax( Title ),
				"%L",
				Client,
				"BACK"
				);

			menu_setprop( Menu, MPROP_BACKNAME, Title );

			formatex( Title, charsmax( Title ),
				"%L",
				Client,
				"NEXT"
				);
	
			menu_setprop( Menu, MPROP_NEXTNAME, Title );
			
			formatex( Title, charsmax( Title ),
				"%L",
				Client,
				"EXIT"
				);
	
			menu_setprop( Menu, MPROP_EXITNAME, Title );
			
			menu_display( Client, Menu, 0 );
		}
	}
}

public ViewPetsMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
		
		return;
	}
}

HandlePetCommand( const Client, const Num )
{
	if( Pet[ Client ] )
	{
		HandleDeathMsg( Client );
		
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"PET_CURRENT_REMOVED"
			);
	}
	else if( !is_user_alive( Client ) )
	{
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"PET_CANNOT_DEAD"
			);
	}
	else
	{
		new Mana = DBM_GetClassMana( Client, DBM_GetClientClass( Client ) );
		new Cost = get_pcvar_num( CvarPetCost );
		if( Mana >= Cost )
		{
			Pet[ Client ] = create_entity( "info_target" );
			
			set_pev( Pet[ Client ], pev_classname, "dbm_pet" );
			
			PetType[ Client ] = Num;
			
			engfunc( EngFunc_SetModel, Pet[ Client ], PetModel[ PetType[ Client ] ] );
			
			new Float:Origin[ 3 ];
			pev( Client, pev_origin, Origin );
			
			if( is_user_crouching( Client ) ) 
			{
				Origin[ 2 ] -= PetMinusCrouchingZ[ PetType[ Client ] ];
			}
			else
			{
				Origin[ 2 ] -= PetMinusStandingZ[ PetType[ Client ] ]
			}
			
			set_pev( Pet[ Client ], pev_origin, Origin );
			set_pev( Pet[ Client ], pev_solid, SOLID_NOT );
			set_pev( Pet[ Client ], pev_movetype, MOVETYPE_FLY );
			set_pev( Pet[ Client ], pev_owner, Client );
			set_pev( Pet[ Client ], pev_nextthink, 1.0 );
			set_pev( Pet[ Client ], pev_sequence, 0 );
			set_pev( Pet[ Client ], pev_gaitsequence, 0 );
			set_pev( Pet[ Client ], pev_framerate, 1.0 );
			
			PetStat[ Client ] = random_num( _Stat_Intelligence, _Stat_Regeneration );
			PetValue[ Client ] = random_num( 3, 17 );
			DBM_StatBoost( Client, PetStat[ Client ], _Stat_Increase, PetValue[ Client ] );
			
			Mana -= Cost;
			
			DBM_SetClassMana( Client, DBM_GetClientClass( Client ), Mana );
			
			client_print_color( Client, DontChange, 
				"^4%L^3 %L", 
				Client,
				"MOD_PREFIX",
				Client,
				"PET_PURCHASED",
				Client,
				PetName[ PetType[ Client ] ], 
				Client,
				StatName[ PetStat[ Client ] ][ _Full ], 
				PetValue[ Client ],
				Cost
				);
		}
		else
		{
			client_print_color( Client, DontChange, 
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"PET_NOT_SUFFICIENT"
				);
		}
	}
}

public Forward_FM_Think( Entity )
{
	for( new PlayerIndex = 1; PlayerIndex <= MaxPlayers; PlayerIndex++ )
	{
		if( Entity == Pet[ PlayerIndex ] )
		{
			static Float:PlayerOrigin[ 3 ];
			static Float:EntityOrigin[ 3 ];
			static Float:Velocity[ 3 ];
			pev( Entity, pev_origin, EntityOrigin );
			
			get_offset_origin_body( PlayerIndex, Float:{ 50.0, 0.0, 0.0 }, PlayerOrigin );
			
			if( is_user_crouching( PlayerIndex ) )
			{
				PlayerOrigin[ 2 ] -= PetMinusCrouchingZ[ PetType[ PlayerIndex ] ];
			}
			else
			{
				PlayerOrigin[ 2 ] -= PetMinusStandingZ[ PetType[ PlayerIndex ] ];
			}

			if( get_distance_f( PlayerOrigin, EntityOrigin ) > PetMaxDistance[ PetType[ PlayerIndex ] ] )
			{
				set_pev( Entity, pev_origin, PlayerOrigin );
			}
			else if( get_distance_f( PlayerOrigin, EntityOrigin ) > PetMinDistance[ PetType[ PlayerIndex ] ] )
			{
				get_speed_vector( EntityOrigin, PlayerOrigin, 250.0, Velocity );
				set_pev( Entity, pev_velocity, Velocity );
				
				if( pev( Entity, pev_sequence ) != PetRun[ PetType[ PlayerIndex ] ] 
				|| pev( Entity, pev_framerate ) != PetRunSpeed[ PetType[ PlayerIndex ] ] )
				{
					set_pev( Entity, pev_frame, 1 );
					set_pev( Entity, pev_sequence, PetRun[ PetType[ PlayerIndex ] ] );
					set_pev( Entity, pev_gaitsequence, PetRun[ PetType[ PlayerIndex ] ] );
					set_pev( Entity, pev_framerate, PetRunSpeed[ PetType[ PlayerIndex ] ] );
				}
			}
			else if( get_distance_f( PlayerOrigin, EntityOrigin ) < ( PetMinDistance[ PetType[ PlayerIndex ] ] - 5.0 ) )
			{
				if( pev( Entity, pev_sequence ) != PetIdle[ PetType[ PlayerIndex ] ] 
				|| pev( Entity, pev_framerate ) != PetIdleSpeed[ PetType[ PlayerIndex ] ] )
				{
					set_pev( Entity, pev_frame, 1 );
					set_pev( Entity, pev_sequence, PetIdle[ PetType[ PlayerIndex ] ] );
					set_pev( Entity, pev_gaitsequence, PetIdle[ PetType[ PlayerIndex ] ] );
					set_pev( Entity, pev_framerate, PetIdleSpeed[ PetType[ PlayerIndex ] ] );
				}
				
				set_pev( Entity, pev_velocity, Float:{ 0.0, 0.0, 0.0 } );
			}
			
			pev( PlayerIndex, pev_origin, PlayerOrigin );
			PlayerOrigin[ 2 ] = EntityOrigin[ 2 ];
			entity_set_aim( Entity, PlayerOrigin );
			
			set_pev( Entity, pev_nextthink, 1.0 );
		}
	}
}