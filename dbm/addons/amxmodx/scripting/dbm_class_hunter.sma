#include < amxmodx >
#include < engine >
#include < hamsandwich >
#include < fakemeta >
#include < cstrike >
#include < fun >
#include < colorchat >
#include < dbm_api >

const m_pPlayer = 41;

const m_flNextPrimaryAttack = 46;
const m_flNextSecondaryAttack = 47;

const m_flNextAttack = 83;

const XO_WEAPONS = 4;
const XO_PLAYER = 5;

const TaskIdFocusFire = 8886;

new const CrossbowViewModel[ ]  = "models/v_crossbow.mdl";
new const CrossbowPlayerModel[ ] = "models/p_crossbow.mdl";
new const CrossbowBoltModel[ ]  = "models/crossbow_bolt.mdl";

new ClassPointer;

new bool:IsHunter[ MaxSlots + 1 ];

new bool:ViewModelBow[ MaxSlots + 1 ];

new bool:HasFocusFire[ MaxSlots + 1 ];
new bool:InFocusFire[ MaxSlots + 1 ];

new SpriteBloodDrop;
new SpriteBloodSpray;

new MsgIdScreenShake;

public plugin_init( )
{
	register_plugin( "Diablo Mod Class: Hunter", "0.0.1", "Xellath" );
	
	register_dictionary_colored( "dbm_class_lang.txt" );
	
	new StatData[ StatStruct ];
	StatData[ _Stat_Intelligence ] = 300;
	StatData[ _Stat_Stamina ] = 100;
	StatData[ _Stat_Dexterity ] = 150;
	StatData[ _Stat_Agility ] = 450;
	StatData[ _Stat_Regeneration ] = 200;
	
	ClassPointer = DBM_RegisterClass( 
		"CLASS_HUNTER_NAME", 
		"CLASS_HUNTER_DESC", 
		"hunter", 
		"CLASS_HUNTER_ABI", 
		"CLASS_HUNTER_ABI_DESC", 
		_Bronze, 
		15.0, 
		true, 
		StatData 
		);
		
	DBM_SetClassIgnoreDeploy( "Hunter" );
	
	register_forward( FM_CmdStart, "Forward_FM_CmdStart_Pre" );
	register_forward( FM_Touch, "Forward_FM_ArrowTouch_Pre" );
	
	RegisterHam( Ham_Weapon_PrimaryAttack, "weapon_knife", "Forward_Ham_PrimaryAttack_Pre" );
	RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_knife", "Forward_Ham_PrimaryAttack_Pre" );
	
	RegisterHam( Ham_Item_Deploy, "weapon_knife", "Forward_Ham_ItemDeploy_Post", 1 );
	
	register_forward( FM_EmitSound, "Forward_FM_EmitSound" );
	
	MsgIdScreenShake = get_user_msgid( "ScreenShake" );
}

public plugin_precache( )
{
	SpriteBloodDrop = precache_model( "sprites/blood.spr" );
	SpriteBloodSpray = precache_model( "sprites/bloodspray.spr" );
	
	precache_model( CrossbowViewModel );
	precache_model( CrossbowPlayerModel );
	precache_model( CrossbowBoltModel );
	
	precache_sound( "weapons/xbow_fire1.wav" );
	precache_sound( "weapons/xbow_hit1.wav" );
	
	precache_sound( "weapons/xbow_hitbod1.wav" );
	precache_sound( "weapons/xbow_hitbod2.wav" );
}

public Forward_DBM_ClassSelected( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsHunter[ Client ] = true;
		
		HasFocusFire[ Client ] = false;
		
		ViewModelBow[ Client ] = false;
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_ClassChanged( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		IsHunter[ Client ] = false;
		
		HasFocusFire[ Client ] = false;
		
		ViewModelBow[ Client ] = false;
		
		if( get_user_weapon( Client ) == CSW_KNIFE )
		{
			entity_set_string( Client, EV_SZ_viewmodel, "models/v_knife.mdl" ); 
			entity_set_string( Client, EV_SZ_weaponmodel, "models/p_knife.mdl" );
		}
		
		DBM_SetClassAbility( Client, ClassIndex );
	}
}

