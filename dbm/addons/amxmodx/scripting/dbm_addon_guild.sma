#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < engine >
#include < hamsandwich >
#include < fun >
#include < colorchat >
#include < dbm_api >
#include < sqlvault_ex >

const SecondsInWeek = 604800;
const SecondsInHour = 3600;

enum _:GuildDataStruct
{
	_Guild_Name[ 64 ],
	Array:_Guild_Timed_Items,
	_Guild_Experience,
	Trie:_Guild_Members,
	_Guild_Member_Count
};
	
enum _:GuildTimedDataStruct
{
	_Guild_Item_Exp_Boost,
	_Guild_Item_Int_Boost,
	_Guild_Item_Sta_Boost,
	_Guild_Item_Dex_Boost,
	_Guild_Item_Agi_Boost,
	_Guild_Item_Reg_Boost
}

enum _:GuildStatusStruct
{
	_Guild_Status_None,
	_Guild_Status_Member,
	_Guild_Status_Admin,
	_Guild_Status_Leader
};

new const GuildStatusNames[ GuildStatusStruct ][ ] =
{
	"GUILD_MEMBER_NONE",
	"GUILD_MEMBER_MEMBER",
	"GUILD_MEMBER_ADMIN",
	"GUILD_MEMBER_LEADER"
};

new const GuildTimedDataKey[ GuildTimedDataStruct ][ ] = 
{
	"EXPBoost",
	"INTBoost",
	"STABoost",
	"DEXBoost",
	"AGIBoost",
	"REGBoost"
};

new const GuildTimedDataNames[ GuildTimedDataStruct ][ ] = 
{
	"GUILD_ITEM_EXP_BOOST",
	"GUILD_ITEM_INT_BOOST",
	"GUILD_ITEM_STA_BOOST",
	"GUILD_ITEM_DEX_BOOST",
	"GUILD_ITEM_AGI_BOOST",
	"GUILD_ITEM_REG_BOOST"
};

new const Stat[ GuildTimedDataStruct ] =
{
	0,
	_Stat_Intelligence,
	_Stat_Stamina,
	_Stat_Dexterity,
	_Stat_Agility,
	_Stat_Regeneration
};

new Array:Guilds;

new Trie:GuildNames;
new Trie:GuildItems;

new SteamId[ MaxSlots + 1 ][ MaxSteamIdChars ];

new PlayerGuild[ MaxSlots + 1 ];

new InviteRequest[ MaxSlots + 1 ];

new CvarGuildExpKill;
new CvarGuildExpHeadshot;

new CostCvars[ GuildTimedDataStruct ];
new BoostCvars[ GuildTimedDataStruct ];

new TimedEntity;

new MaxPlayers;

new SQLVault:VaultHandle;

public plugin_init( )
{
	register_plugin( "Diablo Mod Addon: Guild System", "0.0.1", "Xellath" );
	
	if( !is_plugin_loaded( "dbm_core.amxx", true ) )
	{
		set_fail_state( "[ Diablo Mod Guild System ] DBM Core needs to be loaded in order for this plugin to run correctly!" );
	}
	
	register_clcmd( "say", "ClientCommand_GuildChat" );
	register_clcmd( "say_team", "ClientCommand_GuildChat" );
	
	register_clcmd( "enter_guild_name", "ClientCommand_CreateGuild" );
	
	CvarGuildExpKill = register_cvar( "dbm_guild_exp_kill", "100" );
	CvarGuildExpHeadshot = register_cvar( "dbm_guild_exp_hs", "50" );
	
	CostCvars[ _Guild_Item_Exp_Boost ] = register_cvar( "dbm_guild_exp_cost", "10000" );
	CostCvars[ _Guild_Item_Int_Boost ] = register_cvar( "dbm_guild_int_cost", "7000" );
	CostCvars[ _Guild_Item_Sta_Boost ] = register_cvar( "dbm_guild_sta_cost", "7000" );
	CostCvars[ _Guild_Item_Dex_Boost ] = register_cvar( "dbm_guild_dex_cost", "7000" );
	CostCvars[ _Guild_Item_Agi_Boost ] = register_cvar( "dbm_guild_agi_cost", "7000" );
	CostCvars[ _Guild_Item_Reg_Boost ] = register_cvar( "dbm_guild_reg_cost", "7000" );
	
	BoostCvars[ _Guild_Item_Exp_Boost ] = register_cvar( "dbm_guild_exp_boost", "1.0" );
	BoostCvars[ _Guild_Item_Int_Boost ] = register_cvar( "dbm_guild_int_boost", "15" );
	BoostCvars[ _Guild_Item_Sta_Boost ] = register_cvar( "dbm_guild_sta_boost", "15" );
	BoostCvars[ _Guild_Item_Dex_Boost ] = register_cvar( "dbm_guild_dex_boost", "15" );
	BoostCvars[ _Guild_Item_Agi_Boost ] = register_cvar( "dbm_guild_agi_boost", "15" );
	BoostCvars[ _Guild_Item_Reg_Boost ] = register_cvar( "dbm_guild_reg_boost", "15" );
	
	register_event( "DeathMsg", "Event_DeathMsg", "a" );
	
	MaxPlayers = get_maxplayers( );
	
	TimedEntity = create_entity( "info_target" );
	entity_set_string( TimedEntity, EV_SZ_classname, "timed_think" );
	
	entity_set_float( TimedEntity, EV_FL_nextthink, get_gametime( ) + float( SecondsInHour / 2 ) );
	
	register_think( "timed_think", "Forward_Engine_TimedThink" );
	
	Guilds = ArrayCreate( GuildDataStruct );
	
	GuildNames = TrieCreate( );
	GuildItems = TrieCreate( );
	
	for( new KeyIndex = 0; KeyIndex < sizeof( GuildTimedDataKey ); KeyIndex++ )
	{
		TrieSetCell( GuildItems, GuildTimedDataKey[ KeyIndex ], KeyIndex );
	}
	
	VaultHandle = sqlv_open_default( "dbm_guild_addon", false );
	sqlv_init_ex( VaultHandle );
	
	LoadGuilds( );
	
	DBM_RegisterMenuAddon( "GUILD_SYSTEM", "ClientCommand_GuildSystem", "dbm_addon_guild.amxx" );
	
	DBM_RegisterCommand( "COMMAND_GUILD", "ClientCommand_GuildSystem" );
	DBM_RegisterCommandToList( "COMMAND_GUILD", "ClientCommand_GuildSystem", "COMMANDLIST_GUILD" );
	
	register_dictionary_colored( "dbm_core_lang.txt" );
	register_dictionary_colored( "dbm_addon_lang.txt" );
}

