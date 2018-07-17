#include < amxmodx >
#include < cstrike >
#include < dbm_api >

const TaskIdDelayedData = 9997;

enum _:QuestHeir
{
	_500,
	_5000,
};

new QuestPointer[ QuestHeir ];

new ObjectiveData[ MaxSlots + 1 ][ QuestHeir ];

new MaxPlayers;

public plugin_init( )
{
	register_plugin( "Diablo Mod Quest: 500 + 5000 Player Kills", "0.0.1", "Xellath" );
	
	QuestPointer[ _500 ] = DBM_RegisterQuest( 
		"QUEST_500_NAME", 
		"QUEST_500_DESC", 
		"quest_500_kills",
		500
		);
		
	QuestPointer[ _5000 ] = DBM_RegisterQuest( 
		"QUEST_5000_NAME", 
		"QUEST_5000_DESC", 
		"quest_5000_kills",
		5000
		);
	
	register_event( "DeathMsg", "Event_DeathMsg", "a" );
	
	MaxPlayers = get_maxplayers( );
}

public Forward_DBM_DelayConnect( const Client )
{
	ObjectiveData[ Client ][ _500 ] = DBM_GetQuestData( Client, QuestPointer[ _500 ] );
	DBM_SetQuestPlayerVal( QuestPointer[ _500 ], Client, ObjectiveData[ Client ][ _500 ] );
	
	if( ObjectiveData[ Client ][ _500 ] >= DBM_GetQuestObjectiveVal( QuestPointer[ _500 ] ) )
	{
		DBM_SetQuestCompleted( Client, QuestPointer[ _500 ], false );
	}
	
	set_task( 0.5, "TaskDelayedData", Client + TaskIdDelayedData );
}

public TaskDelayedData( TaskId )
{
	new Client = TaskId - TaskIdDelayedData;
	ObjectiveData[ Client ][ _5000 ] = DBM_GetQuestData( Client, QuestPointer[ _5000 ] );
	DBM_SetQuestPlayerVal( QuestPointer[ _5000 ], Client, ObjectiveData[ Client ][ _5000 ] );
	
	if( ObjectiveData[ Client ][ _5000 ] >= DBM_GetQuestObjectiveVal( QuestPointer[ _5000 ] ) )
	{
		DBM_SetQuestCompleted( Client, QuestPointer[ _5000 ], false );
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
	&& cs_get_user_team( Victim ) != cs_get_user_team( Attacker ) )
	{
		for( new QuestIndex; QuestIndex < QuestHeir; QuestIndex++ )
		{
			if( !DBM_GetQuestCompleted( Attacker, QuestPointer[ QuestIndex ] ) )
			{
				ObjectiveData[ Attacker ][ QuestIndex ]++;
				DBM_SetQuestPlayerVal( QuestPointer[ QuestIndex ], Attacker, ObjectiveData[ Attacker ][ QuestIndex ] );
				
				DBM_SaveQuestData( Attacker, QuestPointer[ QuestIndex ], ObjectiveData[ Attacker ][ QuestIndex ] );
				
				if( ObjectiveData[ Attacker ][ QuestIndex ] >= DBM_GetQuestObjectiveVal( QuestPointer[ QuestIndex ] ) )
				{
					DBM_SetQuestCompleted( Attacker, QuestPointer[ QuestIndex ] );
				}
			}
		}
	}
}