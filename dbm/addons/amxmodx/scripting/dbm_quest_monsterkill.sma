#include < amxmodx >
#include < hamsandwich >
#include < engine >
#include < dbm_api >

new QuestPointer;

new ObjectiveData[ MaxSlots + 1 ];

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Quest: MMMMMONSTERKILLLL", "0.0.1", "Xellath" );
	
	QuestPointer = DBM_RegisterQuest( 
		"QUEST_MONSTERKILL_NAME", 
		"QUEST_MONSTERKILL_DESC", 
		"quest_monsterkill",
		50
		);
	
	RegisterHam( Ham_Killed, "func_wall", "Forward_Ham_MonsterKilled" );
	
	MaxPlayers = get_maxplayers( );
}

public Forward_DBM_DelayConnect( const Client )
{
	ObjectiveData[ Client ] = DBM_GetQuestData( Client, QuestPointer );
	DBM_SetQuestPlayerVal( QuestPointer, Client, ObjectiveData[ Client ] );
	
	if( ObjectiveData[ Client ] >= DBM_GetQuestObjectiveVal( QuestPointer ) )
	{
		DBM_SetQuestCompleted( Client, QuestPointer, false );
	}
}

public Forward_Ham_MonsterKilled( Entity, Attacker, ShouldGib )
{
	if( 1 <= Attacker <= MaxPlayers 
	&& is_user_connected( Attacker )
	&& is_valid_ent( Entity )
	&& ( entity_get_int( Entity, EV_INT_flags ) & FL_MONSTER )
	&& !DBM_GetQuestCompleted( Attacker, QuestPointer ) )
	{
		ObjectiveData[ Attacker ]++;
		DBM_SetQuestPlayerVal( QuestPointer, Attacker, ObjectiveData[ Attacker ] );
		
		DBM_SaveQuestData( Attacker, QuestPointer, ObjectiveData[ Attacker ] );
		
		if( ObjectiveData[ Attacker ] >= DBM_GetQuestObjectiveVal( QuestPointer ) )
		{
			DBM_SetQuestCompleted( Attacker, QuestPointer );
		}
	}
}