public plugin_end( )
{
	SaveGuilds( );
	
	sqlv_close( VaultHandle );
	
	new GuildData[ GuildDataStruct ];
	new CurrentMaxGuilds = ArraySize( Guilds );
	for( new GuildIndex = 0; GuildIndex < CurrentMaxGuilds; GuildIndex++ )
	{
		ArrayGetArray( Guilds, GuildIndex, GuildData );
		
		ArrayDestroy( GuildData[ _Guild_Timed_Items ] );
		
		TrieDestroy( GuildData[ _Guild_Members ] );
	}
	
	ArrayDestroy( Guilds );
}

public plugin_natives( )
{
	register_native( "DBM_GetClientGuild", "_DBM_GetClientGuild" );
	
	register_native( "DBM_GetGuildName", "_DBM_GetGuildName" );
}

public _DBM_GetClientGuild( Plugin, Params )
{
	return PlayerGuild[ get_param( 1 ) ];
}

public _DBM_GetGuildName( Plugin, Params )
{
	new GuildPointer = get_param( 1 );
	new GuildData[ GuildDataStruct ];
	ArrayGetArray( Guilds, GuildPointer, GuildData );
	
	set_string( 2, GuildData[ _Guild_Name ], charsmax( GuildData[ _Guild_Name ] ) );
}

public client_putinserver( Client )
{
	get_user_authid( Client, SteamId[ Client ], charsmax( SteamId[ ] ) );
	
	if( equal( SteamId[ Client ], "STEAM_ID_LAN" ) )
	{
		SteamId[ Client ][ 0 ] = 0;
		get_user_name( Client, SteamId[ Client ], charsmax( SteamId[ ] ) );
	}
	
	PlayerGuild[ Client ] = GetClientGuild( Client );
	
	if( PlayerGuild[ Client ] > -1 )
	{
		new GuildData[ GuildDataStruct ];
		ArrayGetArray( Guilds, PlayerGuild[ Client ], GuildData );
		
		new GuildItemData[ GuildTimedDataStruct ];
		ArrayGetArray( GuildData[ _Guild_Timed_Items ], 0, GuildItemData );
		for( new GuildItemIndex = 1; GuildItemIndex < GuildTimedDataStruct; GuildItemIndex++ )
		{
			if( GuildItemData[ GuildItemIndex ] > 0 )
			{
				DBM_StatBoost( Client, Stat[ GuildItemIndex ], _Stat_Increase, get_pcvar_num( BoostCvars[ GuildItemIndex ] ) );
			}
		}
	}
	
	SetEXPBoost( Client );
}

public client_disconnect( Client )
{
	SteamId[ Client ][ 0 ] = 0;
	
	PlayerGuild[ Client ] = -1;
}

public ClientCommand_GuildSystem( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowGuildMenu( Client );
	}
	
	return PLUGIN_HANDLED;
}

