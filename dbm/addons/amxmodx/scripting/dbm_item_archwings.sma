#include < amxmodx >
#include < hamsandwich >
#include < fun >
#include < engine >
#include < fakemeta >
#include < cstrike >
#include < colorchat >
#include < dbm_api >

enum _:WingType
{
	_Wing_Rare,
	_Wing_Unique
};

new const ModelPath[ ] = "models/hat/angel2.mdl";

new ItemPointer[ WingType ];

new PlayerEntity[ MaxSlots + 1 ];

new bool:HasItem[ MaxSlots + 1 ][ WingType ];

new Stomp[ MaxSlots + 1 ];
new bool:IsFalling[ MaxSlots + 1 ];

new Float:Cooldown[ MaxSlots + 1 ];

new MsgIdScreenShake;

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Item: Arch Angel Wings", "0.0.1", "Xellath" );
	
	register_dictionary_colored( "dbm_item_lang.txt" );	

	ItemPointer[ _Wing_Rare ] = DBM_RegisterItem(
		"ITEM_ARCHWINGS_RARE_NAME",
		"ITEM_ARCHWINGS_RARE_DESC",
		0,
		0,
		_Rare,
		150
		);
		
	ItemPointer[ _Wing_Unique ] = DBM_RegisterItem(
		"ITEM_ARCHWINGS_UNIQUE_NAME",
		"ITEM_ARCHWINGS_UNIQUE_DESC",
		8,
		0,
		_Unique,
		75
		);
		
	MsgIdScreenShake = get_user_msgid( "ScreenShake" );
	
	MaxPlayers = get_maxplayers( );
}

public plugin_precache( )
{
	precache_model( ModelPath );
}

public client_disconnect( Client )
{
	HasItem[ Client ][ _Wing_Rare ] = false;
	HasItem[ Client ][ _Wing_Unique ] = false;
}

public Forward_DBM_ItemReceived( const Client, const ItemIndex )
{
	for( new WingIndex; WingIndex < WingType; WingIndex++ )
	{
		if( ItemIndex == ItemPointer[ WingIndex ] )
		{
			HasItem[ Client ][ WingIndex ] = true;
			
			if( is_user_alive( Client )
			&& !PlayerEntity[ Client ] )
			{
				PlayerEntity[ Client ] = create_entity( "info_target" );
				set_pev( PlayerEntity[ Client ], pev_movetype, MOVETYPE_FOLLOW );
				set_pev( PlayerEntity[ Client ], pev_aiment, Client );
				set_pev( PlayerEntity[ Client ], pev_rendermode, kRenderNormal );
				engfunc( EngFunc_SetModel, PlayerEntity[ Client ], ModelPath );
				
				set_user_gravity( Client, 0.4 );
			}
		}
	}
}

public Forward_DBM_ItemDispatched( const Client, const ItemIndex )
{
	for( new WingIndex; WingIndex < WingType; WingIndex++ )
	{
		if( ItemIndex == ItemPointer[ WingIndex ] )
		{
			HasItem[ Client ][ WingIndex ] = false;
			
			if( PlayerEntity[ Client ] )
			{
				remove_entity( PlayerEntity[ Client ] );
				
				PlayerEntity[ Client ] = 0;
				
				set_user_gravity( Client, 0.4 );
			}
		}
	}
}

public Forward_DBM_ClientSpawned( const Client, const ClassIndex )
{
	for( new WingIndex; WingIndex < WingType; WingIndex++ )
	{
		if( HasItem[ Client ][ WingIndex ] )
		{
			if( PlayerEntity[ Client ] )
			{
				remove_entity( PlayerEntity[ Client ] );
				
				PlayerEntity[ Client ] = 0;
			}
			
			PlayerEntity[ Client ] = create_entity( "info_target" );
			set_pev( PlayerEntity[ Client ], pev_movetype, MOVETYPE_FOLLOW );
			set_pev( PlayerEntity[ Client ], pev_aiment, Client );
			set_pev( PlayerEntity[ Client ], pev_rendermode, kRenderNormal );
			engfunc( EngFunc_SetModel, PlayerEntity[ Client ], ModelPath );
			
			set_user_gravity( Client, 0.4 );
		}
	}
}

public Forward_DBM_ClientKilled( const Victim, const Attacker )
{
	if( PlayerEntity[ Victim ] )
	{
		remove_entity( PlayerEntity[ Victim ] );
		
		PlayerEntity[ Victim ] = 0;
		
		set_user_gravity( Victim, 0.4 );
	}
}

