#if defined _dbm_api_included
    #endinput
#endif

#define _dbm_api_included

#include < dbm_const >

/*
 * Registers a class
 * 
 * @param		ClassName - Class name
 * @param		ClassDescription - Description of class
 * @param		SaveKey - Save key that is used to save data to the specific class
 * @param		AbilityName - Name of the class ability
 * @param		Access - Access to class
 * @param		AbilityDelay - Ability delay in seconds
 * @param		AllowMoving - Bool to allow moving
 *
 * @note 		enum ClassAccess
 *				{
 *					_Bronze,
 *					_Silver,
 *					_Gold,
 *					_Platinum
 *				};
 *
 * @note		enum _:StatStruct
 *				{
 *					_Stat_Intelligence,
 *					_Stat_Stamina,
 *					_Stat_Dexterity,
 *					_Stat_Agility,
 *					_Stat_Regeneration
 *				};
 * 
 * @return 		Pointer to class index
 */
native DBM_RegisterClass( const ClassName[ ], const ClassDescription[ ], const SaveKey[ ], const AbilityName[ ], const AbilityDescription[ ], const ClassAccess:Access, Float:AbilityDelay = 2.0, bool:AllowMoving = false, const MaxStats[ StatStruct ] = { 400, 400, 400, 400, 400 } );

/*
 * Registers an item
 * 
 * @param		ItemName - Item name
 * @param		ItemDescription - Description of item
 * @param		Cost - Price of the item in mana
 * @param		Stat - The amount of stats the item offers
 * @param		Category - What category the item is in
 * @param		Durability - The durability of the item (before it breaks)
 *
 * @note 		enum ItemCategory
 *				{
 *					_Common,
 *					_Rare,
 *					_Unique
 *				};
 * 
 * @return 		Pointer to item index
 */
native DBM_RegisterItem( const ItemName[ ], const ItemDescription[ ], const Cost, const Stat, const Category, const Durability = 255 );

/*
 * Registers a quest
 * 
 * @param		QuestName - Quest name
 * @param		QuestDescription - Description of the quest objective
 * @param		SaveKey - Save key that is used to save data to the specific quest
 * 
 * @return 		Pointer to quest index
 */
native DBM_RegisterQuest( const QuestName[ ], const QuestDescription[ ], const SaveKey[ ], const ObjectiveValue );

/*
 * Registers an addon to the addons menu
 * 
 * @param		AddonName - Addon name
 * @param		Function - Function to be called when pressed
 * @param		PluginName - Plugin name that will be callbacked
 * 
 * @noreturn
 */
native DBM_RegisterMenuAddon( const AddonName[ ], const Function[ ], const PluginName[ ] );

/*
 * Returns the total amount of classes available
 * 
 * @return 		Total amount of classes
 */
native DBM_GetTotalClasses( );

/*
 * Returns the total amount of items available
 * 
 * @return 		Total amount of items
 */
native DBM_GetTotalItems( );

/*
 * Returns the total amount of quests available
 * 
 * @return 		Total amount of quests
 */
native DBM_GetTotalQuests( );

/*
 * Returns the class index from their class name
 * 
 * @param		Name - Class name
 *
 * @return 		Class index on success, -1 otherwise
 */
native DBM_GetIdFromClassName( const Name[ ] );

/*
 * Returns the item index from their item name
 * 
 * @param		Name - Item name
 *
 * @return 		Item index on success, -1 otherwise
 */
native DBM_GetIdFromItemName( const Name[ ] );

/*
 * Returns the quest index from their quest name
 * 
 * @param		Name - Quest name
 *
 * @return 		Quest index on success, -1 otherwise
 */
native DBM_GetIdFromQuestName( const Name[ ] );

/*
 * Returns the current class index of a client
 * 
 * @param		Client - Player index
 *
 * @return 		Returns Class Index
 */
native DBM_GetClientClass( const Client );

/*
 * Returns the name of the class
 * 
 * @param		ClassIndex - Pointer from the registration of the class
 * @param		Description - Name passed by reference
 * 
 * @return		Returns the name by reference (2nd param)
 */
