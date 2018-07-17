#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < engine >
#include < hamsandwich >
#include < fun >
#include < xs >
#include < colorchat >
#include < dbm_const >
#include < sqlvault_ex >

#define AddPartyMember(%1,%2)      ( PartyMembers[ %1 ] |= ( 1 << ( %2 & 31 ) ) )
#define RemovePartyMember(%1,%2)    ( PartyMembers[ %1 ] &= ~( 1 << ( %2 & 31 ) ) )
#define IsPartyMember(%1,%2)    ( PartyMembers[ %1 ] & ( 1 << ( %2 & 31 ) ) )

const TaskIdGiveHealth = 9186;

const TaskIdRemoveTutor = 7563;

const m_pPlayer = 41;
const XO_WEAPONS = 4;

new const ItemClassName[ ] = "diablo_item";
new const ItemModel[ ] = "models/itembag.mdl";
new const ItemModelT[ ] = "models/itembagT.mdl";

enum _:CommandStruct
{
	_Command[ MaxSlots * 2 ],
	_Function[ MaxSlots * 2 ],
	_Desc[ MaxSlots * 2 ]
};

new const CommandList[ ][ CommandStruct ] =
{
	{ "COMMAND_MENU", "ClientCommand_MainMenu", "COMMANDLIST_MENU" },
	{ "COMMAND_CLASS", "ClientCommand_SelectClass", "COMMANDLIST_CLASS" },
	{ "COMMAND_CLASSDESC", "ClientCommand_ClassDesc", "COMMANDLIST_CLASSDESC" },
	{ "COMMAND_ITEMDESC", "ClientCommand_ItemDesc", "COMMANDLIST_ITEAMDESC" },
	{ "COMMAND_DROPITEM", "ClientCommand_DropItem", "COMMANDLIST_DROPITEM" },
	{ "COMMAND_MANA", "ClientCommand_ManaShop", "COMMANDLIST_MANA" },
	{ "COMMAND_STAT", "ClientCommand_Stats", "COMMANDLIST_STAT" },
	{ "COMMAND_RESET", "ClientCommand_ResetStats", "COMMANDLIST_RESET" },
	{ "COMMAND_PARTY", "ClientCommand_PartySystem", "COMMANDLIST_PARTY" },
	{ "COMMAND_PLAYERS", "ClientCommand_PlayerLookup", "COMMANDLIST_PLAYERS" },
	{ "COMMAND_HELP", "ClientCommand_Help", "COMMANDLIST_HELP" },
	{ "COMMAND_CREDITS", "ClientCommand_ShowCredits", "COMMANDLIST_CREDITS" },
	{ "COMMAND_COMMANDS", "ClientCommand_Commands", "COMMANDLIST_COMMANDS" },
	{ "COMMAND_QUESTLOG", "ClientCommand_QuestLog", "COMMANDLIST_QUESTLOG" }
};

new SteamId[ MaxSlots + 1 ][ MaxSteamIdChars ];

new bool:FirstTime[ MaxSlots + 1 ];

new PlayerClass[ MaxSlots + 1 ];
new NextPlayerClass[ MaxSlots + 1 ];

new PlayerLevel[ MaxSlots + 1 ][ MaxClasses ];
new PlayerExperience[ MaxSlots + 1 ][ MaxClasses ];
new PlayerMana[ MaxSlots + 1 ][ MaxClasses ];

new AvailableStatPoints[ MaxSlots + 1 ];
new PlayerStats[ MaxSlots + 1 ][ StatStruct ];
new PlayerAdditionalStats[ MaxSlots + 1 ][ StatStruct ];

new PlayerItem[ MaxSlots + 1 ];
new PlayerItemDurability[ MaxSlots + 1 ];

new Float:ExperienceMultiplier[ MaxSlots + 1 ];

new ClassAccess:PlayerAccess[ MaxSlots + 1 ];

new QuestCompleted[ MaxSlots + 1 ][ MaxQuests ];
new QuestsCompleted[ MaxSlots + 1 ];

new Party[ MaxSlots + 1 ];
new CsTeams:PartyTeam[ MaxSlots * 2 ];
new PartyLeader[ MaxSlots * 2 ];
new PartyMembers[ MaxSlots * 2 ];

new InviteRequest[ MaxSlots + 1 ];

new CurrentParty;

new CurrentTeam[ MaxSlots + 1 ] = { 'U', ... };

new bool:Freezetime;

new bool:FirstBlood;

new bool:DisableAbility[ MaxSlots + 1 ][ MaxClasses ];

new bool:Casting[ MaxSlots + 1 ];
new Float:CastEnd[ MaxSlots + 1 ];

new HUDThinkEntity;
new DurabilityThinkEntity;
new RegThinkEntity[ MaxSlots + 1 ];

new Planter;
new Defuser;

new MaxPlayers;

new	MsgIdBarTime;

new MsgIdTutorText;
new MsgIdTutorClose;

enum _:Operators
{
	_Add1,
	_Add5,
	_Add10,
	_AddAll
};

new const OperatorName[ Operators ][ ] =
{
	"STAT_ADD_1",
	"STAT_ADD_5",
	"STAT_ADD_10",
	"STAT_ADD_ALL"
};

new Operator[ MaxSlots + 1 ];

enum _:DisplayType
{
	_MOTD,
	_Console
};

new const DisplayTypeName[ DisplayType ][ ] =
{
	"MOTD",
	"CONSOLE"
};

new Display[ MaxSlots + 1 ];

enum _:CvarType
{
	_Exp_Expotential,
	
	_Exp_Kill,
	_Exp_Defuse,
	_Exp_Plant,
	_Exp_Hostage,
	_Exp_Headshot,
	_Exp_First_Blood,
	_Exp_Win,
	_Exp_Quest,
	
	_Mana_Kill,
	_Mana_Headshot,
	_Mana_First_Blood,
	_Mana_Hostage,
	_Mana_Quest,
	
	_Item_Durability_Ratio,
	_Item_Durability_Interval,
	
	_Class_Stat_Per_Level
};

new Cvars[ CvarType ];

enum _:ForwardTypes
{
	_Forward_Class_Selected,
	_Forward_Class_Changed,
	_Forward_Class_Ability_Loaded,
	_Forward_Class_Ability_Use,
	
	_Forward_Item_Received,
	_Forward_Item_Dispatched,
	_Forward_Item_Use,
	
	_Forward_Client_Level_Up,
	
	_Forward_Client_Spawned,
	_Forward_Client_Killed,
	_Forward_Client_Hurt,
	
	_Forward_Delay_Connect,
};

new Forwards[ ForwardTypes ];
new ForwardReturns[ ForwardTypes ];

new Array:Classes;
new Array:Items;
new Array:Quests;
new Array:Addons;

new Array:Commands;

new Trie:IgnoreDeploy;

new SQLVault:VaultHandle;

native DBM_RegisterClass( const ClassName[ ], const ClassDescription[ ], const SaveKey[ ], const AbilityName[ ], const AbilityDescription[ ], const ClassAccess:Access, Float:AbilityDelay = 2.0, bool:AllowMoving = false, const MaxStats[ StatStruct ] = { 400, 400, 400, 400, 400 } );
native DBM_RegisterItem( const ItemName[ ], const ItemDescription[ ], const Cost, const Stat, const Category, const Durability = 255 );
native DBM_RegisterCommandToList( const Command[ ], const Function[ ], const Desc[ ] );

native DBM_SkillHudText( const Client, const Float:HoldTime, HudText[ ], any:... );

#if defined ShowGuildInPlayerLookup
	native DBM_GetClientGuild( const Client );
	native DBM_GetGuildName( const GuildIndex, Guild[ ] );
#endif

#if defined ShowPetFollowersInHUD
	native DBM_GetPetName( const Client, Pet[ ] );
#endif

#if defined EnableDamageBlockMonsterRound
	native DBM_IsMonsterRound( );
#endif

public plugin_init( )
{
	register_plugin( "Diablo Mod: Core", "0.0.1", "Xellath" );
	
	register_cvar( "dbm_author", "Xellath", FCVAR_SERVER | FCVAR_SPONLY );
	set_cvar_string( "dbm_author", "Xellath" ); 
	
	register_dictionary_colored( "dbm_core_lang.txt" );
	register_dictionary_colored( "dbm_class_lang.txt" );
	register_dictionary_colored( "dbm_item_lang.txt" );
	register_dictionary_colored( "dbm_quest_lang.txt" );
	register_dictionary_colored( "dbm_addon_lang.txt" );
	
	register_clcmd( "say", "ClientCommand_PartyChat" );
	register_clcmd( "say_team", "ClientCommand_PartyChat" );
	
	register_clcmd( "use_ability", "ClientCommand_UseAbility" );
	register_clcmd( "use_item", "ClientCommand_UseItem" );
	
	Cvars[ _Exp_Expotential ] = register_cvar( "dbm_exp_exponential", "75" );
	
	Cvars[ _Exp_Kill ] = register_cvar( "dbm_exp_kill", "45" );
	Cvars[ _Exp_Defuse ] = register_cvar( "dbm_exp_defuse", "25" );
	Cvars[ _Exp_Plant ] = register_cvar( "dbm_exp_plant", "25" );
	Cvars[ _Exp_Hostage ] = register_cvar( "dbm_exp_hostage", "50" );
	Cvars[ _Exp_Headshot ] = register_cvar( "dbm_exp_headshot", "20" );
	Cvars[ _Exp_First_Blood ] = register_cvar( "dbm_exp_firstblood", "70" );
	Cvars[ _Exp_Win ] = register_cvar( "dbm_exp_winround", "50" );
	Cvars[ _Exp_Quest ] = register_cvar( "dbm_exp_quest", "500" );
	
	Cvars[ _Mana_Kill ] = register_cvar( "dbm_mana_kill", "1" );
	Cvars[ _Mana_Headshot ] = register_cvar( "dbm_mana_headshot", "1" );
	Cvars[ _Mana_Hostage ] = register_cvar( "dbm_mana_hostage", "1" );
	Cvars[ _Mana_First_Blood ] = register_cvar( "dbm_mana_firstblood", "1" );
	Cvars[ _Mana_Quest ] = register_cvar( "dbm_mana_quest", "3" );
	
	Cvars[ _Item_Durability_Ratio ] = register_cvar( "dbm_durability_ratio", "5" );
	Cvars[ _Item_Durability_Interval ] = register_cvar( "dbm_durability_interval", "40" );
	
	Cvars[ _Class_Stat_Per_Level ] = register_cvar( "dbm_stat_per_level", "2" );
	
	register_event( "HLTV", "Event_HLTV_NewRound", "a", "1=0", "2=0" );
	register_logevent( "LogEvent_RoundStart", 2, "1=Round_Start" );
	
	register_event( "TeamInfo", "Event_TeamInfo_Party", "a" ); 
	
	register_touch( ItemClassName, "player", "Forward_Engine_ItemTouch" );
	register_touch( ItemClassName, "worldspawn", "Forward_Engine_WorldTouch" );
	
	register_event( "DeathMsg", "Event_DeathMsg", "a" );
	register_event( "TextMsg", "Event_TextMsg_Hostages", "a", "2&#All_Hostages_R" );
	
	register_event( "SendAudio", "Event_SendAudio_BombDefuse", "a", "2&%!MRAD_BOMBDEF" );
	register_event( "BarTime", "Event_Bartime_Defusing", "be", "1=10", "1=5" );
	
	register_logevent( "LogEvent_BombPlanted", 3, "2=Planted_The_Bomb" );	
	register_event( "StatusIcon", "Event_StatusIcon_HasBomb", "be", "1=1", "1=2", "2=c4" );
	
	register_event( "SendAudio", "Event_SendAudio_TWin", "a", "2&%!MRAD_terwin" );
	register_event( "SendAudio", "Event_SendAudio_CTWin", "a", "2&%!MRAD_ctwin" );
	
	RegisterHam( Ham_Spawn, "player", "Forward_Ham_ClientSpawn_Post", 1 );
	RegisterHam( Ham_TakeDamage, "player", "Forward_Ham_TakeDamage_Pre" );
	
	RegisterHam( Ham_Item_Deploy, "weapon_knife", "Forward_Ham_ItemDeploy_Post", 1 );
	
	register_message( get_user_msgid( "Health" ), "Message_Health_ZeroHPFix" );
	
	MaxPlayers = get_maxplayers( );
	
	MsgIdBarTime = get_user_msgid( "BarTime" );
	
	MsgIdTutorText = get_user_msgid( "TutorText" );
	MsgIdTutorClose = get_user_msgid( "TutorClose" );
	
	HUDThinkEntity = CreateThinkEntity( "hud_think", HUDThinkInterval );
	DurabilityThinkEntity = CreateThinkEntity( "dur_think", get_pcvar_float( Cvars[ _Item_Durability_Interval ] ) );
	
	for( new ClientIndex = 1; ClientIndex <= MaxPlayers; ClientIndex++ )
	{
		RegThinkEntity[ ClientIndex ] = CreateThinkEntity( "reg_think", RegThinkInterval );
		
		entity_set_edict( RegThinkEntity[ ClientIndex ], EV_ENT_owner, ClientIndex );
	}
	
	register_think( "hud_think", "Forward_Engine_HUDThink" );
	register_think( "dur_think", "Forward_Engine_DurabilityThink" );
	register_think( "reg_think", "Forward_Engine_RegThink" );
	
	register_think( ItemClassName, "Forward_Engine_ItemThink" );
	
	Forwards[ _Forward_Class_Selected ] = CreateMultiForward( "Forward_DBM_ClassSelected", ET_IGNORE, FP_CELL, FP_CELL );
	Forwards[ _Forward_Class_Changed ] = CreateMultiForward( "Forward_DBM_ClassChanged", ET_IGNORE, FP_CELL, FP_CELL );
	Forwards[ _Forward_Class_Ability_Loaded ] = CreateMultiForward( "Forward_DBM_AbilityLoaded", ET_IGNORE, FP_CELL, FP_CELL );
	Forwards[ _Forward_Class_Ability_Use ] = CreateMultiForward( "Forward_DBM_AbilityUse", ET_IGNORE, FP_CELL, FP_CELL );
	
	Forwards[ _Forward_Item_Received ] = CreateMultiForward( "Forward_DBM_ItemReceived", ET_IGNORE, FP_CELL, FP_CELL );
	Forwards[ _Forward_Item_Dispatched ] = CreateMultiForward( "Forward_DBM_ItemDispatched", ET_IGNORE, FP_CELL, FP_CELL );
	Forwards[ _Forward_Item_Use ] = CreateMultiForward( "Forward_DBM_ItemUse", ET_IGNORE, FP_CELL, FP_CELL );
	
	Forwards[ _Forward_Client_Level_Up ] = CreateMultiForward( "Forward_DBM_ClientLevelUp", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL );
	
	Forwards[ _Forward_Client_Spawned ] = CreateMultiForward( "Forward_DBM_ClientSpawned", ET_IGNORE, FP_CELL, FP_CELL );
	Forwards[ _Forward_Client_Killed ] = CreateMultiForward( "Forward_DBM_ClientKilled", ET_IGNORE, FP_CELL, FP_CELL );
	Forwards[ _Forward_Client_Hurt ] = CreateMultiForward( "Forward_DBM_ClientHurt", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_FLOAT, FP_CELL );
	
	Forwards[ _Forward_Delay_Connect ] = CreateMultiForward( "Forward_DBM_DelayConnect", ET_IGNORE, FP_CELL );
	
	Classes = ArrayCreate( ClassDataStruct );
	Items = ArrayCreate( ItemDataStruct );
	Quests = ArrayCreate( QuestDataStruct );
	Addons = ArrayCreate( AddonDataStruct );
	
	Commands = ArrayCreate( CommandStruct );
	
	for( new CommandIndex = 0; CommandIndex < sizeof( CommandList ); CommandIndex++ )
	{
		DBM_RegisterCommand( CommandList[ CommandIndex ][ _Command ], CommandList[ CommandIndex ][ _Function ] );
		DBM_RegisterCommandToList( CommandList[ CommandIndex ][ _Command ], CommandList[ CommandIndex ][ _Function ], CommandList[ CommandIndex ][ _Desc ] );
	}
	
	IgnoreDeploy = TrieCreate( );
	
	VaultHandle = sqlv_open_default( "dbm_core", false );
	sqlv_init_ex( VaultHandle );
	
	DBM_RegisterClass( "NONE", "NONE", "NONE", "NONE", "NONE", _Bronze, 1.0, false, { 100, 200, 300, 400, 500 } );
	DBM_RegisterItem( "NONE", "NONE", 0, 0, _Common );
}

public plugin_precache( )
{
	precache_model( ItemModel );
	precache_model( ItemModelT );
	
	precache_generic( "gfx/career/icon_!.tga" );
	precache_generic( "gfx/career/icon_!-bigger.tga" );
	precache_generic( "gfx/career/icon_i.tga" );
	precache_generic( "gfx/career/icon_i-bigger.tga" );
	precache_generic( "gfx/career/icon_skulls.tga" );
	precache_generic( "gfx/career/round_corner_ne.tga" );
	precache_generic( "gfx/career/round_corner_nw.tga" );
	precache_generic( "gfx/career/round_corner_se.tga" );
	precache_generic( "gfx/career/round_corner_sw.tga" );
	
	precache_generic( "resource/TutorScheme.res" );
	precache_generic( "resource/UI/TutorTextWindow.res" );
	
	precache_sound( "events/tutor_msg.wav" );
}

public plugin_end( )
{
	sqlv_close( VaultHandle );
	
	new ClassData[ ClassDataStruct ];
	new CurrentMaxClasses = ArraySize( Classes );
	for( new ClassIndex = 0; ClassIndex < CurrentMaxClasses; ClassIndex++ )
	{
		ArrayGetArray( Classes, ClassIndex, ClassData );
		
		ArrayDestroy( ClassData[ _Class_Max_Stats ] );
	}

	ArrayDestroy( Classes );
	ArrayDestroy( Items );
	ArrayDestroy( Quests );
	ArrayDestroy( Addons );
}

