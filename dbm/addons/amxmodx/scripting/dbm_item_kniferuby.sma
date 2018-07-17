#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < colorchat >
#include < dbm_api >

new ItemPointer;

new bool:HasItem[ MaxSlots + 1 ];

new Float:Teleport[ MaxSlots + 1 ];

public plugin_init( )
{
	register_plugin( "Diablo Mod Item: Knife Ruby", "0.0.1", "Xellath" );
	
	register_dictionary_colored( "dbm_item_lang.txt" );	

	ItemPointer = DBM_RegisterItem(
		"ITEM_RUBY_NAME",
		"ITEM_RUBY_DESC",
		0,
		0,
		_Rare,
		150
		);
}

public client_disconnect( Client )
{
	HasItem[ Client ] = false;
}

public Forward_DBM_ItemReceived( const Client, const ItemIndex )
{
	if( ItemIndex == ItemPointer )
	{
		HasItem[ Client ] = true;
	}
}

public Forward_DBM_ItemDispatched( const Client, const ItemIndex )
{
	if( ItemIndex == ItemPointer )
	{
		HasItem[ Client ] = false;
	}
}

public Forward_DBM_ItemUse( const Client, const ItemIndex )
{
	if( ItemIndex == ItemPointer
	&& HasItem[ Client ] )
	{
		if( ( get_gametime( ) - Teleport[ Client ] ) <= ( 3.0 - ( DBM_GetTotalStats( Client, _Stat_Intelligence ) / 250.0 ) ) )
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
			Teleport[ Client ] = get_gametime( );
		
			UTIL_Teleport( Client, 300 + DBM_GetTotalStats( Client, _Stat_Intelligence ) );
		}
	}
}

UTIL_Teleport( const Client, const Distance )
{	
	SetOriginForward( Client, Distance );
	
	new Origin[ 3 ];
	get_user_origin( Client, Origin );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	{
		write_byte( TE_PARTICLEBURST );
		write_coord( Origin[ 0 ] );
		write_coord( Origin[ 1 ] );
		write_coord( Origin[ 2 ] );
		write_short( 20 );
		write_byte( 1 );
		write_byte( 4 );
	}
	message_end( );
}

SetOriginForward( const Client, Distance ) 
{
	new Float:Origin[ 3 ];
	new Float:Angles[ 3 ];
	new Float:EndOrigin[ 3 ];
	
	new Float:Height = 10.0;
	new Float:PlayerHeight = 64.0;
	
	new bool:Recalculate = false;
	new bool:FoundHeight = false;
	
	pev( Client, pev_origin, Origin );
	pev( Client, pev_angles, Angles );
	
	EndOrigin[ 0 ] = Origin[ 0 ] + Distance * floatcos( Angles[ 1 ], degrees ) * floatabs( floatcos( Angles[ 0 ], degrees ) );
	EndOrigin[ 1 ] = Origin[ 1 ] + Distance * floatsin( Angles[ 1 ], degrees ) * floatabs( floatcos( Angles[ 0 ], degrees ) );
	EndOrigin[ 2 ] = Origin[ 2 ] + Height;
	
	while( !CanTraceLineOrigin( Origin, EndOrigin ) 
	|| IsPointStuck( EndOrigin, 48.0 ) )
	{	
		if( Distance < 10 )
		{
			break;
		}
			
		for( new z = 1; z < PlayerHeight + 20.0; z++ )
		{
			EndOrigin[ 2 ] += z;
			if( CanTraceLineOrigin( Origin, EndOrigin ) 
			&& !IsPointStuck( EndOrigin, 48.0 ) )
			{
				FoundHeight = true;
				
				Height += z;
				
				break;
			}
			
			EndOrigin[ 2 ] -= z;
		}
		
		if( FoundHeight )
		{
			break;
		}
		
		Recalculate = true;
		
		Distance -= 10;
		
		EndOrigin[ 0 ] = Origin[ 0 ] + ( Distance + 32 ) * floatcos( Angles[ 1 ], degrees ) * floatabs( floatcos( Angles[ 0 ], degrees ) );
		EndOrigin[ 1 ] = Origin[ 1 ] + ( Distance + 32 ) * floatsin( Angles[ 1 ], degrees ) * floatabs( floatcos( Angles[ 0 ], degrees ) );
		EndOrigin[ 2 ] = Origin[ 2 ] + Height;
	}
	
	if( !Recalculate )
	{
		set_pev( Client, pev_origin, EndOrigin );
		
		return;
	}
	
	EndOrigin[ 0 ] = Origin[ 0 ] + Distance * floatcos( Angles[ 1 ], degrees ) * floatabs( floatcos( Angles[ 0 ], degrees ) );
	EndOrigin[ 1 ] = Origin[ 1 ] + Distance * floatsin( Angles[ 1 ], degrees ) * floatabs( floatcos( Angles[ 0 ], degrees ) );
	EndOrigin[ 2 ] = Origin[ 2 ] + Height;
	
	set_pev( Client, pev_origin, EndOrigin );
}

bool:CanTraceLineOrigin( Float:StartOrigin[ 3 ], Float:EndOrigin[ 3 ] )
{	
	new Float:Origin[ 3 ];
	new Float:TempStartOrigin[ 3 ];
	new Float:TempEndOrigin[ 3 ];
	
	TempStartOrigin[ 0 ] = StartOrigin[ 0 ];
	TempStartOrigin[ 1 ] = StartOrigin[ 1 ];
	TempStartOrigin[ 2 ] = StartOrigin[ 2 ] - 30;
	
	TempEndOrigin[ 0 ] = EndOrigin[ 0 ];
	TempEndOrigin[ 1 ] = EndOrigin[ 1 ];
	TempEndOrigin[ 2 ] = EndOrigin[ 2 ] - 30;
	
	trace_line( -1, TempStartOrigin, TempEndOrigin, Origin );
	
	if( get_distance_f( Origin, TempEndOrigin ) < 1.0 )
	{
		return true;
	}
	
	return false;
}

bool:IsPointStuck( Float:Origin[ 3 ], Float:HullSize )
{
	new Float:TempOrigin[ 3 ];
	new Float:Iterator = HullSize / 3;
	
	TempOrigin[ 2 ] = Origin[ 2 ];
	
	new Float:x;
	new Float:y;
	new Float:z;
	for( x = Origin[ 0 ] - HullSize; x < Origin[ 0 ] + HullSize; x += Iterator )
	{
		for( y = Origin[ 1 ] + HullSize; y < Origin[ 1 ] + HullSize; y += Iterator)
		{
			for( z = Origin[ 2 ] - 72.0; z < Origin[ 2 ] + 72.0; z += 6 ) 
			{
				TempOrigin[ 0 ] = x;
				TempOrigin[ 1 ] = y;
				TempOrigin[ 2 ] = z;
				
				if( point_contents( TempOrigin ) != -1 )
				{
					return true;
				}
			}
		}
	}
	
	return false;
}