native DBM_GetClassName( const ClassIndex, Name[ ] );

/*
 * Returns the description of the class
 * 
 * @param		ClassIndex - Pointer from the registration of the class
 * @param		Description - Description passed by reference
 * 
 * @return		Returns the description by reference (2nd param)
 */
native DBM_GetClassDesc( const ClassIndex, Description[ ] );

/*
 * Returns the ability name from the class structure
 * 
 * @param		ClassIndex - Pointer from the registration of the class
 * @param		SaveKey - Ability name by reference
 * 
 * @return		Returns the ability name by reference (2nd param)
 */
native DBM_GetClassAbilityName( const ClassIndex, AbilityName[ ] );

/*
 * Returns the player class current level
 * 
 * @param 		Client - Player index
 * @param		ClassIndex - Pointer from the registration of the class
 * 
 * @return		Returns the current class level of the client
 */
native DBM_GetClassLevel( const Client, const ClassIndex );

/*
 * Returns the player class current exp
 * 
 * @param 		Client - Player index
 * @param		ClassIndex - Pointer from the registration of the class
 * 
 * @return		Returns the current class exp of the client
 */
native DBM_GetClassExperience( const Client, const ClassIndex );

/*
 * Returns the player class current mana
 * 
 * @param 		Client - Player index
 * @param		ClassIndex - Pointer from the registration of the class
 * 
 * @return		Returns the current class mana of the client
 */
native DBM_GetClassMana( const Client, const ClassIndex );

/*
 * Sets the player class current level
 * 
 * @param 		Client - Player index
 * @param		ClassIndex - Pointer from the registration of the class
 * @param		Level - Level to be set
 * 
 * @noreturn
 */
native DBM_SetClassLevel( const Client, const ClassIndex, const Level );

/*
 * Sets the player class current exp
 * 
 * @param 		Client - Player index
 * @param		ClassIndex - Pointer from the registration of the class
 * @param 		Experience - Amount of exp to be set
 * 
 * @noreturn
 */
native DBM_SetClassExperience( const Client, const ClassIndex, const Experience );

/*
 * Sets the player class current mana
 * 
 * @param 		Client - Player index
 * @param		ClassIndex - Pointer from the registration of the class
 * @param 		Mana - Amount of mana to be set
 * 
 * @noreturn
 */
native DBM_SetClassMana( const Client, const ClassIndex, const Mana );

/*
 * Checks if the player has gained (a) level(s)
 * 
 * @param 		Client - Player index
 * @param		ClassIndex - Pointer from the registration of the class
 * 
 * @noreturn
 */
native DBM_CheckLevel( const Client, const ClassIndex );

/*
 * Sets the player's ability status
 * 
 * @param 		Client - Player index
 * @param		ClassIndex - Pointer from the registration of the class
 * @param 		Disabled - Bool if ability is disabled
 * 
 * @noreturn
 */
native DBM_SetClassAbility( const Client, const ClassIndex, bool:Disabled = false );

/*
 * Returns the current item index of a client
 * 
 * @param		Client - Player index
 *
 * @return 		Returns Item Index
 */
native DBM_GetClientItem( const Client );

/*
 * Returns the name of the item
 * 
 * @param		ItemIndex - Pointer from the registration of the item
 * @param		Description - Name passed by reference
 * 
 * @return		Returns the name by reference (2nd param)
 */
native DBM_GetItemName( const ItemIndex, Name[ ] );

/*
 * Returns the description of the item
 * 
 * @param		ItemIndex - Pointer from the registration of the item
 * @param		Description - Description passed by reference
 * 
 * @return		Returns the description by reference (2nd param)
 */
native DBM_GetItemDesc( const ItemIndex, Description[ ] );

/*
 * Returns the cost of the item
 * 
 * @param		ItemIndex - Pointer from the registration of the item
 * 
 * @return		Returns the cost
 */
native DBM_GetItemCost( const ItemIndex );

/*
 * Returns the stat of the item
 * 
 * @param		ItemIndex - Pointer from the registration of the item
 * 
 * @return		Returns the stat
 */
native DBM_GetItemStat( const ItemIndex );

