#include < amxmodx >
#include < cstrike >
#include < csx >
#include < dbm_api >

new QuestPointer;

new ObjectiveData[ MaxSlots + 1 ];

new ClassId;

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Quest: Fire it up!", "0.0.1", "Xellath" );
	
	QuestPointer = DBM_RegisterQuest( 
		"QUEST_FIRE_NAME", 
		"QUEST_FIRE_DESC", 
		"quest_fireup",
		20
		);
	
	ClassId = DBM_GetIdFromClassName( "CLASS_MAGE_NAME" );
	
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

public client_death( Killer, Victim, WeaponIndex, Hitplace, TeamKill )
{
	if( 1 <= Killer <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& Victim != Killer
	&& is_user_connected( Victim ) 
	&& is_user_connected( Killer )
	&& cs_get_user_team( Victim ) != cs_get_user_team( Killer )
	&& DBM_GetClientClass( Victim ) == ClassId
	&& !DBM_GetQuestCompleted( Killer, QuestPointer )
	&& WeaponIndex == CSW_HEGRENADE )
	{
		ObjectiveData[ Killer ]++;
		DBM_SetQuestPlayerVal( QuestPointer, Killer, ObjectiveData[ Killer ] );
		
		DBM_SaveQuestData( Killer, QuestPointer, ObjectiveData[ Killer ] );
		
		if( ObjectiveData[ Killer ] >= DBM_GetQuestObjectiveVal( QuestPointer ) )
		{
			DBM_SetQuestCompleted( Killer, QuestPointer );
		}
	}
}