public plugin_natives( )
{
	register_library( "dbm_api" );
	
	register_native( "DBM_RegisterClass", "_DBM_RegisterClass" );
	register_native( "DBM_RegisterItem", "_DBM_RegisterItem" );
	register_native( "DBM_RegisterQuest", "_DBM_RegisterQuest" );
	
	register_native( "DBM_RegisterMenuAddon", "_DBM_RegisterMenuAddon" );
	
	register_native( "DBM_GetTotalClasses", "_DBM_GetTotalClasses" );
	register_native( "DBM_GetTotalItems", "_DBM_GetTotalItems" );
	register_native( "DBM_GetTotalQuests", "_DBM_GetTotalQuests" );
	
	register_native( "DBM_GetIdFromClassName", "_DBM_GetIdFromClassName" );
	register_native( "DBM_GetIdFromItemName", "_DBM_GetIdFromItemName" );
	register_native( "DBM_GetIdFromQuestName", "_DBM_GetIdFromQuestName" );
	
	register_native( "DBM_GetClientClass", "_DBM_GetClientClass" );
	
	register_native( "DBM_GetClassName", "_DBM_GetClassName" );
	register_native( "DBM_GetClassDesc", "_DBM_GetClassDesc" );
	register_native( "DBM_GetClassAbilityName", "_DBM_GetClassAbilityName" );
	
	register_native( "DBM_GetClassLevel", "_DBM_GetClassLevel" );
	register_native( "DBM_GetClassExperience", "_DBM_GetClassExperience" );
	register_native( "DBM_GetClassMana", "_DBM_GetClassMana" );
	
	register_native( "DBM_SetClassLevel", "_DBM_SetClassLevel" );
	register_native( "DBM_SetClassExperience", "_DBM_SetClassExperience" );
	register_native( "DBM_SetClassMana", "_DBM_SetClassMana" );
	
	register_native( "DBM_CheckLevel", "_DBM_CheckLevel" );
	
	register_native( "DBM_SetClassAbility", "_DBM_SetClassAbility" );
	
	register_native( "DBM_GetClientItem", "_DBM_GetClientItem" );
	
	register_native( "DBM_GetItemName", "_DBM_GetItemName" );
	register_native( "DBM_GetItemDesc", "_DBM_GetItemDesc" );
	
	register_native( "DBM_GetItemCost", "_DBM_GetItemCost" );
	register_native( "DBM_GetItemStat", "_DBM_GetItemStat" );
	
	register_native( "DBM_GiveItem", "_DBM_GiveItem" );
	
	register_native( "DBM_GetQuestName", "_DBM_GetQuestName" );
	register_native( "DBM_GetQuestDesc", "_DBM_GetQuestDesc" );
	
	register_native( "DBM_GetQuestObjectiveVal", "_DBM_GetQuestObjectiveVal" );
	
	register_native( "DBM_GetQuestPlayerVal", "_DBM_GetQuestPlayerVal" );
	register_native( "DBM_SetQuestPlayerVal", "_DBM_SetQuestPlayerVal" );
	
	register_native( "DBM_GetQuestCompleted", "_DBM_GetQuestCompleted" );
	
	register_native( "DBM_GetQuestData", "_DBM_GetQuestData" );
	
	register_native( "DBM_GetQuestsCompleted", "_DBM_GetQuestsCompleted" );
	
	register_native( "DBM_SetQuestCompleted", "_DBM_SetQuestCompleted" );
	
	register_native( "DBM_SaveQuestData", "_DBM_SaveQuestData" );
	
	register_native( "DBM_GetStat", "_DBM_GetStat" );
	register_native( "DBM_GetAdditionalStat", "_DBM_GetAdditionalStat" );
	register_native( "DBM_GetTotalStats", "_DBM_GetTotalStats" );
	register_native( "DBM_StatBoost", "_DBM_StatBoost" );
	
	register_native( "DBM_SetClassIgnoreDeploy", "_DBM_SetClassIgnoreDeploy" );
	
	register_native( "DBM_GetClientInClassChange", "_DBM_GetClientInClassChange" );
	
	register_native( "DBM_SkillHudText", "_DBM_SkillHudText" );
	
	register_native( "DBM_GetFreezetime", "_DBM_GetFreezetime" );
	
	register_native( "DBM_AddExperienceMultiplier", "_DBM_AddExperienceMultiplier" );
	register_native( "DBM_SubExperienceMultiplier", "_DBM_SubExperienceMultiplier" );
	
	register_native( "DBM_RegisterCommandToList", "_DBM_RegisterCommandToList" );
	
	register_native( "DBM_GetClientParty", "_DBM_GetClientParty" );
	register_native( "DBM_IsClientInParty", "_DBM_IsClientInParty" );
}

public _DBM_RegisterClass( Plugin, Params )
{
	if( ArraySize( Classes ) >= MaxClasses )
	{
		server_print( "[ Diablo Mod Core ] Max amount of classes exceeded, please set max to a higher amount! Current Max: %i", MaxClasses );
		
		return -1;
	}

	new ClassData[ ClassDataStruct ];
	get_string( 1, ClassData[ _Class_Name ], charsmax( ClassData[ _Class_Name ] ) );
	get_string( 2, ClassData[ _Class_Description ], charsmax( ClassData[ _Class_Description ] ) );
	get_string( 3, ClassData[ _Class_Save_Key ], charsmax( ClassData[ _Class_Save_Key ] ) );
	get_string( 4, ClassData[ _Class_Ability_Name ], charsmax( ClassData[ _Class_Ability_Name ] ) );
	get_string( 5, ClassData[ _Class_Ability_Desc ], charsmax( ClassData[ _Class_Ability_Desc ] ) );
	
	ClassData[ _Class_Access ] = get_param( 6 );
	ClassData[ _Class_Ability_Delay ] = get_param( 7 );
	ClassData[ _Class_Ability_Allow_Moving ] = bool:get_param( 8 );
	
	ClassData[ _Class_Max_Stats ] = _:ArrayCreate( StatStruct );
	
	ArrayPushArray( Classes, ClassData );
	
	new StatData[ StatStruct ];
	get_array( 9, StatData, 5 );
	
	ArrayPushArray( ClassData[ _Class_Max_Stats ], StatData );
	
	return ( ArraySize( Classes ) - 1 );
}

public _DBM_RegisterItem( Plugin, Params )
{
	if( ArraySize( Items ) >= MaxItems )
	{
		server_print( "[ Diablo Mod Core ] Max amount of items exceeded, please set max to a higher amount! Current Max: %i", MaxItems );
		
		return -1;
	}

	new ItemData[ ItemDataStruct ];
	get_string( 1, ItemData[ _Item_Name ], charsmax( ItemData[ _Item_Name ] ) );
	get_string( 2, ItemData[ _Item_Description ], charsmax( ItemData[ _Item_Description ] ) );
	
	ItemData[ _Item_Cost ] = get_param( 3 );
	ItemData[ _Item_Stat ] = get_param( 4 );
	ItemData[ _Item_Category ] = get_param( 5 );
	ItemData[ _Item_Durability ] = get_param( 6 );
	
	ArrayPushArray( Items, ItemData );
	
	return ( ArraySize( Items ) - 1 );
}

public _DBM_RegisterQuest( Plugin, Params )
{
	if( ArraySize( Quests ) >= MaxQuests )
	{
		server_print( "[ Diablo Mod Core ] Max amount of quests exceeded, please set max to a higher amount! Current Max: %i", MaxQuests );
		
		return -1;
	}
	
	new QuestData[ QuestDataStruct ];
	get_string( 1, QuestData[ _Quest_Name ], charsmax( QuestData[ _Quest_Name ] ) );
	get_string( 2, QuestData[ _Quest_Description ], charsmax( QuestData[ _Quest_Description ] ) );
	get_string( 3, QuestData[ _Quest_Save_Key ], charsmax( QuestData[ _Quest_Save_Key ] ) );
	
	QuestData[ _Quest_Objective_Value ] = get_param( 4 );
	
	ArrayPushArray( Quests, QuestData );
	
	return ( ArraySize( Quests ) - 1 );
}

public _DBM_RegisterMenuAddon( Plugin, Params )
{
	new AddonData[ AddonDataStruct ];
	get_string( 1, AddonData[ _Addon_Name ], charsmax( AddonData[ _Addon_Name ] ) );
	get_string( 2, AddonData[ _Addon_Function ], charsmax( AddonData[ _Addon_Function ] ) );
	get_string( 3, AddonData[ _Addon_Plugin_Name ], charsmax( AddonData[ _Addon_Plugin_Name ] ) );
	
	ArrayPushArray( Addons, AddonData );
}

public _DBM_GetTotalClasses( Plugin, Params )
{
	return ArraySize( Classes ) - 1;
}

public _DBM_GetTotalItems( Plugin, Params )
{
	return ArraySize( Items ) - 1;
}

public _DBM_GetTotalQuests( Plugin, Params )
{
	return ArraySize( Quests );
}

public _DBM_GetIdFromClassName( Plugin, Params )
{
	new Name[ MaxSlots * 2 ];
	get_string( 1, Name, charsmax( Name ) );

	new ClassData[ ClassDataStruct ];
	new CurrentMaxClasses = ArraySize( Classes );
	for( new ClassIndex = 1; ClassIndex < CurrentMaxClasses; ClassIndex++ )
	{
		ArrayGetArray( Classes, ClassIndex, ClassData );
		
		if( equali( ClassData[ _Class_Name ], Name ) )
		{
			return ClassIndex;
		}
	}

	return -1;
}

public _DBM_GetIdFromItemName( Plugin, Params )
{
	new Name[ MaxSlots ];
	get_string( 1, Name, charsmax( Name ) );

	new ItemData[ ItemDataStruct ];
	new CurrentMaxItems = ArraySize( Items );
	for( new ItemIndex = 1; ItemIndex < CurrentMaxItems; ItemIndex++ )
	{
		ArrayGetArray( Items, ItemIndex, ItemData );
		
		if( equali( ItemData[ _Item_Name ], Name ) )
		{
			return ItemIndex;
		}
	}

	return -1;
}

public _DBM_GetIdFromQuestName( Plugin, Params )
{
	new Name[ MaxSlots ];
	get_string( 1, Name, charsmax( Name ) );

	new QuestData[ QuestDataStruct ];
	new CurrentMaxQuests = ArraySize( Quests );
	for( new QuestIndex = 0; QuestIndex < CurrentMaxQuests; QuestIndex++ )
	{
		ArrayGetArray( Quests, QuestIndex, QuestData );
		
		if( equali( QuestData[ _Quest_Name ], Name ) )
		{
			return QuestIndex;
		}
	}

	return -1;
}

public _DBM_GetClientClass( Plugin, Params )
{
	return PlayerClass[ get_param( 1 ) ];
}

public _DBM_GetClassName( Plugin, Params )
{
	new ClassPointer = get_param( 1 );
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, ClassPointer, ClassData );
	
	set_string( 2, ClassData[ _Class_Name ], charsmax( ClassData[ _Class_Name ] ) );
}

public _DBM_GetClassDesc( Plugin, Params )
{
	new ClassPointer = get_param( 1 );
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, ClassPointer, ClassData );
	
	set_string( 2, ClassData[ _Class_Description ], charsmax( ClassData[ _Class_Description ] ) );
}

public _DBM_GetClassAbilityName( Plugin, Params )
{
	new ClassPointer = get_param( 1 );
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, ClassPointer, ClassData );
	
	set_string( 2, ClassData[ _Class_Ability_Name ], charsmax( ClassData[ _Class_Ability_Name ] ) );
}

public _DBM_GetClassLevel( Plugin, Params )
{
	return PlayerLevel[ get_param( 1 ) ][ get_param( 2 ) ];
}

public _DBM_GetClassExperience( Plugin, Params )
{
	return PlayerExperience[ get_param( 1 ) ][ get_param( 2 ) ];
}

public _DBM_GetClassMana( Plugin, Params )
{
	return PlayerMana[ get_param( 1 ) ][ get_param( 2 ) ];
}

public _DBM_SetClassLevel( Plugin, Params )
{
	new Client = get_param( 1 );
	new Class = get_param( 2 );
	PlayerLevel[ Client ][ Class ] = get_param( 3 );
	
	new StartExp = get_pcvar_num( Cvars[ _Exp_Expotential ] );
	PlayerExperience[ Client ][ Class ] = ( StartExp * PlayerLevel[ Client ][ Class ] * ( PlayerLevel[ Client ][ Class ] - 1 ) );
	
	SaveData( Client, Class );
}

public _DBM_SetClassExperience( Plugin, Params )
{
	new Client = get_param( 1 );
	new Class = get_param( 2 );
	PlayerExperience[ Client ][ Class ] = ( PlayerExperience[ Client ][ Class ] <= get_param( 3 ) ? PlayerExperience[ Client ][ Class ] : get_param( 3 ) );
}

public _DBM_CheckLevel( Plugin, Params )
{
	CheckLevel( get_param( 1 ), get_param( 2 ) );
}

public _DBM_SetClassMana( Plugin, Params )
{
	new Client = get_param( 1 );
	new Class = get_param( 2 );
	PlayerMana[ Client ][ Class ] = get_param( 3 );
	
	SaveData( Client, Class );
}

public _DBM_SetClassAbility( Plugin, Params )
{
	DisableAbility[ get_param( 1 ) ][ get_param( 2 ) ] = bool:get_param( 3 );
}

public _DBM_GetClientItem( Plugin, Params )
{
	return PlayerItem[ get_param( 1 ) ];
}

public _DBM_GetItemName( Plugin, Params )
{
	new ItemPointer = get_param( 1 );
	new ItemData[ ItemDataStruct ];
	ArrayGetArray( Items, ItemPointer, ItemData );
	
	set_string( 2, ItemData[ _Item_Name ], charsmax( ItemData[ _Item_Name ] ) );
}

public _DBM_GetItemDesc( Plugin, Params )
{
	new ItemPointer = get_param( 1 );
	new ItemData[ ItemDataStruct ];
	ArrayGetArray( Items, ItemPointer, ItemData );
	
	set_string( 2, ItemData[ _Item_Description ], charsmax( ItemData[ _Item_Description ] ) );
}

public _DBM_GetItemCost( Plugin, Params )
{
	new ItemPointer = get_param( 1 );
	new ItemData[ ItemDataStruct ];
	ArrayGetArray( Items, ItemPointer, ItemData );
	
	return ItemData[ _Item_Cost ];
}

public _DBM_GetItemStat( Plugin, Params )
{
	new ItemPointer = get_param( 1 );
	new ItemData[ ItemDataStruct ];
	ArrayGetArray( Items, ItemPointer, ItemData );
	
	return ItemData[ _Item_Stat ];
}

public _DBM_GiveItem( Plugin, Params )
{
	new Client = get_param( 1 );
	new ItemPointer = get_param( 2 );
	if( PlayerItem[ Client ] )
	{
		ExecuteForward( Forwards[ _Forward_Item_Dispatched ], ForwardReturns[ _Forward_Item_Dispatched ], Client, ItemPointer );
	}
	
	PlayerItem[ Client ] = ItemPointer;
	
	new ItemData[ ItemDataStruct ];
	ArrayGetArray( Items, ItemPointer, ItemData );
	PlayerItemDurability[ Client ] = ItemData[ _Item_Durability ];
	
	ExecuteForward( Forwards[ _Forward_Item_Received ], ForwardReturns[ _Forward_Item_Received ], Client, ItemPointer );
}

public _DBM_GetQuestName( Plugin, Params )
{
	new QuestPointer = get_param( 1 );
	new QuestData[ QuestDataStruct ];
	ArrayGetArray( Quests, QuestPointer, QuestData );
	
	set_string( 2, QuestData[ _Quest_Name ], charsmax( QuestData[ _Quest_Name ] ) );
}

public _DBM_GetQuestDesc( Plugin, Params )
{
	new QuestPointer = get_param( 1 );
	new QuestData[ QuestDataStruct ];
	ArrayGetArray( Quests, QuestPointer, QuestData );
	
	set_string( 2, QuestData[ _Quest_Description ], charsmax( QuestData[ _Quest_Description ] ) );
}

public _DBM_GetQuestObjectiveVal( Plugin, Params )
{
	new QuestPointer = get_param( 1 );
	new QuestData[ QuestDataStruct ];
	ArrayGetArray( Quests, QuestPointer, QuestData );
	
	return QuestData[ _Quest_Objective_Value ];
}

public _DBM_GetQuestPlayerVal( Plugin, Params )
{
	new QuestPointer = get_param( 1 );
	new QuestData[ QuestDataStruct ];
	ArrayGetArray( Quests, QuestPointer, QuestData );
	
	return QuestData[ _Quest_Player_Value ][ get_param( 2 ) ];
}

public _DBM_SetQuestPlayerVal( Plugin, Params )
{
	new QuestPointer = get_param( 1 );
	new QuestData[ QuestDataStruct ];
	ArrayGetArray( Quests, QuestPointer, QuestData );
	
	QuestData[ _Quest_Player_Value ][ get_param( 2 ) ] = get_param( 3 );
	
	ArraySetArray( Quests, QuestPointer, QuestData );
}

public _DBM_GetQuestCompleted( Plugin, Params )
{
	return QuestCompleted[ get_param( 1 ) ][ get_param( 2 ) ];
}

public _DBM_GetQuestData( Plugin, Params )
{
	return LoadQuest( get_param( 1 ), get_param( 2 ) );
}

public _DBM_GetQuestsCompleted( Plugin, Params )
{
	return QuestsCompleted[ get_param( 1 ) ];
}

public _DBM_SetQuestCompleted( Plugin, Params )
{
	new Client = get_param( 1 );
	new QuestPointer = get_param( 2 );
	QuestCompleted[ Client ][ QuestPointer ] = 1;
	
	QuestsCompleted[ Client ]++;
	
	if( get_param( 3 ) )
	{
		new QuestData[ QuestDataStruct ];
		ArrayGetArray( Quests, QuestPointer, QuestData );
		
		new Text[ TextLength ];
		formatex( Text, charsmax( Text ),
			"%L^n %L^n^n%L",
			Client,
			"MOD_PREFIX",
			Client,
			"QUEST_COMPLETED_GJ",
			Client,
			QuestData[ _Quest_Name ],
			Client,
			"QUEST_GOOD_JOB"
			);
		
		UTIL_TutorMessage( Client, random_num( 1, 4 ), Text );
		
		PlayerExperience[ Client ][ PlayerClass[ Client ] ] += get_pcvar_num( Cvars[ _Exp_Quest ] );
		PlayerMana[ Client ][ PlayerClass[ Client ] ] += get_pcvar_num( Cvars[ _Mana_Quest ] );
		
		client_print_color( Client, DontChange, 
			"%L",
			Client,
			"QUEST_EXP_RECEIVED",
			get_pcvar_num( Cvars[ _Exp_Quest ] ),
			get_pcvar_num( Cvars[ _Mana_Quest ] ),
			Client,
			QuestData[ _Quest_Name ]
			);
		
		CheckLevel( Client, PlayerClass[ Client ] );
	}
}

public _DBM_SaveQuestData( Plugin, Params )
{
	SaveQuest( get_param( 1 ), get_param( 2 ), get_param( 3 ) );
}

public _DBM_GetStat( Plugin, Params )
{
	new Client = get_param( 1 );
	new Stat = get_param( 2 );
	
	return PlayerStats[ Client ][ Stat ];
}

public _DBM_GetAdditionalStat( Plugin, Params )
{
	new Client = get_param( 1 );
	new Stat = get_param( 2 );
	
	return PlayerAdditionalStats[ Client ][ Stat ];
}

public _DBM_GetTotalStats( Plugin, Params )
{
	new Client = get_param( 1 );
	new Stat = get_param( 2 );
	
	return PlayerStats[ Client ][ Stat ] + PlayerAdditionalStats[ Client ][ Stat ];
}

