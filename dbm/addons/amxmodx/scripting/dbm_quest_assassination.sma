#include < amxmodx >
#include < cstrike >
#include < dbm_api >

new QuestPointer;

new ObjectiveData[ MaxSlots + 1 ];

new ClassId;

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Quest: Assassination", "0.0.1", "Xellath" );
	
	QuestPointer = DBM_RegisterQuest( 
		"QUEST_ASSASSINATION_NAME", 
		"QUEST_ASSASSINATION_DESC", 
		"quest_assassination",
		20
		);
		
	ClassId = DBM_GetIdFromClassName( "CLASS_ASSASSIN_NAME" );	
	
	register_event( "DeathMsg", "Event_DeathMsg", "a" );
	
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

public Event_DeathMsg( )
{
	new Attacker = read_data( 1 );
	new Victim = read_data( 2 );
	
	if( 1 <= Attacker <= MaxPlayers
	&& 1 <= Victim <= MaxPlayers
	&& Victim != Attacker
	&& is_user_connected( Victim ) 
	&& is_user_connected( Attacker )
	&& cs_get_user_team( Victim ) != cs_get_user_team( Attacker )
	&& DBM_GetClientClass( Victim ) == ClassId
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