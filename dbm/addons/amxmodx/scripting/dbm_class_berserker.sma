#include < amxmodx >
#include < cstrike >
#include < engine >
#include < fakemeta >
#include < colorchat >
#include < fun >
#include < dbm_api >

new ClassPointer;

new bool:IsBerserker[ MaxSlots + 1 ];

new bool:HasDodge[ MaxSlots + 1 ];
new Dodge[ MaxSlots + 1 ];

new MaxPlayers;

new const AmmoClipSize[ ] =
{
	0,
	13,
	0,
	10,
	0,
	7,
	0,
	30,
	30,
	0,
	30,
	20,
	25,
	30,
	35,
	25,
	12,
	20,
	10,
	30,
	100,
	8,
	30,
	30,
	20,
	0,
	7,
	30,
	30,
	0,
	50
};

public plugin_init( )
{
	register_plugin( "Diablo Mod Class: Berserker", "0.0.1", "Xellath" );
	
	register_dictionary_colored( "dbm_class_lang.txt" );
	
	new StatData[ StatStruct ];
	StatData[ _Stat_Intelligence ] = 100;
	StatData[ _Stat_Stamina ] = 150;
	StatData[ _Stat_Dexterity ] = 300;
	StatData[ _Stat_Agility ] = 400;
	StatData[ _Stat_Regeneration ] = 300;
	
	ClassPointer = DBM_RegisterClass( 
		"CLASS_BERSERKER_NAME", 
		"CLASS_BERSERKER_DESC", 
		"berserker", 
		"CLASS_BERSERKER_ABI", 
		"CLASS_BERSERKER_ABI_DESC", 
		_Bronze, 
		11.0, 
		true, 
		StatData 
		);
	
	register_forward( FM_TraceLine, "Forward_FM_TraceLine_Post", 1 );
	
	register_event( "DeathMsg", "Event_DeathMsg", "a" );
	
	MaxPlayers = get_maxplayers( );
}

public Forward_DBM_ClassSelected( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsBerserker[ Client ] = true;
		
		HasDodge[ Client ] = false;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_ClassChanged( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsBerserker[ Client ] = false;
		
		HasDodge[ Client ] = false;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_AbilityLoaded( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		new Text[ TextLength ];
		if( HasDodge[ Client ] )
		{
			new MaxDodges = 2 + ( DBM_GetTotalStats( Client, _Stat_Stamina ) / 35 );
			if( Dodge[ Client ] < MaxDodges )
			{
				Dodge[ Client ] += 1;
				
				formatex( Text, charsmax( Text ),
					"%L: %i",
					Client,
					"CLASS_BERSERKER_ABI",
					Dodge[ Client ]
					);
				
				DBM_SkillHudText( Client, 0.4, Text );
				
				if( Dodge[ Client ] >= MaxDodges )
				{
					DBM_SetClassAbility( Client, ClassIndex, true );
				}
			}
		}
		else
		{
			HasDodge[ Client ] = true;
			
			Dodge[ Client ] = 1;
			
			formatex( Text, charsmax( Text ),
				"%L: %i",
				Client,
				"CLASS_BERSERKER_ABI",
				Dodge[ Client ]
				);
			
			DBM_SkillHudText( Client, 1.4, Text );
		}
	}
}

public Forward_DBM_AbilityUse( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		new Text[ TextLength ];
		if( HasDodge[ Client ] )
		{
			HasDodge[ Client ] = false;
			
			formatex( Text, charsmax( Text ),
				"%L %L!",
				Client,
				"CLASS_BERSERKER_ABI",
				Client,
				"CLASS_ABILITY_ACTIVATED"
				);
			
			DBM_SkillHudText( Client, 0.4, Text );
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

public Forward_FM_TraceLine_Post( Float:VectorStart[ 3 ], Float:VectorEnd[ 3 ], IgnoreMonsters, Client, TraceHandle )
{
	if( !is_user_alive( Client )
	|| is_user_bot( Client ) )
	{
		return FMRES_IGNORED;
	}

	new TraceHit = get_tr2( TraceHandle, TR_pHit );	
	if( !( entity_get_int( Client, EV_INT_button ) & IN_ATTACK )
	|| !( entity_get_int( Client, EV_INT_button ) & IN_ATTACK2 ) )
	{
		return FMRES_IGNORED;
	}
	
	if( 1 <= TraceHit <= MaxPlayers 
	&& is_user_alive( TraceHit ) )
	{
		if( IsBerserker[ TraceHit ]
		&& !HasDodge[ TraceHit ]
		&& Dodge[ TraceHit ] > 0 )
		{
			Dodge[ TraceHit ]--;
			
			new Text[ MaxSlots ];	
			if( !Dodge[ TraceHit ] )
			{
				formatex( Text, charsmax( Text ),
					"%L %L!",
					TraceHit,
					"CLASS_BERSERKER_ABI",
					TraceHit,
					"CLASS_ABILITY_ENDED"
					);
				
				DBM_SetClassAbility( TraceHit, ClassPointer );
			}
			else
			{
				formatex( Text, charsmax( Text ),
					"%L: %i",
					TraceHit,
					"CLASS_BERSERKER_ABI",
					Dodge[ TraceHit ]
					);
			}
			
			DBM_SkillHudText( TraceHit, 0.4, Text );
			
			set_tr2( TraceHandle, TR_iHitgroup, 8 );
		}
	}
	else if( is_valid_ent( TraceHit ) )
	{
		return FMRES_IGNORED;
	}
	
	return FMRES_IGNORED;
}

public Event_DeathMsg( )
{
	new Attacker = read_data( 1 );
	new Victim = read_data( 2 );
	
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& Victim != Attacker
	&& is_user_connected( Victim ) 
	&& is_user_connected( Attacker )
	&& cs_get_user_team( Victim ) != cs_get_user_team( Attacker )
	&& IsBerserker[ Attacker ] )
	{
		RefillAmmo( Attacker );
		
		entity_set_float( Attacker, EV_FL_health, entity_get_float( Attacker, EV_FL_health ) + 20.0 + ( DBM_GetTotalStats( Attacker, _Stat_Regeneration ) * 0.1 ) );
	}
}

RefillAmmo( Client )
{
	if( is_user_alive( Client ) )
	{
		new WeaponName[ MaxSlots ];
		new WeaponIndex = get_user_weapon( Client );
		get_weaponname( WeaponIndex, WeaponName, charsmax( WeaponName ) );
		
		new WeaponEntityIndex = find_ent_by_owner( -1, WeaponName, Client );
		cs_set_weapon_ammo( WeaponEntityIndex, AmmoClipSize[ WeaponIndex ] );
	}
}