public _DBM_StatBoost( Plugin, Params )
{
	new Client = get_param( 1 );
	new Stat = get_param( 2 );
	new Value = get_param( 4 );
	
	switch( get_param( 3 ) )
	{
		case _Stat_Increase:
		{
			PlayerAdditionalStats[ Client ][ Stat ] += Value;
		}
		case _Stat_Decrease:
		{
			PlayerAdditionalStats[ Client ][ Stat ] -= Value;
		}
	}
	
	if( PlayerAdditionalStats[ Client ][ Stat ] < 0 )
	{
		PlayerAdditionalStats[ Client ][ Stat ] = 0;
	}
}

public _DBM_SetClassIgnoreDeploy( Plugin, Params )
{
	new ClassString[ MaxSlots ];
	get_string( 1, ClassString, charsmax( ClassString ) );
	
	TrieSetCell( IgnoreDeploy, ClassString, 1 );
}

public bool:_DBM_GetClientInClassChange( Plugin, Params )
{
	return NextPlayerClass[ get_param( 1 ) ] != -1 ? true : false;
}

public _DBM_SkillHudText( Plugin, Params )
{
	new Client = get_param( 1 );
	if( is_user_alive( Client ) )
	{
		new HudText[ 256 ];
		vdformat( HudText, charsmax( HudText ), 3, 4 );
		
		set_hudmessage( 255, 255, 0, SkillHUDConstXPos, SkillHUDConstYPos, 1, 0.1, get_param_f( 2 ), 0.1, 0.1, -1 );
		show_hudmessage( Client, HudText );
	}
}

public bool:_DBM_GetFreezetime( Plugin, Params )
{
	return Freezetime;
}

public _DBM_AddExperienceMultiplier( Plugin, Params )
{
	ExperienceMultiplier[ get_param( 1 ) ] += get_param_f( 2 );
	
	return 1;
}

public _DBM_SubExperienceMultiplier( Plugin, Params )
{
	ExperienceMultiplier[ get_param( 1 ) ] -= get_param_f( 2 );
	
	return 1;
}

public _DBM_RegisterCommandToList( Plugin, Params )
{
	new Command[ MaxSlots * 2 ];
	new Function[ MaxSlots * 2 ];
	get_string( 1, Command, charsmax( Command ) );
	get_string( 2, Function, charsmax( Function ) );
	
	new CommandData[ CommandStruct ];
	CommandData[ _Command ] = Command;
	CommandData[ _Function ] = Function;
	get_string( 3, CommandData[ _Desc ], charsmax( CommandData[ _Desc ] ) );
	
	ArrayPushArray( Commands, CommandData );
}

public _DBM_GetClientParty( Plugin, Params )
{
	return Party[ get_param( 1 ) ];
}

public bool:_DBM_IsClientInParty( Plugin, Params )
{
	return ( IsPartyMember( get_param( 1 ), get_param( 2 ) ) ? true : false );
}

public client_authorized( Client )
{
	DefaultVariables( Client );
	
	get_user_authid( Client, SteamId[ Client ], charsmax( SteamId[ ] ) );
	
	if( equal( SteamId[ Client ], "STEAM_ID_LAN" ) )
	{
		SteamId[ Client ][ 0 ] = 0;
		get_user_name( Client, SteamId[ Client ], charsmax( SteamId[ ] ) );
	}
	
	LoadData( Client );
	
	ExecuteForward( Forwards[ _Forward_Delay_Connect ], ForwardReturns[ _Forward_Delay_Connect ], Client );
}

public client_disconnect( Client )
{
	DefaultVariables( Client );
	
	SteamId[ Client ][ 0 ] = 0;
}

LoadData( const Client )
{
	new Return;
	new Data[ 128 ];
	
	Return = sqlv_get_num_ex( VaultHandle, SteamId[ Client ], "first_time" );
	if( !Return )
	{
		FirstTime[ Client ] = true;
		
		sqlv_set_num_ex( VaultHandle, SteamId[ Client ], "first_time", 1 );
	}
	
	new SplitData[ 12 ];
	new ClassData[ ClassDataStruct ];
	new CurrentMaxClasses = ArraySize( Classes );
	for( new ClassIndex = 1; ClassIndex < CurrentMaxClasses; ClassIndex++ )
	{
		ArrayGetArray( Classes, ClassIndex, ClassData );
		
		Return = sqlv_get_data_ex( VaultHandle, SteamId[ Client ], ClassData[ _Class_Save_Key ], Data, charsmax( Data ) );
		if( !Return )
		{
			continue;
		}
		
		strbreak( Data, SplitData, charsmax( SplitData ), Data, charsmax( Data ) );
		PlayerLevel[ Client ][ ClassIndex ] = str_to_num( SplitData );
		
		AvailableStatPoints[ Client ] = ( PlayerLevel[ Client ][ ClassIndex ] * get_pcvar_num( Cvars[ _Class_Stat_Per_Level ] ) );
		
		strbreak( Data, SplitData, charsmax( SplitData ), Data, charsmax( Data ) );
		PlayerExperience[ Client ][ ClassIndex ] = str_to_num( SplitData );
		
		strbreak( Data, SplitData, charsmax( SplitData ), Data, charsmax( Data ) );
		PlayerMana[ Client ][ ClassIndex ] = str_to_num( SplitData );
	}
}

SaveData( const Client, const Class )
{
	new Data[ 128 ];
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, Class, ClassData );

	formatex( Data, charsmax( Data ), 
		"%i %i %i",
		PlayerLevel[ Client ][ Class ],
		PlayerExperience[ Client ][ Class ],
		PlayerMana[ Client ][ Class ]
		);
	
	sqlv_set_data_ex( VaultHandle, SteamId[ Client ], ClassData[ _Class_Save_Key ], Data );
}

LoadQuest( const Client, const QuestIndex )
{
	new QuestData[ ClassDataStruct ];
	ArrayGetArray( Quests, QuestIndex, QuestData );
	
	new QuestObjective = sqlv_get_num_ex( VaultHandle, SteamId[ Client ], QuestData[ _Quest_Save_Key ] );
	
	return QuestObjective;
}

SaveQuest( const Client, const QuestIndex, const Data )
{
	new QuestData[ ClassDataStruct ];
	ArrayGetArray( Quests, QuestIndex, QuestData );
	
	sqlv_set_num_ex( VaultHandle, SteamId[ Client ], QuestData[ _Quest_Save_Key ], Data );
}

DefaultVariables( const Client )
{
	Operator[ Client ] = _Add1;
	
	Display[ Client ] = _MOTD;

	FirstTime[ Client ] = false;
	
	PlayerClass[ Client ] = 0;
	NextPlayerClass[ Client ] = -1;

	for( new ClassIndex = 0; ClassIndex < MaxClasses; ClassIndex++ )
	{
		PlayerLevel[ Client ][ ClassIndex ] = 1;
		PlayerExperience[ Client ][ ClassIndex ] = 0;
		
		DisableAbility[ Client ][ ClassIndex ] = false;
	}
	
	for( new StatIndex = _Stat_Intelligence; StatIndex < StatStruct; StatIndex++ )
	{
		PlayerStats[ Client ][ StatIndex ] = 0;
		
		PlayerAdditionalStats[ Client ][ StatIndex ] = 0;
	}
	
	PlayerItem[ Client ] = 0;
	
	new QuestIndex;
	for( QuestIndex = 0; QuestIndex < MaxQuests; QuestIndex++ )
	{
		QuestCompleted[ Client ][ QuestIndex ] = 0;
	}
	
	new QuestData[ QuestDataStruct ];
	new CurrentMaxQuests = ArraySize( Quests );
	for( QuestIndex = 0; QuestIndex < CurrentMaxQuests; QuestIndex++ )
	{
		ArrayGetArray( Quests, QuestIndex, QuestData );
	
		QuestData[ _Quest_Player_Value ][ Client ] = 0;
	}
	
	QuestsCompleted[ Client ] = 0;
	
	if( Party[ Client ] )
	{
		RemovePartyMember( Party[ Client ], Client );
	}
	
	Party[ Client ] = 0;
	
	for( new ClassAccess:AccessIndex = _Bronze; AccessIndex < ClassAccess; AccessIndex++ )
	{
		if( access( Client, AccessName[ AccessIndex ][ _Flag ] ) )
		{
			PlayerAccess[ Client ] = AccessIndex;
		}
	}
	
	if( PlayerAccess[ Client ] >= _Silver )
	{
		ExperienceMultiplier[ Client ] = 1.5;
	}
	else
	{
		ExperienceMultiplier[ Client ] = 1.0;
	}
}

public Event_HLTV_NewRound( )
{
	Freezetime = true;
}

public LogEvent_RoundStart( )
{
	Freezetime = false;
	
	FirstBlood = true;
	
	new Entity = -1;
	while( ( Entity = find_ent_by_class( Entity, ItemClassName ) ) )
	{
		remove_entity( Entity );
	}
}

public Event_TeamInfo_Party( ) 
{
	new Client = read_data( 1 ); 
	if( !Party[ Client ] )
	{
		return;
	}
	
	new Team[ 2 ]; 
	read_data( 2, Team, 1 );
	
	if( CurrentTeam[ Client ] != Team[ 0 ] )
	{
		CurrentTeam[ Client ] = Team[ 0 ];
		
		switch( Team[ 0 ] )
		{
			case 'T':
			{
				if( PartyLeader[ Party[ Client ] ] == Client 
				&& PartyTeam[ Party[ Client ] ] != CS_TEAM_T )
				{
					DisbandParty( Client );
				}
				else if( PartyTeam[ Party[ Client ] ] != CS_TEAM_T )
				{
					LeaveParty( Client );
				}
			}
			case 'C':
			{
				if( PartyLeader[ Party[ Client ] ] == Client 
				&& PartyTeam[ Party[ Client ] ] != CS_TEAM_CT )
				{
					DisbandParty( Client );
				}
				else if( PartyTeam[ Party[ Client ] ] != CS_TEAM_CT )
				{
					LeaveParty( Client );
				}
			}
		}
	}
}

GiveExperience( const Client, const Experience, const Type, const KillMessage[ ] = "" )
{
	if( !Party[ Client ] )
	{
		PlayerExperience[ Client ][ PlayerClass[ Client ] ] += Experience;
		
		switch( Type )
		{
			case _Exp_Kill:
			{
				client_print_color( Client, DontChange, KillMessage );
			}
			case _Exp_Defuse:
			{
				client_print_color( Client, DontChange, 
					"^4%L^3 %L", 
					Client,
					"MOD_PREFIX",
					Client,
					"PARTY_EXP_DEFUSE", 
					Experience
					);
			}
			case _Exp_Plant:
			{
				client_print_color( Planter, DontChange, 
					"^4%L^3 %L", 
					Client,
					"MOD_PREFIX",
					Client,
					"PARTY_EXP_PLANT",
					Experience
					);
			}
			case _Exp_Hostage:
			{
				client_print_color( Client, DontChange, 
					"^4%L^3 %L", 
					Client,
					"MOD_PREFIX",
					Client,
					"PARTY_EXP_HOSTAGE",
					Experience
					);
			}
		}
	}
	else
	{
		new Members;
		new MemberIds[ MaxPartyMembers + 1 ];
		for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
		{
			if( is_user_connected( MemberIndex )
			&& IsPartyMember( Party[ Client ], MemberIndex ) )
			{
				MemberIds[ Members++ ] = MemberIndex;
			}
		}
		
		new Exp = floatround( ( Experience * 1.15 ) / Members );
		new Player;
		for( new Index = 0; Index < Members; Index++ )
		{
			Player = MemberIds[ Index ];
			
			PlayerExperience[ Player ][ PlayerClass[ Client ] ] += Exp;
			
			if( Player == Client )
			{
				switch( Type )
				{
					case _Exp_Kill:
					{
						client_print_color( Client, DontChange, KillMessage );
					}
					case _Exp_Defuse:
					{
						client_print_color( Client, DontChange, 
							"^4%L^3 %L", 
							Client,
							"MOD_PREFIX",
							Client,
							"PARTY_EXP_DEFUSE", 
							Exp
							);
					}
					case _Exp_Plant:
					{
						client_print_color( Planter, DontChange, 
							"^4%L^3 %L", 
							Client,
							"MOD_PREFIX",
							Client,
							"PARTY_EXP_PLANT", 
							Exp
							);
					}
					case _Exp_Hostage:
					{
						client_print_color( Client, DontChange, 
							"^4%L^3 %L", 
							Client,
							"MOD_PREFIX",
							Client,
							"PARTY_EXP_HOSTAGE", 
							Exp
							);
					}
				}
			}
			else
			{
				client_print_color( Player, DontChange, 
					"^4%L^3 %L", 
					Player,
					"MOD_PREFIX",
					Player,
					"PARTY_MEMBER_GAIN",
					Exp
					);
			}
		}
	}
}

public Event_StatusIcon_HasBomb( Client )
{ 
	Planter = Client;
} 

public LogEvent_BombPlanted( )
{
	if( is_user_connected( Planter ) 
	&& PlayerClass[ Planter ] )
	{
		new Exp;
		Exp = floatround( get_pcvar_num( Cvars[ _Exp_Plant ] ) * ExperienceMultiplier[ Planter ] );
		
		GiveExperience( Planter, ( Exp * 2 ), _Exp_Plant );
		
		CheckLevel( Planter, PlayerClass[ Planter ] );
	}
	
	new Exp = get_pcvar_num( Cvars[ _Exp_Plant ] );
	for( new Client = 1; Client <= MaxPlayers; Client++ ) 
	{
		if( is_user_connected( Client ) 
		&& cs_get_user_team( Client ) == CS_TEAM_T 
		&& PlayerClass[ Client ]
		&& Client != Planter )
		{
			PlayerExperience[ Client ][ PlayerClass[ Client ] ] += Exp;
		
			client_print_color( Client, DontChange, 
				"^4%L^3 %L", 
				Client,
				"MOD_PREFIX",
				Client,
				"TEAM_PLANT",
				Exp
				);
				
			CheckLevel( Client, PlayerClass[ Client ] );
		}
	}
}

public Event_Bartime_Defusing( Client )
{ 
	Defuser = Client;
} 

public Event_SendAudio_BombDefuse( )
{
	if( is_user_connected( Defuser )
	&& PlayerClass[ Defuser ] )
	{
		new Exp;
		Exp = floatround( get_pcvar_num( Cvars[ _Exp_Defuse ] ) * ExperienceMultiplier[ Defuser ] );
		
		GiveExperience( Defuser, ( Exp * 2 ), _Exp_Defuse );
		
		CheckLevel( Defuser, PlayerClass[ Defuser ] );
	}
	
	new Exp = get_pcvar_num( Cvars[ _Exp_Defuse ] );
	for( new Client = 1; Client <= MaxPlayers; Client++ ) 
	{
		if( is_user_connected( Client ) 
		&& cs_get_user_team( Client ) == CS_TEAM_CT
		&& PlayerClass[ Client ]
		&& Client != Defuser )
		{
			PlayerExperience[ Client ][ PlayerClass[ Client ] ] += Exp;
		
			client_print_color( Client, DontChange, 
				"^4%L^3 %L", 
				Client,
				"MOD_PREFIX",
				Client,
				"TEAM_DEFUSE",
				Exp
				);
				
			CheckLevel( Client, PlayerClass[ Client ] );
		}
	}
}

public Event_SendAudio_TWin( )
{
	new Exp = get_pcvar_num( Cvars[ _Exp_Win ] );
	for( new Client = 1; Client <= MaxPlayers; Client++ ) 
	{
		if( is_user_connected( Client ) 
		&& cs_get_user_team( Client ) == CS_TEAM_T
		&& PlayerClass[ Client ] )
		{
			PlayerExperience[ Client ][ PlayerClass[ Client ] ] += Exp;
		
			client_print_color( Client, DontChange, 
				"^4%L^3 %L", 
				Client,
				"MOD_PREFIX",
				Client,
				"TEAM_WIN",
				Exp
				);
				
			CheckLevel( Client, PlayerClass[ Client ] );
		}
	}
}

public Event_SendAudio_CTWin()
{
	new Exp = get_pcvar_num( Cvars[ _Exp_Win ] );
	for( new Client = 1; Client <= MaxPlayers; Client++ ) 
	{
		if( is_user_connected( Client ) 
		&& cs_get_user_team( Client ) == CS_TEAM_CT
		&& PlayerClass[ Client ] )
		{
			PlayerExperience[ Client ][ PlayerClass[ Client ] ] += Exp;
		
			client_print_color( Client, DontChange, 
				"^4%L^3 %L", 
				Client,
				"MOD_PREFIX",
				Client,
				"TEAM_WIN",
				Exp
				);
				
			CheckLevel( Client, PlayerClass[ Client ] );
		}
	}
}

public Event_TextMsg_Hostages( Client )
{
	if( is_user_connected( Client )
	&& PlayerClass[ Client ] )
	{
		new Exp = floatround( get_pcvar_num( Cvars[ _Exp_Hostage ] ) * ExperienceMultiplier[ Client ] );
		GiveExperience( Client, Exp, _Exp_Hostage );
		
		PlayerMana[ Client ][ PlayerClass[ Client ] ] += get_pcvar_num( Cvars[ _Mana_Hostage ] );
		
		CheckLevel( Client, PlayerClass[ Client ] );
	}
}

public ClientCommand_UseAbility( Client )
{
	if( is_user_alive( Client ) )
	{	
		ExecuteForward( Forwards[ _Forward_Class_Ability_Use ], ForwardReturns[ _Forward_Class_Ability_Use ], Client, PlayerClass[ Client ] );
	}
	
	return PLUGIN_HANDLED;
}

public ClientCommand_UseItem( Client )
{
	if( is_user_alive( Client ) )
	{
		ExecuteForward( Forwards[ _Forward_Item_Use ], ForwardReturns[ _Forward_Item_Use ], Client, PlayerItem[ Client ] );
	}
	
	return PLUGIN_HANDLED;
}

public client_PreThink( Client )
{
	if( !is_user_alive( Client ) 
	|| DisableAbility[ Client ][ PlayerClass[ Client ] ] 
	|| !PlayerClass[ Client ] )
	{
		return;
	}
	
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, PlayerClass[ Client ], ClassData );
	
	if( ClassData[ _Class_Ability_Delay ] == 0.0 )
	{
		return;
	}
	
	new Button = entity_get_int( Client, EV_INT_button );
	new Weapon = get_user_weapon( Client );
	new Flags = get_entity_flags( Client );
	if( ( Weapon == CSW_KNIFE 
	&& Flags & FL_ONGROUND 
	&& !( Button & ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT ) ) 
	&& !ClassData[ _Class_Ability_Allow_Moving ] )
	|| ( Weapon == CSW_KNIFE
	&& ClassData[ _Class_Ability_Allow_Moving ] ) )
	{
		if( Button & IN_RELOAD )
		{
			UTIL_BarTime( Client );
			
			Casting[ Client ] = false;
		}
		
		if( Casting[ Client ] 
		&& get_gametime( ) > CastEnd[ Client ] )
		{
			UTIL_BarTime( Client );
			
			Casting[ Client ] = false;
			
			ExecuteForward( Forwards[ _Forward_Class_Ability_Loaded ], ForwardReturns[ _Forward_Class_Ability_Loaded ], Client, PlayerClass[ Client ] );
		}
		else if( !Casting[ Client ] )
		{
			new Float:AbilityDelay = ( ClassData[ _Class_Ability_Delay ] - ( ( PlayerStats[ Client ][ _Stat_Intelligence ] + PlayerAdditionalStats[ Client ][ _Stat_Intelligence ] ) / 160.0 ) );

			CastEnd[ Client ] = get_gametime( ) + AbilityDelay;
			
			Casting[ Client ] = true;
			
			UTIL_BarTime( Client, AbilityDelay );
		}
	}
	else 
	{	
		if( Casting[ Client ] )
		{
			UTIL_BarTime( Client );
		}
		
		Casting[ Client ] = false;		
	}
}