public Forward_DBM_AbilityLoaded( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		if( !HasFocusFire[ Client ] )
		{
			HasFocusFire[ Client ] = true;
			
			new Text[ TextLength ];
			formatex( Text, charsmax( Text ),
				"%L %L!",
				Client,
				"CLASS_HUNTER_ABI",
				Client,
				"CLASS_ABILITY_READY"
				);
			
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
		if( HasFocusFire[ Client ] )
		{
			DBM_StatBoost( Client, _Stat_Agility, _Stat_Increase, 100 );
		
			InFocusFire[ Client ] = true;
			
			formatex( Text, charsmax( Text ),
				"%L %L!",
				Client,
				"CLASS_HUNTER_ABI",
				Client,
				"CLASS_ABILITY_ACTIVATED"
				);
			
			DBM_SkillHudText( Client, 0.4, Text );
			
			set_task( 5.0, "TaskEndFocusFire", Client + TaskIdFocusFire );
			
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

public TaskEndFocusFire( TaskId )
{
	new Client = TaskId - TaskIdFocusFire;
	
	DBM_StatBoost( Client, _Stat_Agility, _Stat_Decrease, 100 );
	
	InFocusFire[ Client ] = false;
	
	new Text[ TextLength ];
	formatex( Text, charsmax( Text ),
		"%L %L!",
		Client,
		"CLASS_HUNTER_ABI",
		Client,
		"CLASS_ABILITY_ENDED"
		);
	
	DBM_SkillHudText( Client, 2.0, Text );
}

public DBM_Forward_ClientSpawned( const Client, const ClassIndex )
{
	if( ClassIndex == ClassPointer )
	{
		if( IsHunter[ Client ]
		&& ViewModelBow[ Client ]
		&& get_user_weapon( Client ) == CSW_KNIFE )
		{
			entity_set_string( Client, EV_SZ_viewmodel, CrossbowViewModel ); 
			entity_set_string( Client, EV_SZ_weaponmodel, CrossbowPlayerModel );
		}
	}
}

public Forward_FM_CmdStart_Pre( Client, UCHandle )
{
	if( !is_user_alive( Client )
	|| !IsHunter[ Client ]
	|| DBM_GetClientInClassChange( Client ) )
	{
		return FMRES_IGNORED;
	}
	
	new Buttons = get_uc( UCHandle, UC_Buttons );
	new OldButtons = entity_get_int( Client, EV_INT_oldbuttons );
	new Weapon = get_user_weapon( Client );
	if( Buttons & IN_RELOAD
	&& !( OldButtons & IN_RELOAD )
	&& Weapon == CSW_KNIFE )
	{
		if( ViewModelBow[ Client ] )
		{
			ViewModelBow[ Client ] = false;
			
			entity_set_string( Client, EV_SZ_viewmodel, "models/v_knife.mdl" ); 
			entity_set_string( Client, EV_SZ_weaponmodel, "models/p_knife.mdl" );
			
			set_pdata_float( Client, m_flNextAttack, 0.8, XO_PLAYER );
		}
		else
		{
			ViewModelBow[ Client ] = true;
			
			entity_set_string( Client, EV_SZ_viewmodel, CrossbowViewModel ); 
			entity_set_string( Client, EV_SZ_weaponmodel, CrossbowPlayerModel );
		}
	}
	
	return FMRES_IGNORED;
}

public Forward_FM_ArrowTouch_Pre( Entity, Client )
{
	if( Entity
	&& is_valid_ent( Entity ) )
	{
		new ClassName[ MaxSlots ];
		entity_get_string( Entity, EV_SZ_classname, ClassName, charsmax( ClassName ) );
		
		if( equal( ClassName, "crossbow_arrow" ) )
		{
			new Float:Damage = ( entity_get_float( Entity, EV_FL_dmg ) * 3.0 ) / 5.0;
			
			entity_get_string( Client, EV_SZ_classname, ClassName, charsmax( ClassName ) );
			if( equal( ClassName, "player" ) )
			{
				new Owner = entity_get_edict( Entity, EV_ENT_owner );
				if( Owner == Client
				|| cs_get_user_team( Owner ) == cs_get_user_team( Client ) )
				{
					return FMRES_IGNORED;
				}
				
				if( Damage >= entity_get_float( Client, EV_FL_health )
				&& !DBM_IsMonsterRound( ) )
				{
					ExecuteHamB( Ham_Killed, Client, Owner, 0 );
				}
				else
				{
					ExecuteHamB( Ham_TakeDamage, Client, Entity, Owner, Damage, DMG_NEVERGIB );
					
					message_begin( MSG_ONE_UNRELIABLE, MsgIdScreenShake, _, Client );
					{
						write_short( 7 << 14 ); 
						write_short( 1 << 13 ); 
						write_short( 1 << 14 );
					}
					message_end( );
					
					UTIL_Bleed( Client, 248 );
					
					switch( random_num( 0, 1 ) )
					{
						case 0: 
						{
							emit_sound( Client, CHAN_STATIC, "weapons/xbow_hitbod1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
						}
						case 1: 
						{
							emit_sound( Client, CHAN_STATIC, "weapons/xbow_hitbod2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
						}
					}
				}
			}
			else if( equal( ClassName, "func_wall" ) 
			&& entity_get_int( Client, EV_INT_flags ) & FL_MONSTER )
			{
				new Owner = entity_get_edict( Entity, EV_ENT_owner );
				
				if( Damage >= entity_get_float( Client, EV_FL_health ) )
				{
					ExecuteHamB( Ham_Killed, Client, Owner, 0 );
				}
				else
				{
					ExecuteHamB( Ham_TakeDamage, Client, Entity, Owner, Damage, DMG_NEVERGIB );
					
					switch( random_num( 0, 1 ) )
					{
						case 0: 
						{
							emit_sound( Client, CHAN_STATIC, "weapons/xbow_hitbod1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
						}
						case 1: 
						{
							emit_sound( Client, CHAN_STATIC, "weapons/xbow_hitbod2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
						}
					}
				}
			}
			else
			{
				emit_sound( Client, CHAN_STATIC, "weapons/xbow_hit1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
			}
			
			remove_entity( Entity );
		}
	}
	
	return FMRES_IGNORED;
}

public Forward_Ham_PrimaryAttack_Pre( Entity )
{
	new Client = get_pdata_cbase( Entity, m_pPlayer, XO_WEAPONS );
	
	if( IsHunter[ Client ]
	&& ViewModelBow[ Client ] )
	{
		new Float:Cooldown = 3.0 - float( DBM_GetTotalStats( Client, _Stat_Intelligence ) / 150 );
		
		set_pdata_float( Entity, m_flNextPrimaryAttack, Cooldown, XO_WEAPONS );
		set_pdata_float( Entity, m_flNextSecondaryAttack, Cooldown, XO_WEAPONS );
		
		set_pdata_float( Client, m_flNextAttack, Cooldown, XO_PLAYER );
		
		DispatchArrow( Client );
	}
}

public Forward_Ham_ItemDeploy_Post( Entity )
{
	new Client = get_pdata_cbase( Entity, m_pPlayer, XO_WEAPONS );
	
	if( IsHunter[ Client ]
	&& ViewModelBow[ Client ] )
	{
		entity_set_string( Client, EV_SZ_viewmodel, CrossbowViewModel ); 
		entity_set_string( Client, EV_SZ_weaponmodel, CrossbowPlayerModel );
	}
	else if( IsHunter[ Client ] )
	{
		entity_set_string( Client, EV_SZ_viewmodel, "models/v_knife.mdl" ); 
		entity_set_string( Client, EV_SZ_weaponmodel, "models/p_knife.mdl" );
	}
}

public Forward_FM_EmitSound( Entity, Channel, const Sound[ ], Float:Volume, Float:Attenuation, Flags, Pitch )
{
	if( ( equal( Sound, "weapons/knife_deploy1.wav" )
	|| equal( Sound, "weapons/knife_hitwall1.wav" )
	|| equal( Sound, "weapons/knife_slash1.wav" )
	|| equal( Sound, "weapons/knife_slash2.wav" )
	|| equal( Sound, "weapons/knife_stab.wav" ) )
	&& IsHunter[ Entity ]
	&& ViewModelBow[ Entity ] )
	{
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

DispatchArrow( const Client )
{
	new Float:Origin[ 3 ];
	new Float:Angle[ 3 ];
	entity_get_vector( Client, EV_VEC_origin, Origin );
	entity_get_vector( Client, EV_VEC_v_angle, Angle );
	
	new Entity = create_entity( "info_target" );
	
	entity_set_string( Entity, EV_SZ_classname, "crossbow_arrow" );
	entity_set_model( Entity, CrossbowBoltModel );
	
	new Float:Mins[ 3 ] = { -2.8, -2.8, -0.8 };
	new Float:Maxs[ 3 ] = { 2.8, 2.8, 2.0 };
	entity_set_vector( Entity, EV_VEC_mins, Mins );
	entity_set_vector( Entity, EV_VEC_maxs, Maxs );
	
	Angle[ 0 ] *= -1;
	Origin[ 2 ] += 10;
	
	entity_set_origin( Entity, Origin );
	entity_set_vector( Entity, EV_VEC_angles, Angle );
	
	entity_set_int( Entity, EV_INT_effects, EF_MUZZLEFLASH );
	entity_set_int( Entity, EV_INT_solid, SOLID_TRIGGER );
	entity_set_int( Entity, EV_INT_movetype, MOVETYPE_FLY );
	
	entity_set_edict( Entity, EV_ENT_owner, Client );
	
	new Float:Damage = 30.0 + ( DBM_GetTotalStats( Client, _Stat_Agility ) * 0.8 );
	entity_set_float( Entity, EV_FL_dmg, Damage );
	
	set_rendering( Entity, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 56 );
	
	new Float:Velocity[ 3 ];
	VelocityByAim( Client, 1500, Velocity );
	entity_set_vector( Entity, EV_VEC_velocity, Velocity );
	
	emit_sound( Client, CHAN_STATIC, "weapons/xbow_fire1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
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