public ClientCommand_GuildChat( Client )
{
	if( is_user_connected( Client ) 
	&& PlayerGuild[ Client ] > -1 )
	{
		new Message[ 192 ];
		read_args( Message, charsmax( Message ) );
		remove_quotes( Message );
		
		if( equali( Message, "/g ", 3 ) 
		|| equali( Message, "!g ", 3 ) 
		|| equali( Message, ".g ", 3 ) )
		{
			replace_all( Message, charsmax( Message ), "%s", " s" );
			
			new ClientName[ MaxSlots ];
			get_user_name( Client, ClientName, charsmax( ClientName ) );
			for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
			{
				if( is_user_connected( MemberIndex )
				&& PlayerGuild[ MemberIndex ] == PlayerGuild[ Client ] )
				{
					format( Message, charsmax( Message ),
						"^1(^4%L^1) [^4%L^1]^3 %s ^1: %s", 
						MemberIndex, 
						"GUILD",
						MemberIndex,
						GuildStatusNames[ GetGuildStatus( Client, PlayerGuild[ Client ] ) ],
						ClientName,
						Message[ 3 ]
						);
					
					client_print_color( MemberIndex, DontChange, Message );
				}
			}
			
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

SetEXPBoost( const Client )
{
	if( PlayerGuild[ Client ] > -1 )
	{
		new GuildData[ GuildDataStruct ];
		ArrayGetArray( Guilds, PlayerGuild[ Client ], GuildData );
		
		new GuildItemData[ GuildTimedDataStruct ];
		ArrayGetArray( GuildData[ _Guild_Timed_Items ], 0, GuildItemData );
		
		if( GuildItemData[ _Guild_Item_Exp_Boost ] > 0 )
		{
			DBM_AddExperienceMultiplier( Client, get_pcvar_float( BoostCvars[ _Guild_Item_Exp_Boost ] ) );
		}
	}
}

public Forward_Engine_TimedThink( Entity )
{
	if( is_valid_ent( Entity ) 
	&& TimedEntity == Entity )
	{
		new GuildData[ GuildDataStruct ];
		new GuildItemData[ GuildTimedDataStruct ];
		new CurrentMaxGuilds = ArraySize( Guilds );
		for( new GuildIndex = 0, GuildItemIndex; GuildIndex < CurrentMaxGuilds; GuildIndex++ )
		{
			ArrayGetArray( Guilds, GuildIndex, GuildData );
			
			ArrayGetArray( GuildData[ _Guild_Timed_Items ], 0, GuildItemData );
			
			for( GuildItemIndex = 0; GuildItemIndex < GuildTimedDataStruct; GuildItemIndex++ )
			{
				if( GuildItemData[ GuildItemIndex ] <= 0 )
				{
					GuildItemData[ GuildItemIndex ] = 0;
				}
			}
			
			ArraySetArray( GuildData[ _Guild_Timed_Items ], 0, GuildItemData );
		}
		
		entity_set_float( Entity, EV_FL_nextthink, get_gametime( ) + float( SecondsInHour / 2 ) );
	}
}

public Event_DeathMsg( )
{
	new Attacker = read_data( 1 );
	if( PlayerGuild[ Attacker ] == -1 )
	{
		return;
	}
	
	new Victim = read_data( 2 );
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& Victim != Attacker
	&& is_user_connected( Victim ) 
	&& is_user_connected( Attacker )
	&& cs_get_user_team( Victim ) != cs_get_user_team( Attacker ) )
	{
		new GuildData[ GuildDataStruct ];
		ArrayGetArray( Guilds, PlayerGuild[ Attacker ], GuildData );
		
		GuildData[ _Guild_Experience ] += ( get_pcvar_num( CvarGuildExpKill ) + ( bool:read_data( 3 ) ? get_pcvar_num( CvarGuildExpHeadshot ) : 0 ) );
		
		ArraySetArray( Guilds, PlayerGuild[ Attacker ], GuildData );
	}
}

LoadGuilds( )
{
	new ConfigsDirectory[ 60 ];
	get_configsdir( ConfigsDirectory, charsmax( ConfigsDirectory ) );
	add( ConfigsDirectory, charsmax( ConfigsDirectory ), "/dbm_guilds.ini" );
	
	new File = fopen( ConfigsDirectory, "rt" );
	
	new GuildData[ GuildDataStruct ];
	new GuildItemData[ GuildTimedDataStruct ];
	new Buffer[ 512 ];
	new Data[ 6 ];
	new Value[ 10 ];
	new CurrentGuild;
	new CurrentItem;
	while( !feof( File ) )
	{
		fgets( File, Buffer, charsmax( Buffer ) );
		
		trim( Buffer );
		remove_quotes( Buffer );
		
		if( !Buffer[ 0 ] || Buffer[ 0 ] == ';' ) 
		{
			continue;
		}
		
		if( Buffer[ 0 ] == '[' 
		&& Buffer[ strlen( Buffer ) - 1 ] == ']' )
		{
			copy( GuildData[ _Guild_Name ], strlen( Buffer ) - 2, Buffer[ 1 ] );
			GuildData[ _Guild_Timed_Items ] = _:ArrayCreate( GuildTimedDataStruct );
			GuildData[ _Guild_Experience ] = 0;
			GuildData[ _Guild_Members ] = _:TrieCreate( );
			GuildData[ _Guild_Member_Count ] = 0;
			
			if( TrieKeyExists( GuildNames, GuildData[ _Guild_Name ] ) )
			{
				new Error[ 256 ];
				formatex( Error, charsmax( Error ), 
					"[ Diablo Mod Guild System ] Guild already exists: %s", 
					GuildData[ _Guild_Name ] 
					);
				
				set_fail_state( Error );
			}
			
			ArrayPushArray( Guilds, GuildData );
			
			ArrayPushArray( GuildData[ _Guild_Timed_Items ], GuildItemData );
			
			TrieSetCell( GuildNames, GuildData[ _Guild_Name ], CurrentGuild );
			
			CurrentGuild++;
			
			continue;
		}
		
		strtok( Buffer, Data, charsmax( Data ), Value, charsmax( Value ), '=' );
		trim( Data );
		trim( Value );
		
		if( TrieGetCell( GuildItems, Data, CurrentItem ) )
		{
			GuildItemData[ CurrentItem ] = str_to_num( Value );
			
			if( GuildItemData[ CurrentItem ] <= get_systime( ) )
			{
				GuildItemData[ CurrentItem ] = 0;
			}
			
			ArrayGetArray( GuildData[ _Guild_Timed_Items ], 0, GuildItemData );
		}
	}
	
	new Array:AllEntries;
	sqlv_read_all_ex( VaultHandle, AllEntries );
	
	new VaultData[ SQLVaultEntryEx ];
	new CurrentMaxEntries = ArraySize( AllEntries );
	new CurGuild;
	for( new EntryIndex = 0; EntryIndex < CurrentMaxEntries; EntryIndex++ )
	{
		ArrayGetArray( AllEntries, EntryIndex, VaultData );
		
		if( TrieGetCell( GuildNames, VaultData[ SQLVEx_Key2 ], CurGuild ) )
		{
			ArrayGetArray( Guilds, CurGuild, GuildData );
			
			TrieSetCell( GuildData[ _Guild_Members ], VaultData[ SQLVEx_Key1 ], str_to_num( VaultData[ SQLVEx_Data ] ) );
			
			GuildData[ _Guild_Member_Count ]++;
			
			ArraySetArray( Guilds, CurGuild, GuildData );
		}
	}
	
	fclose( File );
}

SaveGuilds( )
{
	new ConfigsDirectory[ 60 ];
	get_configsdir( ConfigsDirectory, charsmax( ConfigsDirectory ) );
	add( ConfigsDirectory, charsmax( ConfigsDirectory ), "/dbm_guilds.ini" );
	
	if( file_exists( ConfigsDirectory ) )
	{
		delete_file( ConfigsDirectory );
	}
	
	new File = fopen( ConfigsDirectory, "wt" );
	
	new GuildData[ GuildDataStruct ];
	new GuildItemData[ GuildTimedDataStruct ];
	new CurrentMaxGuilds = ArraySize( Guilds );
	new Buffer[ 256 ];
	for( new GuildIndex = 0, GuildItemIndex; GuildIndex < CurrentMaxGuilds; GuildIndex++ )
	{
		ArrayGetArray( Guilds, GuildIndex, GuildData );
		
		formatex( Buffer, charsmax( Buffer ), "[%s]^n", GuildData[ _Guild_Name ] );
		fputs( File, Buffer );
		
		ArrayGetArray( GuildData[ _Guild_Timed_Items ], 0, GuildItemData );
		for( GuildItemIndex = 0; GuildItemIndex < GuildTimedDataStruct; GuildItemIndex++ )
		{
			formatex( Buffer, charsmax( Buffer ),
				"%s=%i^n",
				GuildTimedDataKey[ GuildItemIndex ],
				GuildItemData[ GuildItemIndex ]
				);
				
			fputs( File, Buffer );
		}
	}
	
	fclose( File );
}

ShowGuildMenu( Client )
{
	new Title[ 256 ];
	new GuildData[ GuildDataStruct ];
	if( PlayerGuild[ Client ] == -1 )
	{
		formatex( Title, charsmax( Title ), 
			"%L^n\w%L %L^n^n",
			Client,
			"MENU_PREFIX",
			Client,
			"GUILD_SYSTEM",
			Client,
			"MENU"
			);
	}
	else
	{
		ArrayGetArray( Guilds, PlayerGuild[ Client ], GuildData );
		
		formatex( Title, charsmax( Title ), 
			"%L^n\w%L %L^n^n%L:\y %s^n\w%L: \y%L^n\w%L: \y%i\w^n",
			Client,
			"MENU_PREFIX",
			Client,
			"GUILD_SYSTEM",
			Client,
			"MENU",
			Client,
			"GUILD_MENU_YOUR",
			GuildData[ _Guild_Name ],
			Client,
			"GUILD_MENU_MEMBERSHIP",
			Client,
			GuildStatusNames[ GetGuildStatus( Client, PlayerGuild[ Client ] ) ],
			Client,
			"MENU_PARTY_MEMBERS",
			GuildData[ _Guild_Member_Count ]
			);
	}
	
	new Menu = menu_create( Title, "GuildSystemHandler" );
	
	if( PlayerGuild[ Client ] == -1 )
	{
		formatex( Title, charsmax( Title ), 
			"%L^n^n%L: \y%i \w(\y%i %L\w)^n",
			Client,
			"GUILD_MENU_CREATE",
			Client,
			"GUILD_MENU_CURRENT_AMOUNT",
			ArraySize( Guilds ),
			MaxGuilds,
			Client,
			"MAX"
			);
			
		menu_additem( Menu, Title, "1" );
		
		formatex( Title, charsmax( Title ), 
			"%L",
			Client,
			"GUILD_MENU_STATISTICS"
			);
		
		menu_additem( Menu, Title, "2" );
	}
	else
	{
		if( GetGuildStatus( Client, PlayerGuild[ Client ] ) >= _Guild_Status_Admin )
		{
			formatex( Title, charsmax( Title ), 
				"%L",
				Client,
				"GUILD_MENU_INVITE"
				);
		
			menu_additem( Menu, Title, "1" );
			
			formatex( Title, charsmax( Title ), 
				"%L^n",
				Client,
				"GUILD_MENU_KICK"
				);
			
			menu_additem( Menu, Title, "2" );
			
			formatex( Title, charsmax( Title ), 
				"%L^n",
				Client,
				"GUILD_MENU_BOOSTS"
				);
			
			menu_additem( Menu, Title, "3" );
			
			formatex( Title, charsmax( Title ), 
				"%L^n",
				Client,
				"GUILD_MENU_ONLINE"
				);
			
			menu_additem( Menu, Title, "4" );
			
			if( GetGuildStatus( Client, PlayerGuild[ Client ] ) == _Guild_Status_Leader )
			{
				formatex( Title, charsmax( Title ), 
					"%L^n",
					Client,
					"GUILD_MENU_ADMINISTRATE"
					);
			
				menu_additem( Menu, Title, "5" );
			}
			else
			{
				formatex( Title, charsmax( Title ), 
					"%L^n",
					Client,
					"GUILD_MENU_LEAVE"
					);
			
				menu_additem( Menu, Title, "6" );
			}
			
			formatex( Title, charsmax( Title ), 
				"%L^n",
				Client,
				"GUILD_MENU_STATISTICS"
				);
			
			menu_additem( Menu, Title, "7" );
		}
		else
		{
			formatex( Title, charsmax( Title ), 
				"%L^n",
				Client,
				"GUILD_MENU_BOOSTS"
				);
			
			menu_additem( Menu, Title, "3" );
			
			formatex( Title, charsmax( Title ), 
				"%L^n",
				Client,
				"GUILD_MENU_ONLINE"
				);
			
			menu_additem( Menu, Title, "4" );
			
			formatex( Title, charsmax( Title ), 
				"%L^n",
				Client,
				"GUILD_MENU_STATISTICS"
				);
			
			menu_additem( Menu, Title, "7" );
			
			formatex( Title, charsmax( Title ), 
					"%L^n",
					Client,
					"GUILD_MENU_LEAVE"
					);
			
			menu_additem( Menu, Title, "6" );
		}
	}
	
	formatex( Title, charsmax( Title ),
		"%L",
		Client,
		"EXIT"
		);

	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public GuildSystemHandler( Client, Menu, Item )
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
	
	if( PlayerGuild[ Client ] == -1 )
	{
		if( Info[ 0 ] == '1' )
		{
			client_cmd( Client, "messagemode enter_guild_name" );
			
			client_print_color( Client, DontChange, 
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"GUILD_ENTER_NAME"
				);
		}
		else if( Info[ 0 ] == '2' )
		{
			GuildStatistics( Client );
		}
	}
	else
	{
		switch( Info[ 0 ] )
		{
			case '1':
			{
				GuildInviteMenu( Client );
			}
			case '2':
			{
				GuildKickMenu( Client );
			}
			case '3':
			{
				GuildBoostsMenu( Client );
			}
			case '4':
			{
				new Message[ 512 ];
				new Len;
				
				Len = formatex( Message, charsmax( Message ) - Len, 
					"%L:^n",
					Client,
					"GUILD_MENU_ONLINE"
					);
				
				new MemberName[ MaxSlots ];
				for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
				{
					if( is_user_connected( MemberIndex )
					&& PlayerGuild[ MemberIndex ] == PlayerGuild[ Client ] )
					{
						get_user_name( MemberIndex, MemberName, charsmax( MemberName ) );
						
						Len += formatex( Message[ Len ], charsmax( Message ) - Len, "%s^n", MemberName );
					}
				}
				
				Len += formatex( Message[ Len ], charsmax( Message ) - Len, 
					"%L",
					Client,
					"GUILD_SEE_HELP"
					);
				
				set_hudmessage( 255, 255, 0, 0.58, 0.24, 1, 0.1, 10.0, 0.1, 0.1, -1 );
				show_hudmessage( Client, Message );
			}
			case '5':
			{
				AdministrateGuildMenu( Client );
			}
			case '6':
			{
				new GuildData[ GuildDataStruct ];
				ArrayGetArray( Guilds, PlayerGuild[ Client ], GuildData );
				
				SetClientGuild( Client, -1 );
				
				client_print_color( Client, DontChange, 
					"^4%L^3 %L",
					Client,
					"MOD_PREFIX",
					Client,
					"GUILD_LEFT",
					GuildData[ _Guild_Name ]
					);
			}
			case '7':
			{
				GuildStatistics( Client );
			}
		}
	}
}

AdministrateGuildMenu( const Client )
{
	new Title[ 256 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"GUILD_MENU_ADMINISTRATE",
		Client,
		"MENU"
		);
	
	new Menu = menu_create( Title, "AdministrateMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L",
		Client,
		"GUILD_MENU_PROMOTE"
		);
	
	menu_additem( Menu, Title, "1" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"GUILD_MENU_DEMOTE"
		);
	
	menu_additem( Menu, Title, "2" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"GUILD_MENU_TRANSFER"
		);
	
	menu_additem( Menu, Title, "3" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"GUILD_MENU_DISBAND"
		);
	
	menu_additem( Menu, Title, "4" );
	
	formatex( Title, charsmax( Title ),
		"%L %L",
		Client,
		"GUILD_SYSTEM",
		Client,
		"MENU"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public AdministrateMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
		
		ShowGuildMenu( Client );
		
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
			PromoteMenu( Client );
		}
		case '2':
		{
			DemoteMenu( Client );
		}
		case '3':
		{
			GuildTransferMenu( Client );
		}
		case '4':
		{
			new Guild = PlayerGuild[ Client ];
			
			new GuildData[ GuildDataStruct ];
			ArrayGetArray( Guilds, PlayerGuild[ Client ], GuildData );
			
			client_print_color( Client, DontChange, 
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"GUILD_DISBANDED_SUCC"
				);
			
			for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
			{
				if( is_user_connected( MemberIndex )
				&& PlayerGuild[ MemberIndex ] == PlayerGuild[ Client ] )
				{
					client_print_color( MemberIndex, DontChange, 
						"^4%L^3 %L",
						MemberIndex,
						"MOD_PREFIX",
						MemberIndex,
						"GUILD_DISBANDED_SUCC2",
						GuildData[ _Guild_Name ]
						);
					
					SetClientGuild( MemberIndex, -1 );
				}
			}
			
			SetClientGuild( Client, -1 );
			
			ArrayDeleteItem( Guilds, Guild );
		}
	}
}

PromoteMenu( const Client )
{
	new Title[ 128 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"GUILD_MENU_PROMOTE",
		Client,
		"MENU"
		);
	
	new Menu = menu_create( Title, "PromoteMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L %L^n\y%L\w^n",
		Client,
		"GUILD_MENU_DEMOTE",
		Client,
		"MENU",
		Client,
		"GUILD_MENU_PROMOTE2"
		);
	
	menu_additem( Menu, Title, "*" );
	
	new MemberName[ MaxSlots ];
	new Info[ 3 ];
	for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
	{
		if( is_user_connected( MemberIndex )
		&& GetGuildStatus( MemberIndex, PlayerGuild[ MemberIndex ] ) == _Guild_Status_Member )
		{
			get_user_name( MemberIndex, MemberName, charsmax( MemberName ) );
			num_to_str( MemberIndex, Info, charsmax( Info ) );
			
			menu_additem( Menu, MemberName, Info );
		}
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
		"%L %L",
		Client,
		"GUILD_MENU_ADMINISTRATE",
		Client,
		"MENU"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public PromoteMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
	
		AdministrateGuildMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	if( Info[ 0 ] == '*' )
	{
		DemoteMenu( Client );
		
		return;
	}
	
	new Player = str_to_num( Info );
	
	SetClientGuild( Player, PlayerGuild[ Player ], _Guild_Status_Admin );
	
	new PlayerName[ MaxSlots ];
	get_user_name( Player, PlayerName, charsmax( PlayerName ) );
	
	for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
	{
		if( is_user_connected( MemberIndex )
		&& PlayerGuild[ MemberIndex ] == PlayerGuild[ Client ] )
		{
			client_print_color( MemberIndex, DontChange,
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"GUILD_PROMOTED",
				PlayerName
				);
		}
	}
}

DemoteMenu( const Client )
{
	new Title[ 128 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"GUILD_MENU_DEMOTE",
		Client,
		"MENU"
		);
	
	new Menu = menu_create( Title, "DemoteMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L %L^n\y%L\w^n",
		Client,
		"GUILD_MENU_PROMOTE",
		Client,
		"MENU",
		Client,
		"GUILD_MENU_DEMOTE2"
		);
		
	menu_additem( Menu, Title, "*" );
	
	new MemberName[ MaxSlots ];
	new Info[ 3 ];
	for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
	{
		if( is_user_connected( MemberIndex )
		&& GetGuildStatus( MemberIndex, PlayerGuild[ MemberIndex ] ) == _Guild_Status_Admin )
		{
			get_user_name( MemberIndex, MemberName, charsmax( MemberName ) );
			num_to_str( MemberIndex, Info, charsmax( Info ) );
			
			menu_additem( Menu, MemberName, Info );
		}
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
		"%L %L",
		Client,
		"GUILD_MENU_ADMINISTRATE",
		Client,
		"MENU"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public DemoteMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
	
		AdministrateGuildMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	if( Info[ 0 ] == '*' )
	{
		PromoteMenu( Client );
		
		return;
	}
	
	new Player = str_to_num( Info );
	
	SetClientGuild( Player, PlayerGuild[ Player ], _Guild_Status_Member );
	
	new PlayerName[ MaxSlots ];
	get_user_name( Player, PlayerName, charsmax( PlayerName ) );
	
	for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
	{
		if( is_user_connected( MemberIndex )
		&& PlayerGuild[ MemberIndex ] == PlayerGuild[ Client ] )
		{
			client_print_color( MemberIndex, DontChange,
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"GUILD_DEMOTED",
				PlayerName
				);
		}
	}
}

GuildStatistics( const Client )
{
	new Title[ 256 ];
	new CurrentMaxGuilds = ArraySize( Guilds );
	if( CurrentMaxGuilds == 0 )
	{
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"GUILD_NOGUILDS"
			);
		
		ShowGuildMenu( Client );
	}
	
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L^n^n%L:\y %i^n\w^n",
		Client,
		"MENU_PREFIX",
		Client,
		"GUILD_MENU_LIST",
		Client,
		"MENU",
		Client,
		"GUILD_MENU_TOTAL",
		CurrentMaxGuilds
		);
	
	new Menu = menu_create( Title, "ListMenuHandler" );
	
	new GuildData[ GuildDataStruct ];
	new GuildNumber[ 3 ];
	for( new GuildIndex = 0; GuildIndex < CurrentMaxGuilds; GuildIndex++ )
	{
		ArrayGetArray( Guilds, GuildIndex, GuildData );
		
		num_to_str( GuildIndex, GuildNumber, charsmax( GuildNumber ) );
		
		menu_additem( Menu, GuildData[ _Guild_Name ], GuildNumber );
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
		"%L %L",
		Client,
		"GUILD_SYSTEM",
		Client,
		"MENU"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public ListMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
		
		ShowGuildMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	new Guild = str_to_num( Info );
	
	new GuildData[ GuildDataStruct ];
	ArrayGetArray( Guilds, Guild, GuildData );
	
	new GuildItemData[ GuildTimedDataStruct ];
	ArrayGetArray( GuildData[ _Guild_Timed_Items ], 0, GuildItemData );
	
	new Title[ 512 ];
	formatex( Title, charsmax( Title ), 
		"%L\w^n%L^n^n%L:\y %s^n\wEXP: \y%i\w^n^n\y%L^n\wEXP %L: \y%L^n\wINT %L: \y%L^n\wSTA %L: \y%L^n\wDEX %L: \y%L^n\wAGI %L: \y%L^n\wREG %L: \y%L\w^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"GUILD_MENU_STATISTICS",
		Client,
		"GUILD",
		GuildData[ _Guild_Name ],
		GuildData[ _Guild_Experience ],
		Client,
		"GUILD_UPGRADES",
		Client,
		"GUILD_BOOST",
		Client,
		( GuildItemData[ _Guild_Item_Exp_Boost ] ? "YES" : "NO" ),
		Client,
		"GUILD_BOOST",
		Client,
		( GuildItemData[ _Guild_Item_Int_Boost ] ? "YES" : "NO" ),
		Client,
		"GUILD_BOOST",
		Client,
		( GuildItemData[ _Guild_Item_Sta_Boost ] ? "YES" : "NO" ),
		Client,
		"GUILD_BOOST",
		Client,
		( GuildItemData[ _Guild_Item_Dex_Boost ] ? "YES" : "NO" ),
		Client,
		"GUILD_BOOST",
		Client,
		( GuildItemData[ _Guild_Item_Agi_Boost ] ? "YES" : "NO" ),
		Client,
		"GUILD_BOOST",
		Client,
		( GuildItemData[ _Guild_Item_Reg_Boost ] ? "YES" : "NO" )
		);
		
	new StatMenu = menu_create( Title, "StatisticsMenuHandler" );
	
	formatex( Title, charsmax( Title ),
		"%L %L",
		Client,
		"GUILD_BACKTO",
		Client,
		"GUILD_MENU_LIST"
		);
	
	menu_additem( StatMenu, Title, "1" );
	
	menu_setprop( StatMenu, MPROP_EXIT, MEXIT_NEVER );
	
	menu_display( Client, StatMenu, 0 );
}

public StatisticsMenuHandler( Client, Menu, Item )
{
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	if( Info[ 0 ] == '1' )
	{
		GuildStatistics( Client );
	}
}

GuildBoostsMenu( const Client )
{
	new Title[ 256 ];
	new GuildData[ GuildDataStruct ];
	ArrayGetArray( Guilds, PlayerGuild[ Client ], GuildData );
	
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L^n^n%L:\y %s^n\wEXP: \y%i\w^n",
		Client,
		"MENU_PREFIX",
		Client,
		"GUILD_MENU_BOOSTS",
		Client,
		"MENU",
		Client,
		"GUILD",
		GuildData[ _Guild_Name ],
		GuildData[ _Guild_Experience ]
		);
	
	new Menu = menu_create( Title, "BoostsMenuHandler" );
	
	new GuildItemData[ GuildTimedDataStruct ];
	ArrayGetArray( GuildData[ _Guild_Timed_Items ], 0, GuildItemData );
	
	new Info[ 3 ];
	new Time;
	for( new BoostIndex = 0; BoostIndex < GuildTimedDataStruct; BoostIndex++ )
	{
		if( GuildItemData[ BoostIndex ] )
		{
			Time = ( GuildItemData[ BoostIndex ] - get_systime( ) ) / SecondsInHour;
			
			formatex( Title, charsmax( Title ),
				"%L: \r%i %L\w",
				Client,
				GuildTimedDataNames[ BoostIndex ],
				Client,
				"GUILD_MENU_HOURS",
				Time
				);
		}
		else
		{
			formatex( Title, charsmax( Title ),
				"%L: \y%L\R%i\w",
				Client,
				GuildTimedDataNames[ BoostIndex ],
				Client,
				"GUILD_MENU_WEEK",
				get_pcvar_num( CostCvars[ BoostIndex ] )
				);
		}
		
		num_to_str( BoostIndex, Info, charsmax( Info ) );
		
		menu_additem( Menu, Title, Info, _, menu_makecallback( "BoostCallbackHandler" ) );
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
		"%L %L",
		Client,
		"GUILD_SYSTEM",
		Client,
		"MENU"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public BoostCallbackHandler( Client, Menu, Item )
{
	return GetGuildStatus( Client, PlayerGuild[ Client ] ) == _Guild_Status_Leader ? ITEM_ENABLED : ITEM_DISABLED;
}

public BoostsMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
		
		ShowGuildMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	new BoostIndex = str_to_num( Info );
	new GuildData[ GuildDataStruct ];
	ArrayGetArray( Guilds, PlayerGuild[ Client ], GuildData );
	
	new GuildItemData[ GuildTimedDataStruct ];
	ArrayGetArray( GuildData[ _Guild_Timed_Items ], 0, GuildItemData );
	
	new Cost = get_pcvar_num( CostCvars[ BoostIndex ] );
	if( GuildData[ _Guild_Experience ] >= Cost
	&& GuildItemData[ BoostIndex ] <= 0 )
	{
		GuildItemData[ BoostIndex ] = get_systime( ) + SecondsInWeek;

		ArraySetArray( GuildData[ _Guild_Timed_Items ], 0, GuildItemData );
			
		GuildData[ _Guild_Experience ] -= Cost;
		
		ArraySetArray( Guilds, PlayerGuild[ Client ], GuildData );
		
		for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
		{
			if( is_user_connected( MemberIndex )
			&& PlayerGuild[ MemberIndex ] == PlayerGuild[ Client ] )
			{
				if( BoostIndex != _Guild_Item_Exp_Boost )
				{
					DBM_StatBoost( MemberIndex, Stat[ BoostIndex ], _Stat_Increase, get_pcvar_num( BoostCvars[ BoostIndex ] ) );
				}
				else
				{
					SetEXPBoost( MemberIndex );
				}
				
				client_print_color( MemberIndex, DontChange, 
					"^4%L^3 %L",
					MemberIndex,
					"MOD_PREFIX",
					MemberIndex,
					"GUILD_PURCHASED_SUCC",
					GuildTimedDataNames[ BoostIndex ]
					);
					
				client_print_color( MemberIndex, DontChange, 
					"^4%L^3 %L",
					MemberIndex,
					"MOD_PREFIX",
					MemberIndex,
					"GUILD_PURCHASED_ACTIVE"
					);
			}
		}
	}
	else
	{
		client_print_color( Client, DontChange,
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"GUILD_NOT_ENOUGH_EXP"
			);
	}
}

GuildInviteMenu( const Client )
{
	new Title[ 128 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"GUILD_INVITE_MENU"
		);
	
	new Menu = menu_create( Title, "GuildInviteMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n\y%L\w^n",
		Client,
		"GUILD_KICK_MENU",
		Client,
		"GUILD_INVITE_MENU2"
		);
	
	menu_additem( Menu, Title, "*" );
	
	new PlayerName[ MaxSlots ];
	new Info[ 3 ];
	for( new PlayerIndex = 1; PlayerIndex <= MaxPlayers; PlayerIndex++ )
	{
		if( is_user_connected( PlayerIndex )
		&& PlayerGuild[ PlayerIndex ] == -1
		&& GetGuildStatus( PlayerIndex, PlayerGuild[ PlayerIndex ] ) == _Guild_Status_None )
		{
			get_user_name( PlayerIndex, PlayerName, charsmax( PlayerName ) );
			num_to_str( PlayerIndex, Info, charsmax( Info ) );
			
			menu_additem( Menu, PlayerName, Info );
		}
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
		"%L %L",
		Client,
		"GUILD_SYSTEM",
		Client,
		"MENU"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public GuildInviteMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
	
		ShowGuildMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	if( Info[ 0 ] == '*' )
	{
		GuildKickMenu( Client );
		
		return;
	}
	
	GuildInviteRequest( str_to_num( Info ), Client );
}

GuildInviteRequest( const Player, const Client )
{
	new Title[ 256 ];
	new ClientName[ MaxSlots ];
	get_user_name( Client, ClientName, charsmax( ClientName ) );
	
	new GuildData[ GuildDataStruct ];
	ArrayGetArray( Guilds, PlayerGuild[ Client ], GuildData );
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L^n^n\y%s\w %L '%s'^n", 
		Player,
		"MENU_PREFIX",
		Player,
		"GUILD_REQUEST",
		ClientName,
		Player,
		"GUILD_REQUEST_INV",
		GuildData[ _Guild_Name ]
		);
	
	InviteRequest[ Player ] = Client;
	
	new Menu = menu_create( Title, "GuildRequestMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L",
		Player,
		"ACCEPT"
		);
	
	menu_additem( Menu, Title, "1" );
	
	formatex( Title, charsmax( Title ), 
		"%L",
		Player,
		"DECLINE"
		);
	
	menu_additem( Menu, Title, "2" );
	
	menu_setprop( Menu, MPROP_EXIT, MEXIT_NEVER );
	
	menu_display( Player, Menu, 0 );
}

public GuildRequestMenuHandler( Client, Menu, Item )
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
	
	new ClientName[ MaxSlots ];
	get_user_name( Client, ClientName, charsmax( ClientName ) );
	
	switch( Info[ 0 ] )
	{
		case '1':
		{
			if( GetGuildStatus( Client, PlayerGuild[ Client ] ) == _Guild_Status_Leader )
			{
				client_print_color( Client, DontChange, 
					"^4%L^3 %L",
					Client,
					"MOD_PREFIX",
					Client,
					"GUILD_CANNOT_LEAVE"
					);
				
				return;
			}
			
			SetClientGuild( Client, PlayerGuild[ InviteRequest[ Client ] ] );
			
			for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
			{
				if( is_user_connected( MemberIndex )
				&& PlayerGuild[ MemberIndex ] == PlayerGuild[ Client ] )
				{
					client_print_color( MemberIndex, DontChange, 
						"^4%L^3 %L", 
						MemberIndex,
						"MOD_PREFIX",
						MemberIndex,
						"GUILD_JOINED",
						ClientName 
						);
				}
			}
		}
		case '2':
		{
			client_print_color( InviteRequest[ Client ], DontChange, 
				"^4%L^3 %L", 
				InviteRequest[ Client ],
				"MOD_PREFIX",
				InviteRequest[ Client ],
				"GUILD_DECLINED",
				ClientName 
				);
		}
	}
	
	InviteRequest[ Client ] = 0;
}

GuildKickMenu( const Client )
{
	new Title[ 128 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"GUILD_KICK_MENU"
		);
	
	new Menu = menu_create( Title, "GuildKickMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n\y%L\w^n",
		Client,
		"GUILD_INVITE_MENU",
		Client,
		"GUILD_KICK_MENU2"
		);
		
	menu_additem( Menu, Title, "*" );
	
	new Info[ 3 ];
	new MemberName[ MaxSlots ];
	for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
	{
		if( is_user_connected( MemberIndex )
		&& PlayerGuild[ MemberIndex ] == PlayerGuild[ Client ]
		&& MemberIndex != Client )
		{
			get_user_name( MemberIndex, MemberName, charsmax( MemberName ) );
			
			num_to_str( MemberIndex, Info, charsmax( Info ) );
			
			menu_additem( Menu, MemberName, Info );
		}
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
		"%L %L",
		Client,
		"GUILD_SYSTEM",
		Client,
		"MENU"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public GuildKickMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
	
		ShowGuildMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	if( Info[ 0 ] == '*' )
	{
		GuildInviteMenu( Client );
		
		return;
	}
	
	new Player = str_to_num( Info );
	SetClientGuild( Player, -1 );
	
	client_print_color( Player, DontChange, 
		"^4%L^3 %L",
		Player,
		"MOD_PREFIX",
		Player,
		"GUILD_KICKED"
		);
	
	new PlayerName[ MaxSlots ];
	get_user_name( Player, PlayerName, charsmax( PlayerName ) );
	for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
	{
		if( is_user_connected( MemberIndex )
		&& PlayerGuild[ MemberIndex ] == PlayerGuild[ Player ] )
		{
			client_print_color( MemberIndex, DontChange, 
				"^4%L^3 %L",
				MemberIndex,
				"MOD_PREFIX",
				MemberIndex,
				"GUILD_KICKED2",
				PlayerName
				);
		}
	}
}

GuildTransferMenu( const Client )
{
	new Title[ 128 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L^n^n\y%L\w^n",
		Client,
		"MENU_PREFIX",
		Client,
		"GUILD_TRANSFER_MENU",
		Client,
		"GUILD_TRANSFER_MENU2"
		);
	
	new Menu = menu_create( Title, "GuildTransferMenuHandler" );
	
	new Info[ 3 ];
	new MemberName[ MaxSlots ];
	for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
	{
		if( is_user_connected( MemberIndex )
		&& PlayerGuild[ MemberIndex ] == PlayerGuild[ Client ]
		&& MemberIndex != Client )
		{
			get_user_name( MemberIndex, MemberName, charsmax( MemberName ) );
			
			num_to_str( MemberIndex, Info, charsmax( Info ) );
			
			menu_additem( Menu, MemberName, Info );
		}
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
		"%L %L",
		Client,
		"GUILD_SYSTEM",
		Client,
		"MENU"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public GuildTransferMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
	
		ShowGuildMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	new Player = str_to_num( Info );
	SetClientGuild( Client, PlayerGuild[ Client ], _Guild_Status_Admin );
	SetClientGuild( Player, PlayerGuild[ Player ], _Guild_Status_Leader );
	
	new GuildData[ GuildDataStruct ];
	ArrayGetArray( Guilds, PlayerGuild[ Player ], GuildData );
	
	client_print_color( Client, DontChange,
		"^4%L^3 %L",
		Client,
		"MOD_PREFIX",
		Client,
		"GUILD_TRANSFERRED_SUCC"
		);
		
	client_print_color( Player, DontChange, 
		"^4%L^3 %L",
		Client,
		"MOD_PREFIX",
		Client,
		"GUILD_TRANSFERRED_SUCC2",
		GuildData[ _Guild_Name ]
		);
}

public ClientCommand_CreateGuild( Client )
{
	if( PlayerGuild[ Client ] != -1 )
	{
		client_print_color( Client, DontChange,
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"GUILD_CANNOT_CREATE"
			);
		
		return PLUGIN_HANDLED;
	}
	
	new Args[ 60 ];
	read_args( Args, charsmax( Args ) );
	remove_quotes( Args );
	
	if( TrieKeyExists( GuildNames, Args ) )
	{
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"GUILD_ALREADY_EXISTS",
			Args
			);
		
		ShowGuildMenu( Client );
		
		return PLUGIN_HANDLED;
	}
	
	new GuildData[ GuildDataStruct ];
	GuildData[ _Guild_Name ] = Args;
	GuildData[ _Guild_Timed_Items ] = _:ArrayCreate( GuildTimedDataStruct );
	GuildData[ _Guild_Experience ] = 0;
	GuildData[ _Guild_Members ] = _:TrieCreate( );
	GuildData[ _Guild_Member_Count ] = 0;
	
	ArrayPushArray( Guilds, GuildData );
	
	new GuildItemData[ GuildTimedDataStruct ];
	ArrayPushArray( GuildData[ _Guild_Timed_Items ], GuildItemData );
	
	SetClientGuild( Client, ArraySize( Guilds ) - 1, _Guild_Status_Leader );
	
	client_print_color( Client, DontChange, 
		"^4%L^3 %L", 
		Client,
		"MOD_PREFIX",
		Client,
		"GUILD_CREATED_SUCC",
		Args 
		);
	
	return PLUGIN_HANDLED;
}

SetClientGuild( const Client, const Guild, const Status = _Guild_Status_Member )
{
	new GuildData[ GuildDataStruct ];
	if( PlayerGuild[ Client ] > -1 )
	{
		ArrayGetArray( Guilds, PlayerGuild[ Client ], GuildData );
		
		TrieDeleteKey( GuildData[ _Guild_Members ], SteamId[ Client ] );
		
		GuildData[ _Guild_Member_Count ]--;
		
		ArraySetArray( Guilds, PlayerGuild[ Client ], GuildData );
		
		sqlv_remove_ex( VaultHandle, SteamId[ Client ], GuildData[ _Guild_Name ] );
	}

	if( Guild > -1 )
	{
		ArrayGetArray( Guilds, Guild, GuildData );
		
		TrieSetCell( GuildData[ _Guild_Members ], SteamId[ Client ], Status );
		
		GuildData[ _Guild_Member_Count ]++;
		
		ArraySetArray( Guilds, Guild, GuildData );
		
		sqlv_set_num_ex( VaultHandle, SteamId[ Client ], GuildData[ _Guild_Name ], Status );		
	}

	PlayerGuild[ Client ] = Guild;
	
	return 1;
}
	
GetClientGuild( const Client )
{
	new GuildData[ GuildDataStruct ];
	new CurrentMaxGuilds = ArraySize( Guilds );
	for( new GuildIndex = 0; GuildIndex < CurrentMaxGuilds; GuildIndex++ )
	{
		ArrayGetArray( Guilds, GuildIndex, GuildData );
		
		if( TrieKeyExists( GuildData[ _Guild_Members ], SteamId[ Client ] ) )
		{
			return GuildIndex;
		}
	}
	
	return -1;
}

GetGuildStatus( const Client, const Guild )
{
	if( !is_user_connected( Client ) 
	|| Guild == -1 )
	{
		return _Guild_Status_None;
	}
	
	new GuildData[ GuildDataStruct ];
	ArrayGetArray( Guilds, Guild, GuildData );
	
	new Status;
	TrieGetCell( GuildData[ _Guild_Members ], SteamId[ Client ], Status );
	
	return Status;
}