public Forward_Engine_ItemTouch( Entity, Player )
{
	if( is_valid_ent( Entity ) )
	{
		new Item = entity_get_int( Entity, EV_INT_iuser1 );
		new Durability = entity_get_int( Entity, EV_INT_iuser2 );
		
		new ItemData[ ItemDataStruct ];
		ArrayGetArray( Items, Item, ItemData );
		
		static Text[ TextLength ];
		formatex( Text, charsmax( Text ),
			"%L: %L^n%L: %i^n%L: %L", 
			Player,
			"ITEM_NAME",
			Player,
			ItemData[ _Item_Name ],
			Player,
			"ITEM_DURABILITY",
			Durability,
			Player,
			"ITEM_CATEGORY",
			Player,
			CategoryName[ ItemData[ _Item_Category ] ]
			);
		
		DBM_SkillHudText( Player, 0.1, Text );
		
		new Button = entity_get_int( Player, EV_INT_button );
		if( Button & IN_DUCK )
		{
			if( !PlayerItem[ Player ] )
			{
				PlayerItem[ Player ] = Item;
				PlayerItemDurability[ Player ] = Durability;
				
				ExecuteForward( Forwards[ _Forward_Item_Received ], ForwardReturns[ _Forward_Item_Received ], Player, PlayerItem[ Player ] );
				
				remove_entity( Entity );
			}
			else if( PlayerItem[ Player ] 
			&& Button & IN_USE )
			{
				ExecuteForward( Forwards[ _Forward_Item_Dispatched ], ForwardReturns[ _Forward_Item_Dispatched ], Player, PlayerItem[ Player ] );
				
				DispatchItem( Player, PlayerItem[ Player ], PlayerItemDurability[ Player ] );
				
				PlayerItem[ Player ] = Item;
				PlayerItemDurability[ Player ] = Durability;
				
				ExecuteForward( Forwards[ _Forward_Item_Received ], ForwardReturns[ _Forward_Item_Received ], Player, PlayerItem[ Player ] );
				
				remove_entity( Entity );
			}
		}
	}
}

public Forward_Engine_WorldTouch( Entity, World )
{
	if( entity_get_int( Entity, EV_INT_flags ) & ~FL_ONGROUND )
	{	
		return;
	}
	
	drop_to_floor( Entity );
	
	static Float:Origin[ 3 ];
	static Float:TraceTo[ 3 ];
	static Trace = 0;
	
	static Float:Fraction;
	static Float:Angles[ 3 ]; 
	static Float:TempAngles[ 3 ];
	
	entity_get_vector( Entity, EV_VEC_origin, Origin );
	entity_get_vector( Entity, EV_VEC_angles, Angles );
	
	xs_vec_sub( Origin, Float:{ 0.0, 0.0, 10.0 }, TraceTo );
	
	engfunc( EngFunc_TraceLine, Origin, TraceTo, IGNORE_MONSTERS, Entity, Trace );
	
	get_tr2( Trace, TR_flFraction, Fraction );
	if( Fraction == 1.0 )
	{
		return;
	}
	
	static Float:Original[ 3 ];
	angle_vector( Angles, ANGLEVECTOR_FORWARD, Original );
	
	static Float:Right[ 3 ];
	static Float:Up[ 3 ];
	static Float:Forward[ 3 ];
	
	get_tr2( Trace, TR_vecPlaneNormal, Up );
	
	if( Up[ 2 ] == 1.0 )
	{
		return;
	}
	
	xs_vec_cross( Original, Up, Right );
	xs_vec_cross( Up, Right, Forward );
	
	vector_to_angle( Forward, Angles );
	vector_to_angle( Right, TempAngles );
	
	Angles[ 2 ] = -1.0 * TempAngles[ 0 ];
	
	entity_set_vector( Entity, EV_VEC_angles, Angles );
}

public Event_DeathMsg( )
{
	new Attacker = read_data( 1 );
	new Victim = read_data( 2 );
	
	ExecuteForward( Forwards[ _Forward_Client_Killed ], ForwardReturns[ _Forward_Client_Killed ], Victim, Attacker );
	
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& Victim != Attacker
	&& is_user_connected( Victim ) 
	&& is_user_connected( Attacker )
	&& cs_get_user_team( Victim ) != cs_get_user_team( Attacker ) )
	{
		if( PlayerClass[ Attacker ] )
		{
			new RewardedExp = get_pcvar_num( Cvars[ _Exp_Kill ] );
			new RewardedMana = get_pcvar_num( Cvars[ _Mana_Kill ] );
			
			new Headshot = read_data( 3 );
			
			new HeadshotString[ 18 ];
			if( Headshot )
			{
				RewardedExp += get_pcvar_num( Cvars[ _Exp_Headshot ] );
				RewardedMana += get_pcvar_num( Cvars[ _Mana_Headshot ] );
				
				formatex( HeadshotString, charsmax( HeadshotString ), 
					" %L",
					Attacker,
					"DEATHMSG_HEADSHOTBONUS"
					);
			}
			
			new KillerName[ MaxSlots ];
			new VictimName[ MaxSlots ];
			get_user_name( Attacker, KillerName, charsmax( KillerName ) );
			get_user_name( Victim, VictimName, charsmax( VictimName ) );
			
			if( FirstBlood )
			{
				RewardedExp += get_pcvar_num( Cvars[ _Exp_First_Blood ] );
				RewardedMana += get_pcvar_num( Cvars[ _Mana_First_Blood ] );
				
				for( new Player = 1; Player <= MaxPlayers; Player++ )
				{
					if( is_user_connected( Player ) )
					{
						client_print_color( Player, DontChange, 
							"^4%L^3 %L",
							Player,
							"MOD_PREFIX",
							Player,
							"DEATHMSG_FIRSTBLOOD",
							KillerName, 
							VictimName
							);
					}
				}
					
				FirstBlood = false;
			}
			
			new Exp;
			Exp = floatround( RewardedExp * ExperienceMultiplier[ Attacker ] );
			
			new KillMessage[ 128 ];
			formatex( KillMessage, charsmax( KillMessage ), 
				"^4%L^3 %L", 
				Attacker,
				"MOD_PREFIX",
				Attacker,
				"DEATHMSG_KILL",
				Exp, 
				VictimName, 
				Headshot ? HeadshotString : "."
				);
			
			GiveExperience( Attacker, Exp, _Exp_Kill, KillMessage );
			
			PlayerMana[ Attacker ][ PlayerClass[ Attacker ] ] += RewardedMana;
			
			CheckLevel( Attacker, PlayerClass[ Attacker ] );
		}
	}
	
	new ItemData[ ItemDataStruct ];
	new bool:Unique = true;
	if( PlayerItem[ Victim ]
	&& is_user_connected( Victim ) )
	{
		ArrayGetArray( Items, PlayerItem[ Victim ], ItemData );
		
		if( ItemData[ _Item_Category ] != _Unique )
		{
			ExecuteForward( Forwards[ _Forward_Item_Dispatched ], ForwardReturns[ _Forward_Item_Dispatched ], Victim, PlayerItem[ Victim ] );
		
			DispatchItem( Victim, PlayerItem[ Victim ], PlayerItemDurability[ Victim ] );
			
			PlayerItem[ Victim ] = 0;
			PlayerItemDurability[ Victim ] = 0;
			
			Unique = false;
		}
		
		if( Unique )
		{
			ExecuteForward( Forwards[ _Forward_Item_Dispatched ], ForwardReturns[ _Forward_Item_Dispatched ], Victim, PlayerItem[ Victim ] );
			
			PlayerItem[ Victim ] = 0;
			PlayerItemDurability[ Victim ] = 0;
			
			RandomizeItemDrop( Victim );
		}
	}
	else
	{
		RandomizeItemDrop( Victim );
	}
}

RandomizeItemDrop( Client )
{
	new ItemData[ ItemDataStruct ];
	new CurrentMaxItems = ArraySize( Items );
	new IndexRandomizer[ MaxItems ];
	new Index = 0;
	
	if( random_num( 1, 100 ) <= 5 )
	{
		for( new ItemIndex = 1; ItemIndex < CurrentMaxItems; ItemIndex++ )
		{
			ArrayGetArray( Items, ItemIndex, ItemData );
			
			if( ItemData[ _Item_Category ] == _Rare )
			{
				IndexRandomizer[ Index ] = ItemIndex;
				
				Index++;
			}
		}
		
		new RandomItemIndex = random( Index );
		ArrayGetArray( Items, IndexRandomizer[ RandomItemIndex ], ItemData );
		
		DispatchItem( Client, IndexRandomizer[ RandomItemIndex ], ItemData[ _Item_Durability ] );
	}
	else
	{
		for( new ItemIndex = 1; ItemIndex < CurrentMaxItems; ItemIndex++ )
		{
			ArrayGetArray( Items, ItemIndex, ItemData );
			
			if( ItemData[ _Item_Category ] == _Common )
			{
				IndexRandomizer[ Index ] = ItemIndex;
				
				Index++;
			}
		}
		
		new RandomItemIndex = random( Index );
		ArrayGetArray( Items, IndexRandomizer[ RandomItemIndex ], ItemData );
		
		DispatchItem( Client, IndexRandomizer[ RandomItemIndex ], ItemData[ _Item_Durability ] );
	}
}

CheckLevel( const Client, const Class )
{
	if( !Class )
	{
		return;
	}
	
	new StartExp = get_pcvar_num( Cvars[ _Exp_Expotential ] );
	
	new ClientName[ MaxSlots ];
	
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, Class, ClassData );
	if( PlayerLevel[ Client ][ Class ] < MaxLevel )
	{
		while( PlayerExperience[ Client ][ Class ] >= ( StartExp * PlayerLevel[ Client ][ Class ] * ( PlayerLevel[ Client ][ Class ] == 1 ? PlayerLevel[ Client ][ Class ] : ( PlayerLevel[ Client ][ Class ] - 1 ) ) ) )
		{
			if( PlayerLevel[ Client ][ Class ] == MaxLevel )
			{
				break;
			}
			
			PlayerLevel[ Client ][ Class ]++;
			
			ExecuteForward( Forwards[ _Forward_Client_Level_Up ], ForwardReturns[ _Forward_Client_Level_Up ], Client, Class, PlayerLevel[ Client ][ Class ] );
			
			AvailableStatPoints[ Client ] += get_pcvar_num( Cvars[ _Class_Stat_Per_Level ] );
			
			if( PlayerExperience[ Client ][ Class ] < ( StartExp * ( PlayerLevel[ Client ][ Class ] + 1 ) * PlayerLevel[ Client ][ Class ] ) )
			{
				get_user_name( Client, ClientName, charsmax( ClientName ) );
				
				for( new Player = 1; Player <= MaxPlayers; Player++ )
				{
					if( is_user_connected( Player ) )
					{
						client_print_color( Player, DontChange, 
							"^4%L^3 %L",
							Player,
							"MOD_PREFIX",
							Player,
							"CLASS_LEVEL_UP",
							ClientName,
							PlayerLevel[ Client ][ Class ],
							Player,
							ClassData[ _Class_Name ]
							);
					}
				}
				
				Operator[ Client ] = _Add1;
				
				ShowStatDistributeMenu( Client );
				
				client_print_color( Client, DontChange, 
					"^4%L^3 %L",
					Client,
					"MOD_PREFIX",
					Client,
					"CLASS_STAT_AVAIL",
					AvailableStatPoints[ Client ]
					);
					
				SaveData( Client, PlayerClass[ Client ] );
			}
		}
	}
}
	
public Forward_Ham_ClientSpawn_Post( Client )
{
	if( is_user_alive( Client ) )
	{
		if( !PlayerClass[ Client ] )
		{
			ShowClassMenu( Client );
			
			client_print_color( Client, DontChange, 
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"CLASS_SELECT"
				);
		}
		else
		{
			if( NextPlayerClass[ Client ] != -1 )
			{
				SaveData( Client, PlayerClass[ Client ] );
			
				ExecuteForward( Forwards[ _Forward_Class_Changed ], ForwardReturns[ _Forward_Class_Changed ], Client, PlayerClass[ Client ] );
				
				new ClassData[ ClassDataStruct ];
				ArrayGetArray( Classes, NextPlayerClass[ Client ], ClassData );
				
				PlayerClass[ Client ] = NextPlayerClass[ Client ];
				NextPlayerClass[ Client ] = -1;
				
				client_print_color( Client, DontChange, 
					"^4%L^3 %L",
					Client,
					"MOD_PREFIX",
					Client,
					"CLASS_CHANGED",
					Client,
					ClassData[ _Class_Name ]
					);
				
				ResetStats( Client );
				
				ExecuteForward( Forwards[ _Forward_Class_Selected ], ForwardReturns[ _Forward_Class_Selected ], Client, PlayerClass[ Client ] );
			}
			else
			{
				if( AvailableStatPoints[ Client ] )
				{
					client_print_color( Client, DontChange, 
						"^4%L^3 %L",
						Client,
						"MOD_PREFIX",
						Client,
						"AVAILABLE_STATPOINTS2"
						);
				}
			}
		}
		
		set_user_gravity( Client );
		set_user_rendering( Client );
		set_user_godmode( Client );
		set_user_noclip( Client );
		set_user_footsteps( Client, 0 );
		set_user_maxspeed( Client, 250.0 );
		
		arrayset( DisableAbility[ Client ], false, MaxClasses );
		
		UTIL_BarTime( Client );
		
		ExecuteForward( Forwards[ _Forward_Client_Spawned ], ForwardReturns[ _Forward_Client_Spawned ], Client, PlayerClass[ Client ] );
		
		set_task( 1.0, "TaskGiveHealth", Client + TaskIdGiveHealth );
		
		if( FirstTime[ Client ] )
		{
			client_print_color( Client, DontChange, "^3%L", Client, "RESTART_CLIENT1" );
			client_print_color( Client, DontChange, "^3%L", Client, "RESTART_CLIENT2" );
			client_print_color( Client, DontChange, "^3%L", Client, "RESTART_CLIENT3" );
			client_print_color( Client, DontChange, "^3%L", Client, "RESTART_CLIENT4" );
			client_print_color( Client, DontChange, "^3%L", Client, "RESTART_CLIENT5" );
		}
	}
}

public TaskGiveHealth( TaskId )
{
	new Client = TaskId - TaskIdGiveHealth;
	
	new Float:MaxHealth = ( entity_get_float( Client, EV_FL_health ) + ( ( PlayerStats[ Client ][ _Stat_Stamina ] + PlayerAdditionalStats[ Client ][ _Stat_Stamina ] ) * 2 ) );
	entity_set_float( Client, EV_FL_health, MaxHealth );
	entity_set_float( Client, EV_FL_max_health, MaxHealth );
	
	new Text[ TextLength ];
	formatex( Text, charsmax( Text ),
		"%L^n%L Xellath^n^n%L^n%L",
		Client, 
		"MOD_PREFIX",
		Client,
		"SERVER_USING",
		Client,
		"QUEST_TUTOR",
		QuestsCompleted[ Client ],
		ArraySize( Quests ),
		Client,
		"QUEST_HELP"
		);
	
	UTIL_TutorMessage( Client, random_num( 1, 4 ), Text );
	
	if( PlayerItem[ Client ] )
	{
		ExecuteForward( Forwards[ _Forward_Item_Received ], ForwardReturns[ _Forward_Item_Received ], Client, PlayerItem[ Client ] );
	}
}

public Forward_Ham_TakeDamage_Pre( Victim, Inflictor, Attacker, Float:Damage, Damagebits )
{
	ExecuteForward( Forwards[ _Forward_Client_Hurt ], ForwardReturns[ _Forward_Client_Hurt ], Victim, Inflictor, Attacker, Damage, Damagebits );
	
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& Victim != Attacker
	&& is_user_connected( Victim ) 
	&& is_user_connected( Attacker )
	&& cs_get_user_team( Victim ) != cs_get_user_team( Attacker ) )
	{
		#if defined EnableDamageBlockMonsterRound
			if( DBM_IsMonsterRound( ) )
			{
				SetHamParamFloat( 4, 0.0 );
				
				return HAM_SUPERCEDE;
			}
		#endif
		
		if( PlayerClass[ Attacker ] )
		{
			new Float:ExtraDamage = ( ( ( PlayerStats[ Attacker ][ _Stat_Agility ] + PlayerAdditionalStats[ Attacker ][ _Stat_Agility ] ) ) * 0.1 );
			new Float:DamageReduction = ( ( PlayerStats[ Victim ][ _Stat_Dexterity ] + PlayerAdditionalStats[ Victim ][ _Stat_Dexterity ] ) * 0.2 );
			new Float:FinalDamage = ( Damage + ( ( PlayerStats[ Attacker ][ _Stat_Agility ] + PlayerAdditionalStats[ Attacker ][ _Stat_Agility ] ) ? ExtraDamage : 0.0 ) - ( ( PlayerStats[ Victim ][ _Stat_Dexterity ] + PlayerAdditionalStats[ Victim ][ _Stat_Dexterity ] ) ? DamageReduction : 0.0 ) );
			if( FinalDamage < 0.0 )
			{
				FinalDamage = 0.0;
			}
			
			SetHamParamFloat( 4, FinalDamage );
			
			PlayerExperience[ Attacker ][ PlayerClass[ Attacker ] ] += floatround( FinalDamage );
		}
	}
	
	return HAM_IGNORED;
}

public Forward_Ham_ItemDeploy_Post( Entity )
{
	new Client = get_pdata_cbase( Entity, m_pPlayer, XO_WEAPONS );
	
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, PlayerClass[ Client ], ClassData );
	
	new bool:Ignore = false;
	if( TrieKeyExists( IgnoreDeploy, ClassData[ _Class_Name ] ) )
	{
		Ignore = true;
	}
	
	if( !Ignore )
	{
		entity_set_string( Client, EV_SZ_viewmodel, "models/v_knife.mdl" ); 
		entity_set_string( Client, EV_SZ_weaponmodel, "models/p_knife.mdl" );
	}
}