/*
 * Gives an item to a player
 * 
 * @param 		Client - Player index
 * @param		ItemIndex - Pointer from the registration of the item
 * 
 * @forward		Forwards to Forward_DBM_ItemReceived
 */
native _DBM_GiveItem( const Client, const ItemIndex );

/*
 * Returns the name of the quest
 * 
 * @param		QuestIndex - Pointer from the registration of the quest
 * @param		Description - Name passed by reference
 * 
 * @return		Returns the name by reference (2nd param)
 */
native DBM_GetQuestName( const QuestIndex, Name[ ] );

/*
 * Returns the description of the quest
 * 
 * @param		QuestIndex - Pointer from the registration of the quest
 * @param		Description - Description passed by reference
 * 
 * @return		Returns the description by reference (2nd param)
 */
native DBM_GetQuestDesc( const QuestIndex, Description[ ] );

/*
 * Returns the objective value of the quest
 * 
 * @param		QuestIndex - Pointer from the registration of the quest
 * 
 * @return		Returns the objective value
 */
native DBM_GetQuestObjectiveVal( const QuestIndex );

/*
 * Returns the current player value of the quest
 * 
 * @param		QuestIndex - Pointer from the registration of the quest
 * @param 		Client - Player index
 * 
 * @return		Returns the current player value
 */
native DBM_GetQuestPlayerVal( const QuestIndex, const Client );

/*
 * Sets the player value of the quest
 * 
 * @param		QuestIndex - Pointer from the registration of the quest
 * @param 		Client - Player index
 * @param 		
 * 
 * @noreturn
 */
native DBM_SetQuestPlayerVal( const QuestIndex, const Client, const Value );

/*
 * Returns whether client has completed quest or not
 * 
 * @oaram		Client - Player index
 * @param		QuestIndex - Pointer from the registration of the quest
 * 
 * @return		1 if quest is completed, otherwise 0
 */
native DBM_GetQuestCompleted( const Client, const QuestIndex );

/*
 * Returns objective data for the specific quest
 * 
 * @oaram		Client - Player index
 * @param		QuestIndex - Pointer from the registration of the quest
 * 
 * @return		Objective Data of the quest
 */
native DBM_GetQuestData( const Client, const QuestIndex );

/*
 * Returns the number of quests client has completed
 * 
 * @oaram		Client - Player index
 * 
 * @return		Number of quests completed
 */
native DBM_GetQuestsCompleted( const Client );

/*
 * Sets quest completed on client
 * 
 * @oaram		Client - Player index
 * @param		QuestIndex - Pointer from the registration of the quest
 * @param 		Announce - Whether to announce or not (should not announce on connect)
 * 
 * @noreturn
 */
native DBM_SetQuestCompleted( const Client, const QuestIndex, bool:Announce = true );

/*
 * Saves the data for the set quest
 * 
 * @oaram		Client - Player index
 * @param		QuestIndex - Pointer from the registration of the quest
 * @param		Data - Data to assign to quest
 * 
 * @noreturn
 */
native DBM_SaveQuestData( const Client, const QuestIndex, const Data );

/*
 * Returns the current stat value (without boosts, see DBM_GetTotalStats or DBM_GetAdditionalStats)
 * 
 * @param 		Client - Player index
 * @param		Stat - Stat to retrieve
 *
 * @note 		enum _:StatStruct
 *				{
 *					_Stat_Intelligence,
 *					_Stat_Strength,
 *					_Stat_Dexterity,
 *					_Stat_Agility,
 *					_Stat_Regeneration
 *				};
 * 
 * @return		Returns a stat value
 */
native DBM_GetStat( const Client, const Stat );

/*
 * Returns the additional stat values
 * 
 * @param 		Client - Player index
 * @param		Stat - Stat to retrieve
 *
 * @note 		enum _:StatStruct
 *				{
 *					_Stat_Intelligence,
 *					_Stat_Strength,
 *					_Stat_Dexterity,
 *					_Stat_Agility,
 *					_Stat_Regeneration
 *				};
 * 
 * @return		Returns a stat value
 */
