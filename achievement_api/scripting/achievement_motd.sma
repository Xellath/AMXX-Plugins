#include < amxmodx >
#include < achievement_api >

const MaxClients = 32;
const MaxSteamIdChars = 35;

public plugin_init( )
{
	register_plugin( "Achievement API: MOTD Info", "0.0.1", "Xellath" );

	register_clcmd( "say /achievements", "ClientCommand_AchievementMenu" );
}

public ClientCommand_AchievementMenu( Client ) 
{ 
	if( is_user_connected( Client ) ) 
	{ 
		ShowAchievementMenu( Client ); 
	} 

	return PLUGIN_HANDLED; 
} 

ShowAchievementMenu( const Client ) 
{ 
	new Title[ 256 ]; 
	formatex( Title, charsmax( Title ),  
		"\r[ \yAchievement API \r]^n\wAchievements Menu^n^nAchievements Earned: \y%i of %i\w^n^n",  
		GetClientAchievementsCompleted( Client ),  
		GetMaxAchievements( )
		); 

	new Menu = menu_create( Title, "AchievementMenuHandler" ); 

	menu_additem( Menu, "List Achievements (MOTD)^n", "*" ); 

	menu_display( Client, Menu ); 
}

public AchievementMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );

		return;
	}
	
	new Info[ 2 ], Access, Callback;
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	if( Info[ 0 ] == '*' )
	{
		ListAchievements( Client );
	}
}

ListAchievements( const Client ) 
{ 
	if( !is_user_connected( Client ) ) 
	{ 
		return; 
	} 
	
	new Motd[ 1536 ], Char;
	Char = formatex( Motd, 1535 - Char, "<style>" ); 
	Char += formatex( Motd[ Char ], 1535 - Char, "body{margin:0;padding:0;font-family:Tahoma,Helvetica,Arial,sans-serif;}table,tr,td{align:center;color:#222;background:#fff;margin:1;padding:1;border:solid #eee 1px;}" ); 
	
	Char += formatex( Motd[ Char ], 1535 - Char, "</style><body>" ); 
	Char += formatex( Motd[ Char ], 1535 - Char, "<table width=^"600^">" );
	Char += formatex( Motd[ Char ], 1535 - Char, "<tr><td><b>Achievement Name</b></td><td><b>Description</b></td><td><b>Earned</b></td></tr>" );
	
	new AchievementName[ MaxClients ], AchievementDesc[ 256 ], AchievementSaveName[ MaxClients ], ObjectiveData, SteamId[ MaxSteamIdChars ];
	for( new AchievementIndex = 0; AchievementIndex < GetMaxAchievements( ); AchievementIndex++ )
	{
		get_user_authid( Client, SteamId, charsmax( SteamId ) );
		
		GetAchievementName( AchievementIndex, AchievementName );
		GetAchievementDesc( AchievementIndex, AchievementDesc );
		
		GetAchievementSaveKey( AchievementIndex, AchievementSaveName );
		
		ObjectiveData = GetAchievementData( SteamId, AchievementSaveName );
		
		Char += formatex( Motd[ Char ], 1535 - Char, "<tr><td>%s</td><td>%s</td><td>%s</td></tr>",
			AchievementName,
			AchievementDesc,
			( ( ObjectiveData >= GetAchievementMaxValue( AchievementIndex ) ) ? "Yes" : "No" )
			);
	}
	
	Char += formatex( Motd[ Char ], 1535 - Char, "</table></body>" ); 
	
	show_motd( Client, Motd, "Achievements" ); 
}