public Message_Health_ZeroHPFix( MsgId, Dest, Client )
{
	if( !is_user_alive( Client ) )
	{
		return;
	}
	
	new Health = get_msg_arg_int( 1 );
	if( Health > 255 
	&& ( Health % 256 ) == 0 )
	{
		set_msg_arg_int( 1, ARG_BYTE, ++Health );
	}
}

public ClientCommand_MainMenu( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowMainMenu( Client );
	}
	
	return PLUGIN_HANDLED;
}

ShowMainMenu( const Client )
{
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, PlayerClass[ Client ], ClassData );

	new Title[ 256 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L^n^n%L:\y %L^n\w%L: \y%i^n\wEXP: \y%i^n\w^n",
		Client,
		"MENU_PREFIX",
		Client,
		"MENU_MAIN",
		Client,
		"CLASS",
		Client,
		ClassData[ _Class_Name ],
		Client,
		"LEVEL",
		PlayerLevel[ Client ][ PlayerClass[ Client ] ],
		PlayerExperience[ Client ][ PlayerClass[ Client ] ]
		);
	
	new Menu = menu_create( Title, "MainMenuHandler" );
	
	if( ArraySize( Items ) > 0 )
	{
		formatex( Title, charsmax( Title ), 
			"%L^n",
			Client,
			"MENU_MAIN_MSHOP"
			);
		
		menu_additem( Menu, Title, "1" );
	}
	
	if( ArraySize( Addons ) > 0 )
	{
		formatex( Title, charsmax( Title ), 
			"%L^n",
			Client,
			"MENU_MAIN_ADDONS"
			);
	}
		
	menu_additem( Menu, Title, "2" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"MENU_MAIN_QUEST"
		);
	
	menu_additem( Menu, Title, "3" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"MENU_MAIN_LOOKUP"
		);
		
	menu_additem( Menu, Title, "4" );
	
	formatex( Title, charsmax( Title ), 
		"%L",
		Client,
		"MENU_MAIN_SELECT"
		);
	
	menu_additem( Menu, Title, "5" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"MENU_MAIN_RESET"
		);
	
	menu_additem( Menu, Title, "6" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"MENU_MAIN_HELP"
		);
	
	menu_additem( Menu, Title, "7" );
	
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

public MainMenuHandler( Client, Menu, Item )
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
			ShowManaShop( Client );
		}
		case '2':
		{
			ShowAddonsMenu( Client );
		}
		case '3':
		{
			ShowQuestLog( Client );
		}
		case '4':
		{
			ShowPlayerLookupMenu( Client );
		}
		case '5':
		{
			ShowClassMenu( Client );
		}
		case '6':
		{
			ShowResetMenu( Client );
		}
		case '7':
		{
			ShowHelpMenu( Client );
		}
	}
}

public ClientCommand_PartySystem( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowPartyMenu( Client );
	}
	
	return PLUGIN_HANDLED;
}

ShowAddonsMenu( const Client )
{
	new Title[ 256 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"MENU_MAIN_ADDONS",
		Client,
		"MENU"
		);
	
	new Menu = menu_create( Title, "AddonsMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"PARTY_SYSTEM"
		);
	
	menu_additem( Menu, Title, "*" );
	
	new Info[ 3 ];
	new AddonData[ AddonDataStruct ];
	for( new AddonIndex = 0; AddonIndex < ArraySize( Addons ); AddonIndex++ )
	{
		ArrayGetArray( Addons, AddonIndex, AddonData );
		
		num_to_str( AddonIndex, Info, charsmax( Info ) );
		
		formatex( Title, charsmax( Title ),
			"%L^n",
			Client,
			AddonData[ _Addon_Name ]
			);
		
		menu_additem( Menu, Title, Info );
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
		"MENU_MAIN"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public AddonsMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
	
		ShowMainMenu( Client );
	
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	if( Info[ 0 ] == '*' )
	{
		ShowPartyMenu( Client );
	}
	else
	{
		new AddonData[ AddonDataStruct ];
		ArrayGetArray( Addons, str_to_num( Info ), AddonData );
		
		callfunc_begin( AddonData[ _Addon_Function ], AddonData[ _Addon_Plugin_Name ] );
		{
			callfunc_push_int( Client );
		}
		callfunc_end( );
	}
}

public ClientCommand_PartyChat( Client )
{
	if( is_user_connected( Client ) 
	&& Party[ Client ] )
	{
		new Message[ 192 ];
		read_args( Message, charsmax( Message ) );
		remove_quotes( Message );
		
		if( equali( Message, "/p ", 3 ) 
		|| equali( Message, "!p ", 3 ) 
		|| equali( Message, ".p ", 3 ) )
		{
			replace_all( Message, charsmax( Message ), "%s", " s" );
			
			new ClientName[ MaxSlots ];
			get_user_name( Client, ClientName, charsmax( ClientName ) );
			for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
			{
				if( is_user_connected( MemberIndex )
				&& IsPartyMember( Party[ Client ], MemberIndex ) )
				{
					format( Message, charsmax( Message ),
						"^1(^4%L^1)^3 %s ^1: %s", 
						MemberIndex, 
						"PARTY", 
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

ShowPartyMenu( const Client )
{
	new Title[ 256 ];
	new Len;
	
	if( !Party[ Client ] )
	{
		formatex( Title, charsmax( Title ), 
			"%L^n\w%L %L^n^n",
			Client,
			"MENU_PREFIX",
			Client,
			"PARTY_SYSTEM",
			Client,
			"MENU"
			);
	}
	else
	{
		Len = formatex( Title, charsmax( Title ) - Len,  
			"%L^n\w%L %L^n^n%L:\y^n",
			Client,
			"MENU_PREFIX",
			Client,
			"PARTY_SYSTEM",
			Client,
			"MENU",
			Client,
			"MENU_PARTY_MEMBERS"
			);
		
		new MemberName[ MaxSlots ];
		for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
		{
			if( is_user_connected( MemberIndex )
			&& IsPartyMember( Party[ Client ], MemberIndex ) )
			{
				get_user_name( MemberIndex, MemberName, charsmax( MemberName ) );
		
				Len += formatex( Title[ Len ], charsmax( Title ) - Len, "%s^n", MemberName );
			}
		}
	}
	
	new Menu = menu_create( Title, "PartySystemHandler" );
	
	if( !Party[ Client ] )
	{
		formatex( Title, charsmax( Title ), 
			"%L^n",
			Client,
			"MENU_PARTY_CREATE"
			);
	
		menu_additem( Menu, Title, "1" );
	}
	else
	{
		if( PartyLeader[ Party[ Client ] ] == Client )
		{
			formatex( Title, charsmax( Title ), 
				"%L^n",
				Client,
				"MENU_PARTY_INVITE"
				);
			
			menu_additem( Menu, Title, "1" );
			
			formatex( Title, charsmax( Title ), 
				"%L^n",
				Client,
				"MENU_PARTY_KICK"
				);
			
			menu_additem( Menu, Title, "2" );
			
			formatex( Title, charsmax( Title ), 
				"%L^n",
				Client,
				"MENU_PARTY_DISBAND"
				);
			
			menu_additem( Menu, Title, "3" );
		}
		else
		{
			formatex( Title, charsmax( Title ), 
				"%L^n",
				Client,
				"MENU_PARTY_LEAVE"
				);
		
			menu_additem( Menu, Title, "1" );
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

public PartySystemHandler( Client, Menu, Item )
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
	
	if( !Party[ Client ] 
	&& Info[ 0 ] == '1' )
	{
		Party[ Client ] = ++CurrentParty;
		PartyTeam[ Party[ Client ] ] = cs_get_user_team( Client );
		PartyLeader[ Party[ Client ] ] = Client;
		
		AddPartyMember( Party[ Client ], Client );
		
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"PARTY_CREATED"
			);
		
		ShowPartyMenu( Client );
	}
	else if( Party[ Client ] )
	{
		if( PartyLeader[ Party[ Client ] ] == Client )
		{
			switch( Info[ 0 ] )
			{
				case '1':
				{
					PartyInviteMenu( Client );
				}
				case '2':
				{
					PartyKickMenu( Client );
				}
				case '3':
				{
					DisbandParty( Client );
				}
			}
		}
		else
		{
			if( Info[ 0 ] == '1' )
			{
				LeaveParty( Client );
			}
		}
	}
}

PartyInviteMenu( const Client )
{
	new PartyMem;
	for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
	{
		if( is_user_connected( MemberIndex )
		&& IsPartyMember( Party[ Client ], MemberIndex ) )
		{
			PartyMem++;
		}
	}
	
	if( PartyMem == MaxPartyMembers )
	{
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"PARTY_CANNOT_INV",
			MaxPartyMembers
			);
			
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"PARTY_REDIRECT"
			);
		
		ShowPartyMenu( Client );
	}
	
	new Title[ 128 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"PARTY_INVITE",
		Client,
		"MENU"
		);
	
	new Menu = menu_create( Title, "PartyInviteMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L %L^n\y%L\w^n",
		Client,
		"PARTY_KICK",
		Client,
		"MENU",
		Client,
		"PARTY_PICK_INV"
		);
	
	menu_additem( Menu, Title, "*" );
	
	new PlayerName[ MaxSlots ];
	new Info[ 3 ];
	for( new PlayerIndex = 1; PlayerIndex <= MaxPlayers; PlayerIndex++ )
	{
		if( is_user_connected( PlayerIndex )
		&& cs_get_user_team( PlayerIndex ) == cs_get_user_team( Client )
		&& !Party[ PlayerIndex ]
		&& InviteRequest[ Client ] != PlayerIndex )
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
		"PARTY_SYSTEM",
		Client,
		"MENU"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public PartyInviteMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
	
		ShowPartyMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	if( Info[ 0 ] == '*' )
	{
		PartyKickMenu( Client );
		
		return;
	}
	
	new PartyMem;
	for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
	{
		if( is_user_connected( MemberIndex )
		&& IsPartyMember( Party[ Client ], MemberIndex ) )
		{
			PartyMem++;
		}
	}
	
	if( PartyMem == MaxPartyMembers )
	{
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"PARTY_CANNOT_INV",
			MaxPartyMembers
			);
	}
	else
	{
		new Player = str_to_num( Info );
		
		PartyInviteRequest( Player, Client );
		
		InviteRequest[ Client ] = Player;
	}
}

PartyInviteRequest( const Player, const Client )
{
	new Title[ 256 ];
	new ClientName[ MaxSlots ];
	get_user_name( Client, ClientName, charsmax( ClientName ) );
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L^n^n\y%s\w %L^n", 
		Player,
		"MENU_PREFIX",
		Player,
		"PARTY_REQUEST",
		ClientName,
		Player,
		"PARTY_REQ_INVITED"
		);
	
	InviteRequest[ Player ] = Client;
	
	new Menu = menu_create( Title, "PartyRequestMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L",
		Player,
		"PARTY_REQ_ACCEPT"
		);
	
	menu_additem( Menu, Title, "1" );
	
	formatex( Title, charsmax( Title ), 
		"%L",
		Player,
		"PARTY_REQ_DECLINE"
		);
	
	menu_additem( Menu, Title, "2" );
	
	menu_setprop( Menu, MPROP_EXIT, MEXIT_NEVER );
	
	menu_display( Player, Menu, 0 );
}

public PartyRequestMenuHandler( Client, Menu, Item )
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
			if( !Party[ Client ] )
			{
				Party[ Client ] = Party[ InviteRequest[ Client ] ];
				
				AddPartyMember( Party[ Client ], Client );
				
				for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
				{
					if( is_user_connected( MemberIndex )
					&& IsPartyMember( Party[ Client ], MemberIndex ) )
					{
						client_print_color( MemberIndex, DontChange, 
							"^4%L^3 %L", 
							MemberIndex,
							"MOD_PREFIX",
							MemberIndex,
							"PARTY_JOINED",
							ClientName 
							);
					}
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
				"PARTY_DECLINED",
				ClientName
				);
		}
	}
	
	InviteRequest[ InviteRequest[ Client ] ] = 0;
	InviteRequest[ Client ] = 0;
}

PartyKickMenu( const Client )
{
	new Title[ 128 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"PARTY_KICK",
		Client,
		"MENU"
		);
	
	new Menu = menu_create( Title, "PartyKickMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L %L^n\y%L\w^n",
		Client,
		"PARTY_INVITE",
		Client,
		"MENU",
		Client,
		"PARTY_PICK_KICK"
		);
		
	menu_additem( Menu, Title, "*" );
	
	new Info[ 3 ];
	new MemberName[ MaxSlots ];
	for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
	{
		if( is_user_connected( MemberIndex )
		&& IsPartyMember( Party[ Client ], MemberIndex )
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
		"PARTY_SYSTEM",
		Client,
		"MENU"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public PartyKickMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
	
		ShowPartyMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	if( Info[ 0 ] == '*' )
	{
		PartyInviteMenu( Client );
		
		return;
	}
	
	LeaveParty( str_to_num( Info ) );
}

DisbandParty( const Client )
{
	for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
	{
		if( is_user_connected( MemberIndex )
		&& IsPartyMember( Party[ Client ], MemberIndex ) )
		{
			RemovePartyMember( Party[ Client ], MemberIndex );
			
			Party[ MemberIndex ] = 0;
			
			client_print_color( MemberIndex, DontChange, 
				"^4%L^3 %L",
				MemberIndex,
				"MOD_PREFIX",
				MemberIndex,
				"PARTY_DISBANDED"
				);
		}
	}
	
	RemovePartyMember( Party[ Client ], Client );
	
	PartyLeader[ Party[ Client ] ] = 0;
	
	Party[ Client ] = 0;
	
	client_print_color( Client, DontChange, 
		"^4%L^3 %L",
		Client,
		"MOD_PREFIX",
		Client,
		"PARTY_DISBANDED2"
		);
}

LeaveParty( const Client )
{
	new MemberName[ MaxSlots ];
	get_user_name( Client, MemberName, charsmax( MemberName ) );
	for( new MemberIndex = 1; MemberIndex <= MaxPlayers; MemberIndex++ )
	{
		if( is_user_connected( MemberIndex )
		&& IsPartyMember( Party[ Client ], MemberIndex ) )
		{
			client_print_color( MemberIndex, DontChange, 
				"^4%L^3 %L", 
				MemberIndex,
				"MOD_PREFIX",
				MemberIndex,
				"PARTY_PLAYER_LEFT",
				MemberName
				);
		}
	}
	
	RemovePartyMember( Party[ Client ], Client );
	
	Party[ Client ] = 0;
}

public ClientCommand_QuestLog( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowQuestLog( Client );
	}
	
	return PLUGIN_HANDLED;
}

ShowQuestLog( const Client )
{
	new Title[ 256 ];
	new CurrentMaxQuests = ArraySize( Quests );
	
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L^n^n%L: \y%i/%i\w^n",
		Client,
		"MENU_PREFIX",
		Client,
		"MENU_MAIN_QUEST",
		Client,
		"QUESTS_COMPLETED",
		QuestsCompleted[ Client ],
		CurrentMaxQuests
		);
	
	new Menu = menu_create( Title, "QuestLogMenuHandler" );
	
	new Info[ 3 ];
	new QuestData[ QuestDataStruct ];
	for( new QuestIndex = 0; QuestIndex < CurrentMaxQuests; QuestIndex++ )
	{
		ArrayGetArray( Quests, QuestIndex, QuestData );
	
		num_to_str( QuestIndex, Info, charsmax( Info ) );
		
		formatex( Title, charsmax( Title ), 
			"%L: \y%L",
			Client,
			QuestData[ _Quest_Name ],
			Client,
			( QuestCompleted[ Client ][ QuestIndex ] ? "QUEST_COMPLETED" : "QUEST_INPROGRESS" )
			);
		
		menu_additem( Menu, Title, Info );
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
		"MENU_MAIN"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public QuestLogMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
		
		ShowMainMenu( Client );
	
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	new Quest = str_to_num( Info );
	
	new QuestData[ QuestDataStruct ];
	ArrayGetArray( Quests, Quest, QuestData );
	
	new Title[ 512 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L^n^n%L: \y%L^n\w%L: \y%L^n\r%L^n\y%L\w^n%L: \y%i/%i\w^n",
		Client,
		"MENU_PREFIX",
		Client,
		"MENU_MAIN_QUEST",
		Client,
		"QUEST",
		Client,
		QuestData[ _Quest_Name ],
		Client,
		"QUEST_STATUS",
		Client,
		( QuestCompleted[ Client ][ Quest ] ? "QUEST_COMPLETED" : "QUEST_INPROGRESS" ),
		Client,
		"DESCRIPTION",
		Client,
		QuestData[ _Quest_Description ],
		Client,
		"PROGRESS",
		QuestData[ _Quest_Player_Value ][ Client ],
		QuestData[ _Quest_Objective_Value ]
		);
	
	new InfoMenu = menu_create( Title, "QuestLogInfoMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L",
		Client,
		"QUEST_BACK"
		);
	
	menu_additem( InfoMenu, Title, "1" );
	
	menu_setprop( InfoMenu, MPROP_EXIT, MEXIT_NEVER );
	
	menu_display( Client, InfoMenu, 0 );
}

public QuestLogInfoMenuHandler( Client, Menu, Item )
{
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	if( Info[ 0 ] == '1' )
	{
		ShowQuestLog( Client );
	}
}

public ClientCommand_Help( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowHelpMenu( Client );
	}
	
	return PLUGIN_HANDLED;
}

ShowHelpMenu( const Client )
{
	new Title[ 256 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"MENU_MAIN_HELP",
		Client,
		"MENU"
		);
	
	new Menu = menu_create( Title, "HelpMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L %L",
		Client,
		"CLASS",
		Client,
		"DESCRIPTION"
		);
	
	menu_additem( Menu, Title, "1" );
	
	formatex( Title, charsmax( Title ), 
		"%L %L^n",
		Client,
		"ITEM_NAME",
		Client,
		"DESCRIPTION"
		);
	
	menu_additem( Menu, Title, "2" );
	
	formatex( Title, charsmax( Title ), 
		"%L %L^n",
		Client,
		"GAMEPLAY",
		Client,
		"MENU_MAIN_HELP"
		);
	
	menu_additem( Menu, Title, "3" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"COMMANDS"
		);
	
	menu_additem( Menu, Title, "4" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"BINDS_LANG"
		);
	
	menu_additem( Menu, Title, "5" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"CREDITS"
		);
	
	menu_additem( Menu, Title, "6" );
	
	formatex( Title, charsmax( Title ), 
		"%L \y%L\w^n",
		Client,
		"SHOW_ALL_DESC",
		Client,
		DisplayTypeName[ Display[ Client ] ]
		);
	
	menu_additem( Menu, Title, "7" );
	
	formatex( Title, charsmax( Title ), 
		"%L",
		Client,
		"MENU_MAIN"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public HelpMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
		
		ShowMainMenu( Client );
	
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
			ShowClassDescMenu( Client );
		}
		case '2':
		{
			ShowItemDescMenu( Client );
		}
		case '3':
		{
			GameplayHelp( Client );
			
			ShowHelpMenu( Client );
		}
		case '4':
		{
			ShowCommands( Client );
			
			ShowHelpMenu( Client );
		}
		case '5':
		{
			ShowBinds( Client );
		}
		case '6':
		{
			ShowCreditsMenu( Client );
		}
		case '7':
		{
			Display[ Client ] = !Display[ Client ];
			
			ShowHelpMenu( Client );
		}
	}
}

ShowBinds( const Client )
{
	new Title[ 256 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L^n^n%L^n\ybind ^"key^" ^"use_ability^"^n\w%L^n\ybind ^"key^" ^"use_item^"^n^n\w",
		Client,
		"MENU_PREFIX",
		Client,
		"AVAILABLE_BINDS",
		Client,
		"USE_ABILITY",
		Client,
		"USE_ITEM"
		);
	
	new Menu = menu_create( Title, "BindMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n\yV = %L^nC = %L^n\w",
		Client,
		"BIND_AUTO",
		Client,
		"DEFAULT_BUTTONS_V",
		Client,
		"DEFAULT_BUTTONS_C"
		);
	
	menu_additem( Menu, Title, "1" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"CHOOSE_LANGUAGE"
		);
		
	menu_additem( Menu, Title, "2" );
	
	formatex( Title, charsmax( Title ), 
		"%L",
		Client,
		"HELP_BACK"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public BindMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
		
		ShowHelpMenu( Client );
		
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
			client_cmd( Client, "bind v use_ability" );
			client_cmd( Client, "bind c use_item" );
			
			engclient_cmd( Client, "bind v use_ability" );
			engclient_cmd( Client, "bind c use_item" );
			
			client_print_color( Client, DontChange,
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"BIND_AUTO_TEXT"
				);
				
			ShowBinds( Client );
		}
		case '2':
		{
			client_cmd( Client, "amx_langmenu" );
		}
	}
}

public ClientCommand_ManaShop( Client )
{
	if( is_user_alive( Client ) )
	{
		ShowManaShop( Client );
	}
	
	return PLUGIN_HANDLED;
}

ShowManaShop( const Client )
{
	if( !is_user_alive( Client ) )
	{
		return;
	}
	
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, PlayerClass[ Client ], ClassData );

	new Title[ 256 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L^n^n\w%L: \y%i \w(\y%L\w)^n",
		Client,
		"MENU_PREFIX",
		Client,
		"MENU_MAIN_MSHOP",
		Client,
		"MENU",
		Client,
		"MANA",
		PlayerMana[ Client ][ PlayerClass[ Client ] ],
		Client,
		ClassData[ _Class_Name ]
		);
	
	new Menu = menu_create( Title, "ManaMenuHandler" );
	
	new Info[ 3 ];
	new ItemData[ ItemDataStruct ];
	new CurrentMaxItems = ArraySize( Items );
	for( new ItemIndex = 1; ItemIndex < CurrentMaxItems; ItemIndex++ )
	{
		ArrayGetArray( Items, ItemIndex, ItemData );
	
		if( ItemData[ _Item_Category ] == _Unique )
		{
			num_to_str( ItemIndex, Info, charsmax( Info ) );
		
			formatex( Title, charsmax( Title ), 
				"%L \w(\y%L\w)\R\y%i\w",
				Client,
				ItemData[ _Item_Name ],
				Client,
				CategoryName[ ItemData[ _Item_Category ] ],
				ItemData[ _Item_Cost ]
				);
		
			menu_additem( Menu, Title, Info );
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
		"%L",
		Client,
		"MENU_MAIN"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public ManaMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
		
		ShowMainMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	new ItemIndex = str_to_num( Info );
	new ItemData[ ItemDataStruct ];
	ArrayGetArray( Items, ItemIndex, ItemData );
	
	if( !PlayerItem[ Client ] )
	{
		if( PlayerMana[ Client ][ PlayerClass[ Client ] ] >= ItemData[ _Item_Cost ] )
		{
			PlayerItem[ Client ] = ItemIndex;
			PlayerItemDurability[ Client ] = ItemData[ _Item_Durability ];

			client_print_color( Client, DontChange, 
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"ITEM_RECEIVED",
				Client,
				ItemData[ _Item_Name ],
				Client,
				CategoryName[ ItemData[ _Item_Category ] ],
				ItemData[ _Item_Durability ]
				);
				
			PlayerMana[ Client ][ PlayerClass[ Client ] ] -= ItemData[ _Item_Cost ];
			
			ExecuteForward( Forwards[ _Forward_Item_Received ], ForwardReturns[ _Forward_Item_Received ], Client, ItemIndex );
		}
		else
		{
			client_print_color( Client, DontChange, 
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"ITEM_NOT_ENOUGH_MANA"
				);
		}
	}
	else
	{
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"ITEM_ALREADY_HAVE"
			);
	}
}

public ClientCommand_SelectClass( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowClassMenu( Client );
	}
	
	return PLUGIN_HANDLED;
}

