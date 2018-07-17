#include < amxmodx >
#include < engine >
#include < hamsandwich >
#include < fun >
#include < colorchat >
#include < dbm_api >

const TaskIdStealth = 4118;

new ClassPointer;

new bool:IsAssassin[ MaxSlots + 1 ];
new bool:HasStealth[ MaxSlots + 1 ];

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Class: Assassin", "0.0.1", "Xellath" );
	
	register_dictionary_colored( "dbm_class_lang.txt" );
	
	new StatData[ StatStruct ];
	StatData[ _Stat_Intelligence ] = 50;
	StatData[ _Stat_Stamina ] = 150;
	StatData[ _Stat_Dexterity ] = 300;
	StatData[ _Stat_Agility ] = 300;
	StatData[ _Stat_Regeneration ] = 200;
	
	ClassPointer = DBM_RegisterClass( 
		"CLASS_ASSASSIN_NAME", 
		"CLASS_ASSASSIN_DESC", 
		"assassin", 
		"CLASS_ASSASSIN_ABI", 
		"CLASS_ASSASSIN_ABI_DESC",
		_Bronze, 
		6.0, 
		false, 
		StatData 
		);
	
	RegisterHam( Ham_Item_PreFrame, "player", "Forward_Ham_ItemPreFrame_Post", 1 );
	RegisterHam( Ham_TakeDamage, "player", "Forward_Ham_TakeDamage_Pre" );
	
	MaxPlayers = get_maxplayers( );
}

public Forward_DBM_ClassSelected( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsAssassin[ Client ] = true;
		
		HasStealth[ Client ] = false;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_ClassChanged( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsAssassin[ Client ] = false;
		
		HasStealth[ Client ] = false;
		
		remove_task( Client + TaskIdStealth );
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_AbilityLoaded( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		HasStealth[ Client ] = true;
		
		new Text[ TextLength ];
		formatex( Text, charsmax( Text ),
			"%L %L!",
			Client,
			"CLASS_ASSASSIN_ABI",
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
		if( HasStealth[ Client ] )
		{
			formatex( Text, charsmax( Text ),
				"%L %L!",
				Client,
				"CLASS_ASSASSIN_ABI",
				Client,
				"CLASS_ABILITY_USED"
				);
			
			DBM_SkillHudText( Client, 2.0, Text );
			
			set_user_rendering( Client, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 10 );
			
			HasStealth[ Client ] = false;
			
			set_task( 5.0 + ( DBM_GetTotalStats( Client, _Stat_Intelligence ) * 0.05 ), "TaskRemoveStealth", Client + TaskIdStealth );
			
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

public TaskRemoveStealth( TaskId )
{
	new Client = TaskId - TaskIdStealth;
	
	set_user_rendering( Client );
	
	new Text[ TextLength ];
	formatex( Text, charsmax( Text ),
		"%L %L!",
		Client,
		"CLASS_ASSASSIN_ABI",
		Client,
		"CLASS_ABILITY_ENDED"
		);
	
	DBM_SkillHudText( Client, 2.0, Text );
}

public Forward_Ham_ItemPreFrame_Post( Client )
{
	if( is_user_alive( Client ) 
	&& IsAssassin[ Client ]
	&& !DBM_GetFreezetime( ) )
	{
		set_user_maxspeed( Client, 320.0 );
	}
}

public Forward_DBM_ClientSpawned( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		if( IsAssassin[ Client ] )
		{
			set_user_health( Client, 150 );
			
			set_user_footsteps( Client, 1 );
		}
	}
}

public Forward_Ham_TakeDamage_Pre( Victim, Inflictor, Attacker, Float:Damage, Damagebits )
{
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& IsAssassin[ Attacker ]
	&& get_user_weapon( Attacker ) == CSW_KNIFE
	&& random_num( 1, 100 ) <= 20 )
	{
		ExecuteHamB( Ham_Killed, Victim, Attacker, 0 );
	}
}