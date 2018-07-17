#include < amxmodx >
#include < engine >
#include < hamsandwich >
#include < fun >
#include < colorchat >
#include < dbm_api >

new ClassPointer;

new bool:IsPaladin[ MaxSlots + 1 ];

new HolyJumps[ MaxSlots + 1 ];

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Class: Paladin", "0.0.1", "Xellath" );
	
	register_dictionary_colored( "dbm_class_lang.txt" );
	
	new StatData[ StatStruct ];
	StatData[ _Stat_Intelligence ] = 200;
	StatData[ _Stat_Stamina ] = 400;
	StatData[ _Stat_Dexterity ] = 200;
	StatData[ _Stat_Agility ] = 100;
	StatData[ _Stat_Regeneration ] = 100;
	
	ClassPointer = DBM_RegisterClass( 
		"CLASS_PALADIN_NAME", 
		"CLASS_PALADIN_DESC", 
		"paladin", 
		"CLASS_PALADIN_ABI", 
		"CLASS_PALADIN_ABI_DESC", 
		_Bronze, 
		4.0, 
		true, 
		StatData 
		);
	
	RegisterHam( Ham_TakeDamage, "player", "Forward_Ham_TakeDamage_Pre" );
	
	MaxPlayers = get_maxplayers( );
}

public Forward_DBM_ClassSelected( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsPaladin[ Client ] = true;
		
		HolyJumps[ Client ] = 0;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_ClassChanged( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsPaladin[ Client ] = false;
		
		HolyJumps[ Client ] = 0;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_AbilityLoaded( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		new MaxHolyJumps = 2 + ( DBM_GetTotalStats( Client, _Stat_Intelligence ) / 20 );
		if( HolyJumps[ Client ] < MaxHolyJumps )
		{
			HolyJumps[ Client ]++;
			
			new Text[ TextLength ];
			
			new Language[ 3 ];
			get_user_info( Client, "lang", Language, charsmax( Language ) );
			if( equali( Language, "pl" ) )
			{
				new Plural[ 16 ];
				if( HolyJumps[ Client ] >= 5 )
				{
					formatex( Plural, charsmax( Plural ), "Swietych Skokow" );
				}
				else if( 2 <= HolyJumps[ Client ] <= 4 )
				{
					formatex( Plural, charsmax( Plural ), "Swiete Skoki" );
				}
				else if( HolyJumps[ Client ] <= 1 )
				{
					formatex( Plural, charsmax( Plural ), "Swiety Skok" );
				}
				
				formatex( Text, charsmax( Text ),
					"%s: %i",
					Plural,
					HolyJumps[ Client ]
					);
			}
			else
			{
				formatex( Text, charsmax( Text ),
					"%L: %i",
					Client,
					"CLASS_PALADIN_ABI_PLURAL",
					HolyJumps[ Client ]
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
		if( HolyJumps[ Client ] )
		{
			HolyJump( Client );
		
			HolyJumps[ Client ]--;
		
			new Language[ 3 ];
			get_user_info( Client, "lang", Language, charsmax( Language ) );
			if( equali( Language, "pl" ) )
			{
				new Plural[ 16 ];
				if( HolyJumps[ Client ] >= 5 )
				{
					formatex( Plural, charsmax( Plural ), "Swietych Skokow" );
				}
				else if( 2 <= HolyJumps[ Client ] <= 4 )
				{
					formatex( Plural, charsmax( Plural ), "Swiete Skoki" );
				}
				else if( HolyJumps[ Client ] <= 1 )
				{
					formatex( Plural, charsmax( Plural ), "Swiety Skok" );
				}
				
				formatex( Text, charsmax( Text ),
					"%s: %i",
					Plural,
					HolyJumps[ Client ]
					);
			}
			else
			{
				formatex( Text, charsmax( Text ),
					"%L: %i",
					Client,
					"CLASS_PALADIN_ABI_PLURAL",
					HolyJumps[ Client ]
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

HolyJump( const Client )
{	
	new Float:Angle[ 3 ];
	new Float:Velocity[ 3 ]; 
	entity_get_vector( Client, EV_VEC_v_angle, Angle );
	
	Velocity[ 0 ] = floatcos( Angle[ 1 ] / 180.0 * M_PI ) * 560.0; 
	Velocity[ 1 ] = floatsin( Angle[ 1 ] / 180.0 * M_PI ) * 560.0; 
	Velocity[ 2 ] = 300.0;
	
	entity_set_vector( Client, EV_VEC_velocity, Velocity ); 
}

public Forward_DBM_ClientSpawned( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		if( IsPaladin[ Client ] )
		{
			set_user_health( Client, 120 );
		}
	}
}

public Forward_Ham_TakeDamage_Pre( Victim, Inflictor, Attacker, Float:Damage, Damagebits )
{
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& IsPaladin[ Attacker ]
	&& get_user_weapon( Attacker ) == CSW_KNIFE
	&& random_num( 1, 100 ) <= 20 )
	{
		SetHamParamFloat( 4, Damage * 2 );
	}
}