ShowClassMenu( const Client )
{
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, PlayerClass[ Client ], ClassData );

	new Title[ 256 ];
	if( !PlayerClass[ Client ] )
	{
		formatex( Title, charsmax( Title ), 
			"%L^n\w%L %L^n^n%L %L:\y %L^n\w%L: \y%L\w^n",
			Client,
			"MENU_PREFIX",
			Client,
			"MENU_SELECT_CLASS",
			Client,
			"MENU",
			Client,
			"CURRENT",
			Client,
			"CLASS",
			Client,
			ClassData[ _Class_Name ],
			Client,
			"ACCESS",
			Client,
			AccessName[ PlayerAccess[ Client ] ][ _Name ]
			);
	}
	else
	{
		formatex( Title, charsmax( Title ), 
			"%L^n\w%L %L^n^n%L %L:\y %L^n\w%L %L: \y%i^n\w%L: \y%L\w^n",
			Client,
			"MENU_PREFIX",
			Client,
			"MENU_SELECT_CLASS",
			Client,
			"MENU",
			Client,
			"CURRENT",
			Client,
			"CLASS",
			Client,
			ClassData[ _Class_Name ],
			Client,
			"CLASS",
			Client,
			"LEVEL",
			PlayerLevel[ Client ][ PlayerClass[ Client ] ],
			Client,
			"ACCESS",
			Client,
			AccessName[ PlayerAccess[ Client ] ][ _Name ]
			);
	}
	
	new Menu = menu_create( Title, "ClassMenuHandler" );
	
	new Info[ 3 ];
	new CurrentMaxClasses = ArraySize( Classes );
	for( new ClassIndex = 1; ClassIndex < CurrentMaxClasses; ClassIndex++ )
	{
		ArrayGetArray( Classes, ClassIndex, ClassData );
	
		num_to_str( ClassIndex, Info, charsmax( Info ) );
	
		formatex( Title, charsmax( Title ), 
			"%L: \r%L %i \w(\y%L\w)",
			Client,
			ClassData[ _Class_Name ],
			Client,
			"LEVEL",
			PlayerLevel[ Client ][ ClassIndex ],
			Client,
			AccessName[ ClassData[ _Class_Access ] ][ _Name ]
			);
	
		menu_additem( Menu, Title, Info );
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
		"MENU_MAIN"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public ClassMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
		
		ShowMainMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	new Class = str_to_num( Info );
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, Class, ClassData );
	
	if( PlayerAccess[ Client ] >= ClassData[ _Class_Access ] )
	{
		if( !PlayerClass[ Client ] )
		{
			ExecuteForward( Forwards[ _Forward_Class_Changed ], ForwardReturns[ _Forward_Class_Changed ], Client, PlayerClass[ Client ] );
			
			new ClassData[ ClassDataStruct ];
			ArrayGetArray( Classes, Class, ClassData );
			
			PlayerClass[ Client ] = Class;
			
			client_print_color( Client, DontChange, 
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"CLASS_CHANGED",
				Client,
				ClassData[ _Class_Name ]
				);
			
			ResetStats( Client );
			
			ExecuteForward( Forwards[ _Forward_Class_Selected ], ForwardReturns[ _Forward_Class_Selected ], Client, PlayerClass[ Client ] );
			
			ExecuteForward( Forwards[ _Forward_Client_Spawned ], ForwardReturns[ _Forward_Client_Spawned ], Client, PlayerClass[ Client ] );
		
			set_task( 1.0, "TaskGiveHealth", Client + TaskIdGiveHealth );
		}
		else
		{
			if( PlayerClass[ Client ] == Class )
			{			
				client_print_color( Client, DontChange, 
					"^4%L^3 %L",
					Client,
					"MOD_PREFIX",
					Client,
					"CLASS_ALREADY",
					Client,
					ClassData[ _Class_Name ]
					);
			}
			else
			{
				NextPlayerClass[ Client ] = Class;
				
				client_print_color( Client, DontChange, 
					"^4%L^3 %L",
					Client,
					"MOD_PREFIX",
					Client,
					"CLASS_CHANGE_NEXT",
					Client,
					ClassData[ _Class_Name ]
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
			"CLASS_ACCESS",
			Client,
			ClassData[ _Class_Name ],
			Client,
			AccessName[ ClassData[ _Class_Access ] ][ _Name ]
			);
	}
}

public ClientCommand_Stats( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowStatDistributeMenu( Client );
	}
	
	return PLUGIN_HANDLED;
}

ShowStatDistributeMenu( const Client )
{
	new Title[ 256 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L^n^n%L: \y%i\w^n",
		Client,
		"MENU_PREFIX",
		Client,
		"MENU_STAT_DISTRIBUTION",
		Client,
		"MENU",
		Client,
		"AVAILABLE_STATPOINTS",
		AvailableStatPoints[ Client ]
		);
	
	new Menu = menu_create( Title, "StatDistMenuHandler" );
	
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, PlayerClass[ Client ], ClassData );
	
	new StatData[ StatStruct ];
	ArrayGetArray( ClassData[ _Class_Max_Stats ], 0, StatData );
	
	new Info[ 3 ];
	for( new StatIndex = _Stat_Intelligence; StatIndex < StatStruct; StatIndex++ )
	{
		num_to_str( StatIndex, Info, charsmax( Info ) );
	
		if( StatIndex == _Stat_Regeneration )
		{
			formatex( Title, charsmax( Title ), 
				"%L (\y%L\w): \r%i \w(\y+%i\w) - \w(\y%L %i\w)^n",
				Client,
				StatName[ StatIndex ][ _Full ],
				Client,
				StatName[ StatIndex ][ _Short ],
				PlayerStats[ Client ][ StatIndex ],
				PlayerAdditionalStats[ Client ][ StatIndex ],
				Client,
				"MAX",
				StatData[ StatIndex ]
				);
		}
		else
		{
			formatex( Title, charsmax( Title ), 
				"\w%L (\y%L\w): \r%i \w(\y+%i\w) - \w(\y%L %i\w)",
				Client,
				StatName[ StatIndex ][ _Full ],
				Client,
				StatName[ StatIndex ][ _Short ],
				PlayerStats[ Client ][ StatIndex ],
				PlayerAdditionalStats[ Client ][ StatIndex ],
				Client,
				"MAX",
				StatData[ StatIndex ]
				);
		}
	
		menu_additem( Menu, Title, Info );
	}
	
	formatex( Title, charsmax( Title ), 
		"\w%L:\y %L\w^n",
		Client,
		"ACTION",
		Client,
		OperatorName[ Operator[ Client ] ]
		);
		
	menu_additem( Menu, Title, "6" );
	
	formatex( Title, charsmax( Title ), 
		"%L^n",
		Client,
		"STAT_INFO"
		);
	
	menu_additem( Menu, Title, "7" );
	
	formatex( Title, charsmax( Title ),
		"%L",
		Client,
		"EXIT"
		);

	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public StatDistMenuHandler( Client, Menu, Item )
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
	
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, PlayerClass[ Client ], ClassData );
	
	new StatData[ StatStruct ];
	ArrayGetArray( ClassData[ _Class_Max_Stats ], 0, StatData );
	
	new Stat = str_to_num( Info );
	if( Stat < 6 
	&& AvailableStatPoints[ Client ] )
	{
		switch( Operator[ Client ] )
		{
			case _Add1:
			{
				if( ( PlayerStats[ Client ][ Stat ] + 1 ) < StatData[ Stat ]
				&& AvailableStatPoints[ Client ] )
				{
					PlayerStats[ Client ][ Stat ]++;
					
					AvailableStatPoints[ Client ]--;
				}
			}
			case _Add5:
			{
				if( ( PlayerStats[ Client ][ Stat ] + 5 ) < StatData[ Stat ]
				&& AvailableStatPoints[ Client ] >= 5 )
				{
					PlayerStats[ Client ][ Stat ] += 5;
					
					AvailableStatPoints[ Client ] -= 5;
				}
			}
			case _Add10:
			{
				if( ( PlayerStats[ Client ][ Stat ] + 10 ) < StatData[ Stat ]
				&& AvailableStatPoints[ Client ] >= 10 )
				{
					PlayerStats[ Client ][ Stat ] += 10;
					
					AvailableStatPoints[ Client ] -= 10;
				}
			}
			case _AddAll:
			{
				if( ( PlayerStats[ Client ][ Stat ] + AvailableStatPoints[ Client ] ) < StatData[ Stat ] )
				{
					PlayerStats[ Client ][ Stat ] += AvailableStatPoints[ Client ];
					
					AvailableStatPoints[ Client ] = 0;
				}
			}
		}
		
		if( !AvailableStatPoints[ Client ] )
		{
			client_print_color( Client, DontChange, 
				"^4%L^3 %L %L: %i %L: %i %L: %i %L: %i %L: %i",
				Client,
				"MOD_PREFIX",
				Client,
				"STAT_POINTS_SPENT",
				Client,
				"STATNAME_INT",
				PlayerStats[ Client ][ _Stat_Intelligence ],
				Client,
				"STATNAME_STA",
				PlayerStats[ Client ][ _Stat_Stamina ],
				Client,
				"STATNAME_DEX",
				PlayerStats[ Client ][ _Stat_Dexterity ],
				Client,
				"STATNAME_AGI",
				PlayerStats[ Client ][ _Stat_Agility ],
				Client,
				"STATNAME_REG",
				PlayerStats[ Client ][ _Stat_Regeneration ]
				);
				
			if( Freezetime )
			{
				new Float:MaxHealth = ( entity_get_float( Client, EV_FL_health ) + ( ( PlayerStats[ Client ][ _Stat_Stamina ] + PlayerAdditionalStats[ Client ][ _Stat_Stamina ] ) * 2 ) );
				entity_set_float( Client, EV_FL_health, MaxHealth );
				entity_set_float( Client, EV_FL_max_health, MaxHealth );
			}
		}
	}
	else if( Stat < 6 
	&& !AvailableStatPoints[ Client ] )
	{
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"STAT_POINTS_NOREDIST"
			);
	}
	else if( Stat == 6 )
	{
		if( Operator[ Client ] < _AddAll )
		{
			Operator[ Client ]++;
		}
		else
		{
			Operator[ Client ] = _Add1;
		}
		
		ShowStatDistributeMenu( Client );
	}
	else if( Stat == 7 )
	{
		new Motd[ 1536 ];
		new Len;
		
		if( Display[ Client ] == _MOTD )
		{
			Len = formatex( Motd, 1535 - Len, "<body bgcolor=#000000><font color=#FFFFFF><pre>" );
			
			Len += formatex( Motd[ Len ], 1535 - Len, 
				"<u>%L</u>^n^n",
				Client,
				"STATS"
				);
			
			for( new StatIndex = _Stat_Intelligence; StatIndex < StatStruct; StatIndex++ )
			{
				Len += formatex( Motd[ Len ], 1535 - Len, "%L (%L): - %L (%L %i %L)^n", 
					Client,
					StatName[ StatIndex ][ _Full ], 
					Client,
					StatName[ StatIndex ][ _Short ],
					Client,
					StatDesc[ StatIndex ][ _Stat_Desc ],
					Client,
					"MAX",
					StatData[ StatIndex ],
					Client,
					"POINTS"
					);
			}
			
			Len += formatex( Motd[ Len ], 1535 - Len, "</body></font></pre>" );
			
			new Text[ 23 ];
			formatex( Text, charsmax( Text ),
				"%L %L",
				Client,
				"DIABLO_MOD",
				Client,
				"STAT_INFO"
				);
			
			show_motd( Client, Motd, Text );
		}
		else
		{
			client_print_color( Client, DontChange, 
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"STAT_INFO_PRINT"
				);
		
			console_print( Client, 
				"^n%L^n^n",
				Client,
				"STATS"
				);
			
			for( new StatIndex = _Stat_Intelligence; StatIndex < StatStruct; StatIndex++ )
			{
				console_print( Client, "%L (%L): - %L (%L %i %L)^n", 
					Client,
					StatName[ StatIndex ][ _Full ], 
					Client,
					StatName[ StatIndex ][ _Short ],
					Client,
					StatDesc[ StatIndex ][ _Stat_Desc ],
					Client,
					"MAX",
					StatData[ StatIndex ],
					Client,
					"POINTS"
					);
			}
		}
	}
	
	if( AvailableStatPoints[ Client ] )
	{
		ShowStatDistributeMenu( Client );
	}
}

public ClientCommand_ResetStats( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowResetMenu( Client );
	}
	
	return PLUGIN_HANDLED;
}

ShowResetMenu( const Client )
{
	new Title[ 256 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L^n^n\w%L^n",
		Client,
		"MENU_PREFIX",
		Client,
		"MENU_MAIN_RESET",
		Client,
		"MENU_CONFIRM_RESET"
		);
	
	new Menu = menu_create( Title, "ResetMenuHandler" );
	
	formatex( Title, charsmax( Title ), 
		"%L",
		Client,
		"YES"
		);
	
	menu_additem( Menu, Title, "1" );
	
	formatex( Title, charsmax( Title ), 
		"%L",
		Client,
		"NO"
		);
		
	menu_additem( Menu, Title, "2" );
	
	formatex( Title, charsmax( Title ),
		"%L",
		Client,
		"EXIT"
		);

	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public ResetMenuHandler( Client, Menu, Item )
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
			ResetStats( Client );
			
			client_print_color( Client, DontChange, 
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"STATS_RESET",
				AvailableStatPoints[ Client ]
				);
		}
		case '2':
		{
			client_print_color( Client, DontChange, 
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"STATS_UNCHANGED"
				);
		}
	}
}

ResetStats( const Client )
{
	for( new StatIndex = 0; StatIndex < StatStruct; StatIndex++ )
	{
		PlayerStats[ Client ][ StatIndex ] = 0;
	}
	
	AvailableStatPoints[ Client ] = ( PlayerLevel[ Client ][ PlayerClass[ Client ] ] * get_pcvar_num( Cvars[ _Class_Stat_Per_Level ] ) );
	
	ShowStatDistributeMenu( Client );
}

public ClientCommand_ClassDesc( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowClassDescMenu( Client );
	}
	
	return PLUGIN_HANDLED;
}

public ClientCommand_ItemDesc( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowItemDescMenu( Client );
	}
	
	return PLUGIN_HANDLED;
}