public Forward_DBM_ItemUse( const Client, const ItemIndex )
{
	for( new WingIndex; WingIndex < WingType; WingIndex++ )
	{
		if( ItemIndex == ItemPointer[ WingIndex ]
		&& HasItem[ Client ][ WingIndex ] )
		{
			if( ( get_gametime( ) - Cooldown[ Client ] ) <= ( 5.0 - ( DBM_GetTotalStats( Client, _Stat_Intelligence ) / 250.0 ) ) )
			{
				new Text[ TextLength ];
				formatex( Text, charsmax( Text ),
					"%L",
					Client,
					"ITEM_NOT_READY"
					);
				
				DBM_SkillHudText( Client, 2.0, Text );
			}
			else
			{
				if( !( pev( Client, pev_flags ) & FL_ONGROUND ) )
				{
					Cooldown[ Client ] = get_gametime( );
			
					new Origin[ 3 ];
					get_user_origin( Client, Origin );
					
					if( Origin[ 2 ] == 0 )
					{
						Stomp[ Client ] = 1;
					}
					else
					{
						Stomp[ Client ] = Origin[ 2 ] + ( WingIndex == _Wing_Rare ? 50 : 0 );
					}
					
					set_user_gravity( Client, 5.0 );
					IsFalling[ Client ] = true;
				}
			}
		}
	}
}

public client_PreThink( Client )
{
	if( Stomp[ Client ] != 0 
	&& is_user_alive( Client ) )
	{
		static Float:FallVelocity;
		pev( Client, pev_flFallVelocity, FallVelocity );
		
		if( FallVelocity ) 
		{
			IsFalling[ Client ] = true;
		}
		else 
		{
			IsFalling[ Client ] = false;
		}
	}
}

public client_PostThink( Client )
{
	if( Stomp[ Client ] != 0 
	&& is_user_alive( Client ) )
	{
		if( !IsFalling[ Client ] ) 
		{
			ExecuteStomp( Client );
		}
		else 
		{
			set_pev( Client, pev_watertype, CONTENTS_WATER );
		}
	}
}

ExecuteStomp( const Client )
{
	set_user_gravity( Client, 0.4 );
	
	new Origin[ 3 ];
	get_user_origin( Client, Origin );
	
	new Damage = Stomp[ Client ] - Origin[ 2 ];
	Stomp[ Client ] = 0;
	
	if( Damage < 90 )
	{
		return;
	}
	
	message_begin( MSG_ONE_UNRELIABLE , MsgIdScreenShake, _ , Client );
	{
		write_short( 1<<14 );
		write_short( 1<<12 );
		write_short( 1<<14 );
	}
	message_end( );
	
	new Float:FloatedDamage = Damage - 90.0;
	
	new Float:FOrigin[ 3 ];
	IVecFVec( Origin, FOrigin );
	
	new Float:ClientOrigin[ 3 ];
	new Float:PlayerOrigin[ 3 ];
	new Float:DeltaVector[ 3 ];
	
	new Player = -1;
	while( ( Player = find_ent_in_sphere( Player, FOrigin, ( 230.0 + DBM_GetTotalStats( Client, _Stat_Agility ) ) * 2 ) ) != 0 ) 
	{
		if(	!( 1 <= Player <= MaxPlayers )
		|| Player == Client 
		|| !is_user_alive( Player )
		|| cs_get_user_team( Player ) == cs_get_user_team( Client )
		|| !( pev( Player, pev_flags ) & FL_ONGROUND ) )
		{
			continue;
		}
		
		pev( Client, pev_origin, ClientOrigin );
		pev( Player, pev_origin, PlayerOrigin );
		
		DeltaVector[ 0 ] = ( PlayerOrigin[ 0 ] - ClientOrigin[ 0 ] ) + 10;
		DeltaVector[ 1 ] = ( PlayerOrigin[ 1 ] - ClientOrigin[ 1 ] ) + 10;
		DeltaVector[ 2 ] = ( PlayerOrigin[ 2 ] - ClientOrigin[ 2 ] ) + 200;
		
		set_pev( Player, pev_velocity, DeltaVector );
		
		message_begin( MSG_ONE_UNRELIABLE, MsgIdScreenShake, _ , Player );
		{
			write_short( 1<<18 );
			write_short( 1<<14 );
			write_short( 1<<18 );
		}
		message_end( );
		
		if( ( pev( Player, pev_health ) - FloatedDamage ) > 0 )
		{
			ExecuteHamB( Ham_TakeDamage, Player, Client, Client, FloatedDamage, DMG_ENERGYBEAM );
		}
		else
		{
			ExecuteHamB( Ham_Killed, Player, Client, 2 );
		}
	}
}