native DBM_GetAdditionalStat( const Client, const Stat );

/*
 * Returns the total stat value (including boosts)
 * 
 * @param 		Client - Player index
 * @param		Stat - Stat to retrieve
 *
 * @note 		enum _:StatStruct
 *				{
 *					_Stat_Intelligence,
 *					_Stat_Strength,
 *					_Stat_Dexterity,
 *					_Stat_Agility,
 *					_Stat_Regeneration
 *				};
 * 
 * @return		Returns a stat value
 */
native DBM_GetTotalStats( const Client, const Stat );

/*
 * Sets a stats additional boost value (original stats are always intact, this changes the stat in a non-direct way)
 * 
 * @param 		Client - Player index
 * @param		Stat - Stat to set
 * @param		Operator - 
 * @param 		Value - Value to add
 *
 * @note 		enum _:StatStruct
 *				{
 *					_Stat_Intelligence,
 *					_Stat_Strength,
 *					_Stat_Dexterity,
 *					_Stat_Agility,
 *					_Stat_Regeneration
 *				};
 *
 * @note 		enum _:StatOperators
 * 				{
 * 					_Stat_Increase,
 * 					_Stat_Decrease
 * 				};
 * 
 * @noreturn
 */
native DBM_StatBoost( const Client, const Stat, const Operator, const Value );

/*
 * Tells the core to ignore resetting knife deploy if class is equal to ClassName
 * 
 * @param 		ClassName - Class that should ignore deploy
 * 
 * @example 	See dbm_class_hunter.amxx (knife is replaced by a crossbow and core ignores knife resetting)
 * 
 * @noreturn
 */
native DBM_SetClassIgnoreDeploy( const ClassName[ ] );

/*
 * Returns true or false depending on if client is in current class change
 * 
 * @param 		Client - Player index
 * 
 * @return		True on in change, false if not
 */
native DBM_GetClientInClassChange( const Client );

/*
 * Displays Hud text in a predefined spot
 * 
 * @param 		Client - Player index
 * @param		HudText - Text to show
 * 
 * @noreturn
 */
native DBM_SkillHudText( const Client, const Float:HoldTime, HudText[ ], any:... );

/*
 * Returns whether freezetime is on
 * 
 * @noparams
 * 
 * @return		True if freezetime, false if not
 */
native bool:DBM_GetFreezetime( );

/* WILL ONLY FUNCTION IF GUILD ADDON IS LOADED
 * Returns clients guild index
 * 
 * @param 		Client - Player index
 * 
 * @return 		Returns guild index
 */
native DBM_GetClientGuild( const Client );

/* WILL ONLY FUNCTION IF GUILD ADDON IS LOADED
 * Sets client guild name
 * 
 * @param 		Client - Player index
 * @param 		Guild - Guild Name
 * 
 * @return 		Returns guild name by reference (2nd parameter)
 */
native DBM_GetGuildName( const GuildIndex, Guild[ ] );

/* WILL ONLY FUNCTION IF PETFOLLOWERS ADDON IS LOADED
 * Returns client pet name
 * 
 * @param 		Client - Player index
 * @param 		Pet - Pet Name
 * 
 * @return 		Returns pet name by reference (2nd parameter)
 */
native DBM_GetPetName( const Client, Pet[ ] );

/* WILL ONLY FUNCTION IF MONSTER ADDON IS LOADED
 * Returns whether current round is monster round
 * 
 * @noparams
 * 
 * @return		True if monster round, false if not
 */
native bool:DBM_IsMonsterRound( );

/*
 * Adds "Addition" to current experience multiplier
 * 
 * @param 		Client - Player index
 * @param 		Addition - Floated value to add
 * 
 * @noreturn
 */
native DBM_AddExperienceMultiplier( const Client, Float:Addition = 0.0 );

/*
 * Subtracts "Subtraction" from current experience multiplier
 * 
 * @param 		Client - Player index
 * @param 		Subtraction - Floated value to subtract
 * 
 * @noreturn
 */
native DBM_SubExperienceMultiplier( const Client, Float:Subtraction = 0.0 );