ShowClassDescMenu( const Client )
{
	new Title[ 256 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L %L^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"CLASS",
		Client,
		"DESCRIPTION",
		Client,
		"MENU"
		);
	
	new Menu = menu_create( Title, "ClassDescMenuHandler" );
	
	new Info[ 3 ];
	new CurrentMaxClasses = ArraySize( Classes );
	new ClassData[ ClassDataStruct ];
	
	for( new ClassIndex = 1; ClassIndex < CurrentMaxClasses; ClassIndex++ )
	{
		ArrayGetArray( Classes, ClassIndex, ClassData );
	
		num_to_str( ClassIndex, Info, charsmax( Info ) );
	
		formatex( Title, charsmax( Title ), 
			"%L \w(\y%L\w)",
			Client,
			ClassData[ _Class_Name ],
			Client,
			AccessName[ ClassData[ _Class_Access ] ][ _Name ]
			);
	
		menu_additem( Menu, Title, Info );
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
		"MENU_MAIN_HELP",
		Client,
		"MENU"
		);
		
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public ClassDescMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
		
		ShowHelpMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, str_to_num( Info ), ClassData );
	
	new Motd[ 1536 ];
	new Len;
	
	if( Display[ Client ] == _MOTD )
	{
		Len = formatex( Motd, 1535 - Len, "<body bgcolor=#000000><font color=#FFFFFF><pre>" );
		
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"<u>%L</u>^n^n", 
			Client,
			ClassData[ _Class_Name ] 
			);
		
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"%L: %L^n^n", 
			Client,
			"ACCESS",
			Client,
			AccessName[ ClassData[ _Class_Access ] ][ _Name ]
			);
		
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"%L",
			Client,
			ClassData[ _Class_Description ]
			);
		
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"^n^n%L: %L (%L: %0.1f)^n", 
			Client,
			"ABILITY",
			Client,
			ClassData[ _Class_Ability_Name ], 
			Client,
			"DELAY",
			ClassData[ _Class_Ability_Delay ] 
			);
		
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"%L",
			Client,
			ClassData[ _Class_Ability_Desc ]
			);
		
		Len += formatex( Motd[ Len ], 1535 - Len, "</body></font></pre>" );
		
		new Text[ MaxSlots * 2 ];
		formatex( Text, charsmax( Text ),
			"%L %L %L",
			Client,
			"DIABLO_MOD",
			Client,
			"CLASS",
			Client,
			"DESCRIPTION"
			);
		
		show_motd( Client, Motd, Text );
	}
	else
	{
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"CLASS_INFO",
			Client,
			ClassData[ _Class_Name ]
			);
	
		console_print( Client, 
			"^n%L^n^n", 
			Client,
			ClassData[ _Class_Name ] 
			);
		
		console_print( Client, 
			"%L: %L^n^n", 
			Client,
			"ACCESS",
			Client,
			AccessName[ ClassData[ _Class_Access ] ][ _Name ]
			);
			
		new Text[ 256 ];
		formatex( Text, charsmax( Text ),
			"%L",
			Client,
			ClassData[ _Class_Description ]
			);
			
		console_print( Client, Text );
		
		console_print( Client, 
			"^n^n%L: %L (%L: %0.1f)^n", 
			Client,
			"ABILITY",
			Client,
			ClassData[ _Class_Ability_Name ], 
			Client,
			"DELAY",
			ClassData[ _Class_Ability_Delay ] 
			);
		
		formatex( Text, charsmax( Text ),
			"%L",
			Client,
			ClassData[ _Class_Ability_Desc ]
			);
		
		console_print( Client, Text );
	}
	
	ShowClassDescMenu( Client );
}

ShowItemDescMenu( const Client )
{
	new Title[ 256 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L %L %L^n^n",
		Client,
		"MENU_PREFIX",
		Client,
		"ITEM_NAME",
		Client,
		"DESCRIPTION",
		Client,
		"MENU"
		);
	
	new Menu = menu_create( Title, "ItemDescMenuHandler" );
	
	new Info[ 3 ];
	new CurrentMaxItems = ArraySize( Items );
	new ItemData[ ClassDataStruct ];
	
	for( new ItemIndex = 1; ItemIndex < CurrentMaxItems; ItemIndex++ )
	{
		ArrayGetArray( Items, ItemIndex, ItemData );
	
		num_to_str( ItemIndex, Info, charsmax( Info ) );
	
		formatex( Title, charsmax( Title ), 
			"%L \w(\y%L\w)",
			Client,
			ItemData[ _Item_Name ],
			Client,
			CategoryName[ ItemData[ _Item_Category ] ]
			);
	
		menu_additem( Menu, Title, Info );
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
		"MENU_MAIN_HELP",
		Client,
		"MENU"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public ItemDescMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
		
		ShowHelpMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	new ItemData[ ClassDataStruct ];
	ArrayGetArray( Items, str_to_num( Info ), ItemData );
	
	new Motd[ 1536 ];
	new Len;
	
	if( Display[ Client ] == _MOTD )
	{
		Len = formatex( Motd, 1535 - Len, "<body bgcolor=#000000><font color=#FFFFFF><pre>" );
		
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"<u>%L</u>^n^n",
			Client,
			ItemData[ _Item_Name ] 
			);
		
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"%L: %L^n^n",
			Client,
			"CATEGORY",
			Client,
			CategoryName[ ItemData[ _Item_Category ] ] 
			);
			
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"%L",
			Client,
			ItemData[ _Item_Description ]
			);
	
		Len += formatex( Motd[ Len ], 1535 - Len, "</body></font></pre>" );
		
		new Text[ MaxSlots * 2 ];
		formatex( Text, charsmax( Text ),
			"%L %L %L",
			Client,
			"DIABLO_MOD",
			Client,
			"ITEM_NAME",
			Client,
			"DESCRIPTION"
			);
		
		show_motd( Client, Motd, Text );
	}
	else
	{
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"ITEM_INFO",
			Client,
			ItemData[ _Item_Name ]
			);
	
		console_print( Client, 
			"^n%L^n^n", 
			Client,
			ItemData[ _Item_Name ] 
			);
			
		console_print( Client,
			"%L: %L^n^n", 
			Client,
			"CATEGORY",
			Client,
			CategoryName[ ItemData[ _Item_Category ] ] 
			);
			
		new Text[ 256 ];
		formatex( Text, charsmax( Text ),
			"%L",
			Client,
			ItemData[ _Item_Description ]
			);
			
		console_print( Client, Text );
	}
	
	ShowItemDescMenu( Client );
}

public ClientCommand_ShowCredits( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowCreditsMenu( Client );
	}
	
	return PLUGIN_HANDLED;
}

ShowCreditsMenu( const Client )
{
	new Title[ 256 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L^n^n%L: \yXellath\w^n^n%L \yF0RCE\w!^n",
		Client,
		"MENU_PREFIX",
		Client,
		"CREDITS",
		Client,
		"AUTHOR",
		Client,
		"SPECIAL_THANKS"
		);
	
	new Menu = menu_create( Title, "CreditsMenuHandler" );
	
	menu_additem( Menu, "\yFor \rTeh \yLULz\w", "*" );

	formatex( Title, charsmax( Title ), 
		"%L %L",
		Client,
		"MENU_MAIN_HELP",
		Client,
		"MENU"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public CreditsMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
	
		ShowHelpMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	if( Info[ 0 ] == '*' )
	{
		show_motd( Client, "http://www.dafk.net/what/", "For the LULz" );
	}
}
	
public ClientCommand_PlayerLookup( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowPlayerLookupMenu( Client );
	}
	
	return PLUGIN_HANDLED;
}

ShowPlayerLookupMenu( const Client )
{
	new Title[ 128 ];
	formatex( Title, charsmax( Title ), 
		"%L^n\w%L^n^n%L\w^n",
		Client,
		"MENU_PREFIX",
		Client,
		"MENU_PLAYER_LOOKUP",
		Client,
		"MENU_PLAYER_PICK"
		);
	
	new Menu = menu_create( Title, "PlayerLookupMenuHandler" );
	
	new PlayerClientName[ MaxSlots ];
	new PlayerName[ MaxSlots ];
	new Info[ 3 ];
	
	for( new PlayerIndex = 1; PlayerIndex <= MaxPlayers; PlayerIndex++ )
	{
		if( is_user_connected( PlayerIndex ) )
		{
			get_user_name( PlayerIndex, PlayerName, charsmax( PlayerName ) );
			num_to_str( PlayerIndex, Info, charsmax( Info ) );
			
			if( PlayerIndex == Client )
			{
				formatex( PlayerClientName, charsmax( PlayerClientName ), 
					"\r%s\w", 
					PlayerName 
					);
			
				menu_additem( Menu, PlayerClientName, Info );
			}
			else
			{
				menu_additem( Menu, PlayerName, Info );
			}
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
		"%L",
		Client,
		"MENU_MAIN"
		);
	
	menu_setprop( Menu, MPROP_EXITNAME, Title );
	
	menu_display( Client, Menu, 0 );
}

public PlayerLookupMenuHandler( Client, Menu, Item )
{
	if( Item == MENU_EXIT )
	{
		menu_destroy( Menu );
	
		ShowMainMenu( Client );
		
		return;
	}
	
	new Info[ 3 ];
	new Access;
	new Callback;
	
	menu_item_getinfo( Menu, Item, Access, Info, charsmax( Info ), _, _, Callback );
	menu_destroy( Menu );
	
	PlayerLookup( Client, str_to_num( Info ) );
}

PlayerLookup( const Client, const Player )
{
	if( !is_user_connected( Client ) 
	|| !is_user_connected( Player ) )
	{
		return;
	}

	new Motd[ 1536 ];
	new Len;
	
	new PlayerName[ MaxSlots ];
	new ClassData[ ClassDataStruct ];
	ArrayGetArray( Classes, PlayerClass[ Player ], ClassData );
	
	get_user_name( Player, PlayerName, charsmax( PlayerName ) );
	
	new ItemData[ ItemDataStruct ];
	ArrayGetArray( Items, PlayerItem[ Player ], ItemData );
	
	#if defined ShowGuildInPlayerLookup
		new GuildName[ 64 ];
		new Guild = DBM_GetClientGuild( Player );
		if( Guild > -1 )
		{
			DBM_GetGuildName( Guild, GuildName );
		}
		else
		{
			formatex( GuildName, charsmax( GuildName ),
				"%L",
				Client,
				"NONE"
				);
		}
	#endif
	
	if( Display[ Client ] == _MOTD )
	{
		Len = formatex( Motd, 1535 - Len, "<body bgcolor=#000000><font color=#FFFFFF><pre>" );
		
		if( !containi( SteamId[ Client ], "STEAM_" ) )
		{
			Len += formatex( Motd[ Len ], 1535 - Len, 
				"%L: %s^n^n", 
				Client,
				"NAME",
				PlayerName
				);
		}
		else
		{
			Len += formatex( Motd[ Len ], 1535 - Len, 
				"%L: %s^nSteam ID: %s^n^n", 
				Client,
				"NAME",
				PlayerName, 
				SteamId[ Player ]
				);
		}
	
		#if defined ShowGuildInPlayerLookup
			Len += formatex( Motd[ Len ], 1535 - Len, 
				"%L: %L^n%L: %i^n%L: %i^n%L: %i^n%L: %L^n%L: %s^n^n",
				Client,
				"CURRENT_CLASS",
				Client,
				ClassData[ _Class_Name ],
				Client,
				"CURRENT_LEVEL",
				PlayerLevel[ Player ][ PlayerClass[ Player ] ],
				Client,
				"CURRENT_EXP",
				PlayerExperience[ Player ][ PlayerClass[ Player ] ],
				Client,
				"CURRENT_MANA",
				PlayerMana[ Player ][ PlayerClass[ Player ] ],
				Client,
				"CURRENT_ITEM",
				Client,
				ItemData[ _Item_Name ],
				Client,
				"GUILD",
				GuildName
				);
		#else
			Len += formatex( Motd[ Len ], 1535 - Len, 
				"%L: %L^n%L: %i^n%L: %i^n%L: %i^n%L: %L^n^n",
				Client,
				"CURRENT_CLASS",
				Client,
				ClassData[ _Class_Name ],
				Client,
				"CURRENT_LEVEL",
				PlayerLevel[ Player ][ PlayerClass[ Player ] ],
				Client,
				"CURRENT_EXP",
				PlayerExperience[ Player ][ PlayerClass[ Player ] ],
				Client,
				"CURRENT_MANA",
				PlayerMana[ Player ][ PlayerClass[ Player ] ],
				Client,
				"CURRENT_ITEM",
				Client,
				ItemData[ _Item_Name ]
				);
		#endif
	
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"<u>%L</u>^n^n",
			Client,
			"STATS"
			);
		
		for( new StatIndex = _Stat_Intelligence; StatIndex < StatStruct; StatIndex++ )
		{
			Len += formatex( Motd[ Len ], 1535 - Len, 
				"%L (%L): %i (+%i)^n",
				Client,
				StatName[ StatIndex ][ _Full ],
				Client,
				StatName[ StatIndex ][ _Short ],
				PlayerStats[ Player ][ StatIndex ],
				PlayerAdditionalStats[ Player ][ StatIndex ]
				);
		}
		
		Len += formatex( Motd[ Len ], 1535 - Len, "^n" );
	
		new CurrentMaxClasses = ArraySize( Classes );
		for( new Class = 1; Class < CurrentMaxClasses; Class++ )
		{
			ArrayGetArray( Classes, Class, ClassData );
			
			Len += formatex( Motd[ Len ], 1535 - Len, 
				"%L: %L %i/%i - EXP: %i^n",
				Client,
				ClassData[ _Class_Name ],
				Client,
				"LEVEL",
				PlayerLevel[ Player ][ Class ],
				MaxLevel,
				PlayerExperience[ Player ][ Class ]
				);
		}
		
		Len += formatex( Motd[ Len ], 1535 - Len, "</body></font></pre>" );
		
		new Text[ MaxSlots * 2 ];
		formatex( Text, charsmax( Text ),
			"%L %L",
			Client,
			"DIABLO_MOD",
			Client,
			"MENU_MAIN_LOOKUP"
			);
		
		show_motd( Client, Motd, Text );
	}
	else
	{
		client_print_color( Client, DontChange, 
			"^4%L^3 %L", 
			Client,
			"MOD_PREFIX",
			Client,
			"MENU_LOOKUP_PRINT",
			PlayerName 
			);
	
		if( !containi( SteamId[ Client ], "STEAM_" ) )
		{
			console_print( Client, 
				"^n%L: %s^n^n",
				Client,
				"NAME",
				PlayerName
				);
		}
		else
		{
			console_print( Client, 
				"^n%L: %s^nSteam ID: %s^n^n", 
				Client,
				"NAME",
				PlayerName, 
				SteamId[ Player ]
				);
		}
			
		console_print( Client, 
			"%L: %L^n%L: %i^n%L: %i^n",
			Client,
			"CURRENT_CLASS",
			Client,
			ClassData[ _Class_Name ],
			Client,
			"CURRENT_LEVEL",
			PlayerLevel[ Player ][ PlayerClass[ Player ] ],
			Client,
			"CURRENT_EXP",
			PlayerExperience[ Player ][ PlayerClass[ Player ] ]
			);
			
		#if defined ShowGuildInPlayerLookup
			console_print( Client,
				"%L: %i^n%L: %L^n%L: %s^n^n",
				Client,
				"CURRENT_MANA",
				PlayerMana[ Player ][ PlayerClass[ Player ] ],
				Client,
				"CURRENT_ITEM",
				Client,
				ItemData[ _Item_Name ],
				Client,
				"GUILD",
				GuildName
				);
		#else
			console_print( Client,
				"%L: %i^n%L: %L^n^n",
				Client,
				"CURRENT_MANA",
				PlayerMana[ Player ][ PlayerClass[ Player ] ],
				Client,
				"CURRENT_ITEM",
				Client,
				ItemData[ _Item_Name ]
				);
		#endif
			
		for( new StatIndex = _Stat_Intelligence; StatIndex < StatStruct; StatIndex++ )
		{
			console_print( Client, 
				"%L (%L): %i (+%i)^n",
				Client,
				StatName[ StatIndex ][ _Full ],
				Client,
				StatName[ StatIndex ][ _Short ],
				PlayerStats[ Player ][ StatIndex ],
				PlayerAdditionalStats[ Player ][ StatIndex ]
				);
		}
		
		console_print( Client, "^n" );
	
		new CurrentMaxClasses = ArraySize( Classes );
		for( new Class = 1; Class < CurrentMaxClasses; Class++ )
		{
			ArrayGetArray( Classes, Class, ClassData );
			
			console_print( Client, 
				"%L: %L %i/%i - EXP: %i^n",
				Client,
				ClassData[ _Class_Name ],
				Client,
				"LEVEL",
				PlayerLevel[ Player ][ Class ],
				MaxLevel,
				PlayerExperience[ Player ][ Class ]
				);
		}
	}
}

public ClientCommand_Commands( Client )
{
	if( is_user_connected( Client ) )
	{
		ShowCommands( Client );
	}
	
	return PLUGIN_HANDLED;
}

ShowCommands( const Client )
{
	if( !is_user_connected( Client ) )
	{
		return;
	}

	new Motd[ 1536 ];
	new Len;
	
	if( Display[ Client ] == _MOTD )
	{
		Len = formatex( Motd, 1535 - Len, "<body bgcolor=#000000><font color=#FFFFFF><pre>" );
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"<u>%L</u>^n^n",
			Client,
			"COMMANDS"
			);
			
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"<b>%L</b>^n^n",
			Client,
			"COMMANDS_PREFIXED"
			);
	
		new CommandData[ CommandStruct ];
		for( new CommandIndex = 0; CommandIndex < ArraySize( Commands ); CommandIndex++ )
		{
			ArrayGetArray( Commands, CommandIndex, CommandData );
			
			Len += formatex( Motd[ Len ], 1535 - Len, 
				"%L - %L^n",
				Client,
				CommandData[ _Command ],
				Client,
				CommandData[ _Desc ]
				);
		}
		
		Len += formatex( Motd[ Len ], 1535 - Len, "</body></font></pre>" );
		
		new Text[ MaxSlots * 2 ];
		formatex( Text, charsmax( Text ),
			"%L %L",
			Client,
			"DIABLO_MOD",
			Client,
			"COMMANDS"
			);
		
		show_motd( Client, Motd, Text );
	}
	else
	{
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"COMMANDS_PRINTED"
			);
	
		console_print( Client, 
			"^n%L^n^n", 
			Client,
			"COMMANDS"
			);
			
		console_print( Client, 
			"%L^n^n",
			Client,
			"COMMANDS_PREFIXED"
			);
		
		new CommandData[ CommandStruct ];
		for( new CommandIndex = 0; CommandIndex < ArraySize( Commands ); CommandIndex++ )
		{
			ArrayGetArray( Commands, CommandIndex, CommandData );
			
			console_print( Client, 
				"%L - %L^n", 
				Client,
				CommandData[ _Command ],
				Client,
				CommandData[ _Desc ]
				);
		}
	}
}

