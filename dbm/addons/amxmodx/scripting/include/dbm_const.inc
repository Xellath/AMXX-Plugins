 #if defined _dbm_const_included
    #endinput
#endif

#define _dbm_const_included

// Comment to remove the pet name and stat bonus from HUD (core hud)
// Note: Petfollowers addon must be turned on in order for this to function
#define ShowPetFollowersInHUD 				1

// Comment to remove the guild view in player lookup
// Note: Guild addon must be turned on in order for this to function
#define ShowGuildInPlayerLookup				1

// Comment to remove damage block during monster round
// Note: Monster addon must be turned on in order for this to function
#define EnableDamageBlockMonsterRound 1

const MaxSlots = 32;
const MaxSteamIdChars = 35;

// Positions used for client hud
const Float:ClientHUDConstXPos = 0.11;
const Float:ClientHUDConstYPos = 0.01;

// Positions used for spectator hud
const Float:SpectatorHUDConstXPos = 0.78;
const Float:SpectatorHUDConstYPos = 0.56;

// Positions used for skill text (DBM_SkillHudText)
const Float:SkillHUDConstXPos = 0.42;
const Float:SkillHUDConstYPos = 0.46;

const Float:HUDThinkInterval = 1.0;
const Float:RegThinkInterval = 3.0;

const MaxClasses = 15;
const MaxItems = 60;
const MaxQuests = 60;
const MaxLevel = 200;

const MaxGuilds = 50;

const MaxPartyMembers = 4;

enum _:ClassDataStruct
{
	_Class_Name[ MaxSlots ],
	_Class_Description[ 256 ],
	_Class_Save_Key[ MaxSlots ],
	_Class_Ability_Name[ MaxSlots ],
	_Class_Ability_Desc[ 256 ],
	ClassAccess:_Class_Access,
	Float:_Class_Ability_Delay,
	_Class_Ability_Allow_Moving,
	Array:_Class_Max_Stats
};

enum _:ItemDataStruct
{
	_Item_Name[ MaxSlots ],
	_Item_Description[ 256 ],
	_Item_Cost,
	_Item_Stat,
	_Item_Category,
	_Item_Durability
};

enum _:QuestDataStruct
{
	_Quest_Name[ MaxSlots ],
	_Quest_Description[ 256 ],
	_Quest_Save_Key[ MaxSlots ],
	_Quest_Objective_Value,
	_Quest_Player_Value[ MaxSlots + 1 ]
};

enum _:AddonDataStruct
{
	_Addon_Name[ MaxSlots ],
	_Addon_Function[ 64 ],
	_Addon_Plugin_Name[ MaxSlots ]
};

enum _:StatStruct
{
	_Stat_Intelligence,
	_Stat_Stamina,
	_Stat_Dexterity,
	_Stat_Agility,
	_Stat_Regeneration
};

enum ClassAccess
{
	_Bronze,
	_Silver,
	_Gold,
	_Platinum
};

enum _:AccessType
{
	_Name[ MaxSlots ],
	_Flag
};

enum _:StatOperators
{
	_Stat_Increase,
	_Stat_Decrease
};

stock const AccessName[ ClassAccess ][ AccessType ] =
{
	{ "ACCESSNAME_BRONZE", ADMIN_ALL },
	{ "ACCESSNAME_SILVER",	ADMIN_LEVEL_F },
	{ "ACCESSNAME_GOLD", ADMIN_LEVEL_G },
	{ "ACCESSNAME_PLATINUM", ADMIN_LEVEL_H }
};

enum _:ItemCategory
{
	_Common,
	_Rare,
	_Unique
};

stock const CategoryName[ ItemCategory ][ ] =
{
	"CATEGORYNAME_COMMON",
	"CATEGORYNAME_RARE",
	"CATEGORYNAME_UNIQUE"
};

enum _:StatNameType
{
	_Full,
	_Short
};

stock const StatName[ StatStruct ][ StatNameType ][ ] =
{
	{ "STATNAME_INTELLIGENCE", "STATNAME_INT" },
	{ "STATNAME_STAMINA", "STATNAME_STA" },
	{ "STATNAME_DEXTERITY", "STATNAME_DEX" },
	{ "STATNAME_AGILITY", "STATNAME_AGI" },
	{ "STATNAME_REGENERATION", "STATNAME_REG" }
};

enum _:StatDescType
{
	_Stat_Desc,
	_Stat_Desc_Scaling
};

stock const StatDesc[ StatStruct ][ StatDescType ][ ] = 
{
	{ "STATDESC_INTELLIGENCE", "STATNAME_INTELLIGENCE_SCALING" },
	{ "STATDESC_STAMINA", "STATDESC_STAMINA_SCALING" },
	{ "STATDESC_DEXTERITY", "STATDESC_DEXTERITY_SCALING" },
	{ "STATDESC_AGILITY", "STATDESC_AGILITY_SCALING" },
	{ "STATDESC_REGENERATION", "STATDESC_REGENERATION_SCALING" }
};

const TextLength = 192;

stock DBM_RegisterCommand( Command[ ], Function[ ] )
{
	new CommandText[ MaxSlots * 2 ];
	
	new Language[ 3 ];
	new Languages = get_langsnum( );
	for( new LangIndex; LangIndex < Languages; LangIndex++ )
	{
		get_lang( LangIndex, Language )
		
		formatex( CommandText, charsmax( CommandText ), "say %L", Language, Command );
		register_clcmd( CommandText, Function );
		
		formatex( CommandText, charsmax( CommandText ), "say_team %L", Language, Command );
		register_clcmd( CommandText, Function );
		
		formatex( CommandText, charsmax( CommandText ), "say /%L", Language, Command );
		register_clcmd( CommandText, Function );
		
		formatex( CommandText, charsmax( CommandText ), "say_team /%L", Language, Command );
		register_clcmd( CommandText, Function );
		
		formatex( CommandText, charsmax( CommandText ), "say .%L", Language, Command );
		register_clcmd( CommandText, Function );
		
		formatex( CommandText, charsmax( CommandText ), "say_team .%L", Language, Command );
		register_clcmd( CommandText, Function );
		
		formatex( CommandText, charsmax( CommandText ), "say !%L", Language, Command );
		register_clcmd( CommandText, Function );
		
		formatex( CommandText, charsmax( CommandText ), "say_team !%L", Language, Command );
		register_clcmd( CommandText, Function );
	}
}