/*
 * Registers a command to the commandlist (in the core)
 * 
 * @param 		Command - Command to register
 * @param 		Function - Function to trigger
 * @param		Desc - Description of the command
 * 
 * @noreturn
 */
native DBM_RegisterCommandToList( const Command[ ], const Function[ ], const Desc[ ] );

/*
 * Retrieves party index of player
 * 
 * @param 		Client - Player index
 * 
 * @return		Party Index
 */
native DBM_GetClientParty( const Client );

/*
 * Checks if client is a member of PartyIndex
 * 
 * @param 		PartyIndex - Index of party to check if matched
 * @param 		Client - Player index
 * 
 * @return		True or false
 */
native DBM_IsClientInParty( const PartyIndex, const Client );

/*
 * Called when a player has recently selected a class
 * 
 * @param		Client - Index of player
 * @param 		ClassIndex - Pointer from the registration of the class
 * 
 * @noreturn
 */
forward Forward_DBM_ClassSelected( const Client, const ClassIndex );

/*
 * Called when a player has recently changed class
 * 
 * @param		Client - Index of player
 * @param 		ClassIndex - Pointer from the registration of the class
 * 
 * @noreturn
 */
forward Forward_DBM_ClassChanged( const Client, const ClassIndex );

/*
 * Called when a player has loaded his ability timer
 * 
 * @param		Client - Index of player
 * @param 		ClassIndex - Pointer from the registration of the class
 * 
 * @noreturn
 */
forward Forward_DBM_AbilityLoaded( const Client, const ClassIndex );

/*
 * Called when a player wants to use the class ability
 * 
 * @param		Client - Index of player
 * @param 		ClassIndex - Pointer from the registration of the class
 * 
 * @noreturn
 */
forward Forward_DBM_AbilityUse( const Client, const ClassIndex );

/*
 * Called when a player receives an item
 * 
 * @param		Client - Index of player
 * @param 		ItemIndex - Pointer from the registration of the item
 * 
 * @noreturn
 */
forward Forward_DBM_ItemReceived( const Client, const ItemIndex );

/*
 * Called when a player dispatches an item (drops, breaks.. etc)
 * 
 * @param		Client - Index of player
 * @param 		ItemIndex - Pointer from the registration of the item
 * 
 * @noreturn
 */
forward Forward_DBM_ItemDispatched( const Client, const ItemIndex );

/*
 * Called when a player uses the item
 * 
 * @param		Client - Index of player
 * @param 		ItemIndex - Pointer from the registration of the item
 * 
 * @noreturn
 */
forward Forward_DBM_ItemUse( const Client, const ItemIndex );

/*
 * Called when a player is spawned
 * 
 * @param		Client - Index of player
 * @param		ClassIndex - Class index
 * @param		CurrentLevel - The current level of players class
 *
 * @noreturn
 */
forward Forward_DBM_ClientLevelUp( const Client, const ClassIndex, const CurrentLevel );

/*
 * Called when a player is spawned
 * 
 * @param		Client - Index of player
 * @param 		ClassIndex - Class index
 *
 * @noreturn
 */
forward Forward_DBM_ClientSpawned( const Client, const ClassIndex );

/*
 * Called when a player is killed
 * 
 * @param		Client - Index of victim
 * @param 		Attacker - Index of attacker
 *
 * @noreturn
 */
forward Forward_DBM_ClientKilled( const Client, const Attacker );

/*
 * Called when a player is hurt
 * 
 * @param		Client - Index of victim
 * @param		Inflictor - Weapon index or entity index
 * @param		Attacker - Index of attacker
 * @param		Damage - Damage as floated value
 * @param		Damagebits - Bitsum of damage
 *
 * @note 		This forward cannot be blocked or altered, it was only made due to forwarding purposes
 *
 * @noreturn
 */
forward Forward_DBM_ClientHurt( const Client, const Inflictor, const Attacker, const Float:Damage, const Damagebits );

/*
 * Called when a player is done connecting and is authorized
 * 
 * @param		Client - Index of player
 *
 * @noreturn
 */
forward Forward_DBM_DelayConnect( const Client );