GameplayHelp( const Client )
{
	if( !is_user_connected( Client ) )
	{
		return;
	}

	new Motd[ 1536 ];
	new Len;
	
	if( Display[ Client ] == _MOTD )
	{
		Len = formatex( Motd, 1535 - Len, "<body bgcolor=#000000><font color=#FFFFFF><pre>" );
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"%L",
			Client, 
			"GAMEPLAYHELP_1"
			);
			
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"%L^n%L^n%L^n^n",
			Client,
			"GAMEPLAYHELP_2",
			Client, 
			"GAMEPLAYHELP_3",
			Client, 
			"GAMEPLAYHELP_4"
			);
		
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"<u>%L</u>^n^n%L^n", 
			Client, 
			"GAMEPLAYHELP_5",
			Client, 
			"GAMEPLAYHELP_6",
			( ArraySize( Classes ) - 1 ), 
			( ArraySize( Items ) - 1 ), 
			( ArraySize( Quests ) ) 
			);
		
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"%L^n",
			Client, 
			"GAMEPLAYHELP_7"
			);
		
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"^n%L^n%L^n%L^n%L^n^n%L^n",
			Client, 
			"GAMEPLAYHELP_8",
			Client, 
			"GAMEPLAYHELP_9",
			Client, 
			"GAMEPLAYHELP_10",
			Client, 
			"GAMEPLAYHELP_11",
			Client, 
			"GAMEPLAYHELP_12",
			get_pcvar_num( Cvars[ _Item_Durability_Interval ] )
			);
			
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"%L^n^n",
			Client, 
			"GAMEPLAYHELP_13"
			);
		
		Len += formatex( Motd[ Len ], 1535 - Len, 
			"<u>%L</u>^n%L^n%L^n%L",
			Client, 
			"GAMEPLAYHELP_14",
			Client, 
			"GAMEPLAYHELP_15",
			Client, 
			"GAMEPLAYHELP_16",
			Client, 
			"GAMEPLAYHELP_17"
			);
		
		Len += formatex( Motd[ Len ], 1535 - Len, "</body></font></pre>" );
		
		new Text[ MaxSlots * 2 ];
		formatex( Text, charsmax( Text ),
			"%L %L %L",
			Client,
			"DIABLO_MOD",
			Client,
			"GAMEPLAY",
			Client,
			"MENU_MAIN_HELP"
			);
		
		show_motd( Client, Motd, Text );
	}
	else
	{
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"GAMEPLAY_INFO"
			);
	
		console_print( Client,
			"^n%L",
			Client, 
			"GAMEPLAYHELP_1"
			);
		
		console_print( Client, 
			"%L^n^n",
			Client, 
			"GAMEPLAYHELP_2"
			);
			
		console_print( Client, 
			"%L",
			Client, 
			"GAMEPLAYHELP_3"
			);
			
		console_print( Client, 
			"%L",
			Client, 
			"GAMEPLAYHELP_4"
			);
		
		console_print( Client, 
			"%L^n^n",
			Client, 
			"GAMEPLAYHELP_5"
			);
		
		console_print( Client, 
			"%L^n",
			Client, 
			"GAMEPLAYHELP_6",
			ArraySize( Classes ) - 1,
			ArraySize( Items ) - 1,
			ArraySize( Quests )
			);
		
		console_print( Client, 
			"%L^n",
			Client, 
			"GAMEPLAYHELP_7"
			);
		
		console_print( Client, 
			"^n%L",
			Client, 
			"GAMEPLAYHELP_8"
			);
			
		console_print( Client, 
			"%L^n",
			Client, 
			"GAMEPLAYHELP_9" 
			);
			
		console_print( Client,
			"%L",
			Client, 
			"GAMEPLAYHELP_10"
			);
		
		console_print( Client, 
			"%L^n^n",
			Client, 
			"GAMEPLAYHELP_11" );
		
		console_print( Client, 
			"%L^n",
			Client, 
			"GAMEPLAYHELP_12",
			get_pcvar_num( Cvars[ _Item_Durability_Interval ] )
			);
		
		console_print( Client, 
			"%L^n^n",
			Client, 
			"GAMEPLAYHELP_13"
			);
		
		console_print( Client, 
			"%L^n^n",
			Client, 
			"GAMEPLAYHELP_14"
			);
			
		console_print( Client, 
			"%L",
			Client, 
			"GAMEPLAYHELP_15"
			);
			
		console_print( Client, 
			"%L",
			Client, 
			"GAMEPLAYHELP_16"
			);
			
		console_print( Client, 
			"%L",
			Client, 
			"GAMEPLAYHELP_17"
			);
	}
}

ShowHUDText( const Client, bool:Spectating = false, const Player = 0 )
{
	new Text[ 512 ];
	new Len;
	
	if( !Spectating )
	{
		new ClassData[ ClassDataStruct ];
		ArrayGetArray( Classes, PlayerClass[ Client ], ClassData );
		
		Len = formatex( Text, charsmax( Text ) - Len, 
			"%L^n%L: %i/%i^n%L: %L^n%L: %i/%i^n%L: %i^nEXP: %i", 
			Client,
			"MOD_PREFIX",
			Client,
			"HEALTH",
			floatround( entity_get_float( Client, EV_FL_health ) ),
			floatround( entity_get_float( Client, EV_FL_max_health ) ),
			Client,
			"CLASS",
			Client,
			ClassData[ _Class_Name ],
			Client,
			"LEVEL",
			PlayerLevel[ Client ][ PlayerClass[ Client ] ],
			MaxLevel,
			Client,
			"MANA",
			PlayerMana[ Client ][ PlayerClass[ Client ] ],
			PlayerExperience[ Client ][ PlayerClass[ Client ] ]
			);
		
		if( PlayerLevel[ Client ][ PlayerClass[ Client ] ] < MaxLevel )
		{
			new StartExp = get_pcvar_num( Cvars[ _Exp_Expotential ] );
			
			Len += formatex( Text[ Len ], charsmax( Text ) - Len, 
				"/%i",
				( StartExp * PlayerLevel[ Client ][ PlayerClass[ Client ] ] * ( PlayerLevel[ Client ][ PlayerClass[ Client ] ] == 1 ? PlayerLevel[ Client ][ PlayerClass[ Client ] ] : ( PlayerLevel[ Client ][ PlayerClass[ Client ] ] - 1 ) ) )
				);
		}
		
		if( PlayerItem[ Client ] )
		{
			new ItemData[ ItemDataStruct ];
			ArrayGetArray( Items, PlayerItem[ Client ], ItemData );
			
			Len += formatex( Text[ Len ], charsmax( Text ) - Len, 
				"^n%L: %L (%L)^n%L: %i",
				Client,
				"ITEM_NAME",
				Client,
				ItemData[ _Item_Name ],
				Client,
				CategoryName[ ItemData[ _Item_Category ] ],
				Client,
				"ITEM_DURABILITY",
				PlayerItemDurability[ Client ]
				);
		}
		else
		{
			Len += formatex( Text[ Len ], charsmax( Text ) - Len, 
				"^n%L: %L",
				Client,
				"ITEM_NAME",
				Client,
				"NONE"
				);
		}
		
		#if defined ShowPetFollowersInHUD
			new Pet[ 64 ];
			DBM_GetPetName( Client, Pet );
			
			Len += formatex( Text[ Len ], charsmax( Text ) - Len, 
				"^n%L: %s", 
				Client,
				"PET",
				Pet 
				);
		#endif
		
		set_hudmessage( 0, 255, 0, ClientHUDConstXPos, ClientHUDConstYPos, _, _, HUDThinkInterval, 0.1, 0.1, -1 );
		show_hudmessage( Client, Text );
	}
	else
	{
		new ClassData[ ClassDataStruct ];
		ArrayGetArray( Classes, PlayerClass[ Player ], ClassData );
		
		new PlayerName[ MaxSlots ];
		get_user_name( Player, PlayerName, charsmax( PlayerName ) );
		
		Len = formatex( Text, charsmax( Text ) - Len, 
			"%L^n%L: %s^n%L: %i/%i^n%L: %L^n%L: %i/%i^n%L: %i^nEXP: %i", 
			Client,
			"MOD_PREFIX",
			Client,
			"NAME",
			PlayerName,
			Client,
			"HEALTH",
			floatround( entity_get_float( Player, EV_FL_health ) ),
			floatround( entity_get_float( Player, EV_FL_max_health ) ),
			Client,
			"CLASS",
			Client,
			ClassData[ _Class_Name ],
			Client,
			"LEVEL",
			PlayerLevel[ Player ][ PlayerClass[ Player ] ],
			MaxLevel,
			Client,
			"MANA",
			PlayerMana[ Player ][ PlayerClass[ Player ] ],
			PlayerExperience[ Player ][ PlayerClass[ Player ] ]
			);
		
		if( PlayerLevel[ Player ][ PlayerClass[ Player ] ] < MaxLevel )
		{
			new StartExp = get_pcvar_num( Cvars[ _Exp_Expotential ] );
			
			Len += formatex( Text[ Len ], charsmax( Text ) - Len, 
				"/%i",
				( StartExp * PlayerLevel[ Player ][ PlayerClass[ Player ] ] * ( PlayerLevel[ Player ][ PlayerClass[ Player ] ] == 1 ? PlayerLevel[ Player ][ PlayerClass[ Player ] ] : ( PlayerLevel[ Player ][ PlayerClass[ Player ] ] - 1 ) ) )
				);
		}
		
		if( PlayerItem[ Player ] )
		{
			new ItemData[ ItemDataStruct ];
			ArrayGetArray( Items, PlayerItem[ Player ], ItemData );
			
			Len += formatex( Text[ Len ], charsmax( Text ) - Len, 
				"^n%L: %L (%L)^n%L: %i^n^n",
				Client,
				"ITEM_NAME",
				Client,
				ItemData[ _Item_Name ],
				Client,
				CategoryName[ ItemData[ _Item_Category ] ],
				Client,
				"ITEM_DURABILITY",
				PlayerItemDurability[ Player ]
				);
		}
		else
		{
			Len += formatex( Text[ Len ], charsmax( Text ) - Len, 
				"^n%L: %L^n^n",
				Client,
				"ITEM_NAME",
				Client,
				"NONE"
				);
		}
		
		for( new StatIndex = _Stat_Intelligence; StatIndex < StatStruct; StatIndex++ )
		{
			Len += formatex( Text[ Len ], charsmax( Text ) - Len, 
				"%L (%L): %i (+%i)^n",
				Client,
				StatName[ StatIndex ][ _Full ],
				Client,
				StatName[ StatIndex ][ _Short ],
				PlayerStats[ Player ][ StatIndex ],
				PlayerAdditionalStats[ Player ][ StatIndex ]
				);
		}
		
		#if defined ShowPetFollowersInHUD
			new Pet[ 64 ];
			DBM_GetPetName( Client, Pet );
			
			Len += formatex( Text[ Len ], charsmax( Text ) - Len, 
				"^n%L: %s", 
				Client,
				"PET",
				Pet 
				);
		#endif
		
		set_hudmessage( 255, 255, 255, SpectatorHUDConstXPos, SpectatorHUDConstYPos, _, _, HUDThinkInterval, 0.1, 0.1, -1 );
		show_hudmessage( Client, Text );
	}
}

public Forward_Engine_HUDThink( Entity )
{
	if( is_valid_ent( Entity ) 
	&& HUDThinkEntity == Entity )
	{
		for( new Client = 1; Client <= MaxPlayers; Client++ )
		{	
			if( is_user_alive( Client ) )
			{
				ShowHUDText( Client );
			}
			else
			{
				new Player;
				new Body;
				get_user_aiming( Client, Player, Body );
				
				if( ( 1 <= Player <= MaxPlayers ) 
				&& is_user_alive( Player ) ) 
				{
					ShowHUDText( Client, true, Player );
				}
			}
		}
		
		entity_set_float( Entity, EV_FL_nextthink, get_gametime( ) + HUDThinkInterval );
	}
}

public Forward_Engine_DurabilityThink( Entity )
{
	if( is_valid_ent( Entity ) 
	&& DurabilityThinkEntity == Entity )
	{
		new Durability = get_pcvar_num( Cvars[ _Item_Durability_Ratio ] );
		for( new Client = 1; Client <= MaxPlayers; Client++ )
		{
			if( is_user_alive( Client )
			&& PlayerItem[ Client ] )
			{
				PlayerItemDurability[ Client ] -= Durability;
				
				CheckDurability( Client );
			}
		}
		
		entity_set_float( Entity, EV_FL_nextthink, get_gametime( ) + get_pcvar_float( Cvars[ _Item_Durability_Interval ] ) );
	}
}

CheckDurability( const Client )
{
	new ItemData[ ItemDataStruct ];
	ArrayGetArray( Items, PlayerItem[ Client ], ItemData );
	if( PlayerItemDurability[ Client ] <= 0 )
	{
		ExecuteForward( Forwards[ _Forward_Item_Dispatched ], ForwardReturns[ _Forward_Item_Dispatched ], Client, PlayerItem[ Client ] );
	
		PlayerItem[ Client ] = 0;
		PlayerItemDurability[ Client ] = 0;
		
		client_print_color( Client, DontChange, 
			"^4%L^3 %L",
			Client,
			"MOD_PREFIX",
			Client,
			"ITEM_DUR_RUN_OUT"
			);
	}
}

public Forward_Engine_RegThink( Entity )
{
	if( is_valid_ent( Entity ) )
	{
		new Client = entity_get_edict( Entity, EV_ENT_owner );
		if( RegThinkEntity[ Client ] == Entity
		&& is_user_alive( Client ) )
		{
			RegenerateHealth( Client );
		}
		
		entity_set_float( Entity, EV_FL_nextthink, get_gametime( ) + ( RegThinkInterval - ( ( PlayerStats[ Client ][ _Stat_Regeneration ] + PlayerAdditionalStats[ Client ][ _Stat_Regeneration ] ) / 125.0 ) ) );
	}
}

RegenerateHealth( const Client )
{
	new Float:CurrentHealth = entity_get_float( Client, EV_FL_health );
	new Float:MaxHealth = entity_get_float( Client, EV_FL_max_health );
	
	if( CurrentHealth < MaxHealth )
	{
		entity_set_float( Client, EV_FL_health, CurrentHealth + 1 + ( ( ( PlayerStats[ Client ][ _Stat_Stamina ] + PlayerAdditionalStats[ Client ][ _Stat_Stamina ] ) / 50.0 ) * ( PlayerStats[ Client ][ _Stat_Regeneration ] + PlayerAdditionalStats[ Client ][ _Stat_Regeneration ] / 100.0 ) ) );
	}
}

CreateThinkEntity( const ClassName[ ], const Float:Interval = 1.0 )
{
	new Entity = create_entity( "info_target" );
	entity_set_string( Entity, EV_SZ_classname, ClassName );
	
	entity_set_float( Entity, EV_FL_nextthink, get_gametime( ) + Interval );
	
	return Entity;
}

public Forward_Engine_ItemThink( Entity )
{
	if( is_valid_ent( Entity ) )
	{
		new Float:Angle[ 3 ];
		entity_get_vector( Entity, EV_VEC_angles, Angle );
		Angle[ 1 ] += 1.5;
		
		entity_set_vector( Entity, EV_VEC_angles, Angle );
		
		entity_set_float( Entity, EV_FL_nextthink, get_gametime() + 0.1 );
	}
}

public ClientCommand_DropItem( Client )
{
	if( is_user_alive( Client ) )
	{
		if( PlayerItem[ Client ] )
		{
			ExecuteForward( Forwards[ _Forward_Item_Dispatched ], ForwardReturns[ _Forward_Item_Dispatched ], Client, PlayerItem[ Client ] );
		
			DispatchItem( Client, PlayerItem[ Client ], PlayerItemDurability[ Client ] );
			
			PlayerItem[ Client ] = 0;
			PlayerItemDurability[ Client ] = 0;
			
			client_print_color( Client, DontChange, 
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"ITEM_DROPPED"
				);
		}
		else
		{
			client_print_color( Client, DontChange, 
				"^4%L^3 %L",
				Client,
				"MOD_PREFIX",
				Client,
				"ITEM_DONT_HAVE"
				);
		}
	}
	
	return PLUGIN_HANDLED;
}

DispatchItem( const Client, const ItemIndex, const Durability )
{
	new Entity = create_entity( "info_target" );
	entity_set_string( Entity, EV_SZ_classname, ItemClassName );
	
	entity_set_model( Entity, ItemModel );
	
	entity_set_int( Entity, EV_INT_solid, SOLID_BBOX );
	entity_set_int( Entity, EV_INT_movetype, MOVETYPE_TOSS );
	
	new Float:Origin[ 3 ];
	entity_get_vector( Client, EV_VEC_origin, Origin );
	
	if( is_user_alive( Client ) )
	{
		Origin[ 0 ] += 40.0;
	}
	
	Origin[ 2 ] += 85.0;
	
	entity_set_origin( Entity, Origin );
	
	new Float:Mins[ 3 ] = { -5.920000, -10.260000, -4.970000 };
	new Float:Maxs[ 3 ] = { 5.700000, 1.410000, 5.080000 };
	entity_set_size( Entity, Mins, Maxs );
	
	entity_set_int( Entity, EV_INT_iuser1, ItemIndex );
	entity_set_int( Entity, EV_INT_iuser2, Durability );

	entity_set_float( Entity, EV_FL_nextthink, get_gametime( ) ); 
}

UTIL_BarTime( const Client, const Float:Duration = 0.0 )
{
	message_begin( MSG_ONE_UNRELIABLE, MsgIdBarTime, _, Client );
	{
		write_byte( floatround( Duration ) );
		write_byte( 0 );
	}
	message_end( );
}

UTIL_TutorMessage( const Client, Color, Input[ ], any:... )
{
	if( is_user_connected( Client ) )
	{
		if( task_exists( Client + TaskIdRemoveTutor ) )
		{
			message_begin( MSG_ONE_UNRELIABLE, MsgIdTutorClose, _, Client );
			message_end( );
			
			remove_task( Client + TaskIdRemoveTutor );
		}
		
		client_cmd( Client, "spk ^"events/tutor_msg.wav^"" );
		
		new Text[ 256 ];
		vformat( Text, charsmax( Text ), Input, 4 );
	
		message_begin( MSG_ONE_UNRELIABLE, MsgIdTutorText, _, Client );
		{
			write_string( Text );
			write_byte( 0 );
			write_short( 0 );
			write_short( 0 );
			write_short( 1 << Color );
		}
		message_end( );
	}
	
	set_task( 7.0, "RemoveTutorMessage", Client + TaskIdRemoveTutor );
}

public RemoveTutorMessage( TaskId )
{
	new Client = TaskId - TaskIdRemoveTutor;

	message_begin( MSG_ONE_UNRELIABLE, MsgIdTutorClose, _, Client );
	message_end( );
}