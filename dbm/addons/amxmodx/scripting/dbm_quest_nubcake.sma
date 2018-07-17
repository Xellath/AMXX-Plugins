#include < amxmodx >
#include < hamsandwich >
#include < dbm_api >

new QuestPointer;

new ObjectiveData[ MaxSlots + 1 ];

public plugin_init( )
{
	register_plugin( "Diablo Mod Quest: Nubcake!", "0.0.1", "Xellath" );
	
	QuestPointer = DBM_RegisterQuest( 
		"QUEST_NUBCAKE_NAME", 
		"QUEST_NUBCAKE_DESC", 
		"quest_nubcake",
		10
		);
	
	RegisterHam( Ham_Killed, "player", "Forward_Ham_ClientKilled" );
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

public Forward_Ham_ClientKilled( Client, Killer, ShouldGib )
{
	if( is_user_connected( Client )
	&& !DBM_GetQuestCompleted( Client, QuestPointer ) )
	{
		ObjectiveData[ Client ]++;
		DBM_SetQuestPlayerVal( QuestPointer, Client, ObjectiveData[ Client ] );
		
		DBM_SaveQuestData( Client, QuestPointer, ObjectiveData[ Client ] );
		
		if( ObjectiveData[ Client ] >= DBM_GetQuestObjectiveVal( QuestPointer ) )
		{
			DBM_SetQuestCompleted( Client, QuestPointer );
		}
	}
}