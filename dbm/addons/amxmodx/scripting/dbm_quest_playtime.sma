#include < amxmodx >
#include < dbm_api >

const TaskIdDelayedData = 9794;

enum _:QuestHeir
{
	_20,
	_200,
	_500
};

new QuestPointer[ QuestHeir ];

new ObjectiveData[ MaxSlots + 1 ][ QuestHeir ];

public plugin_init( )
{
	register_plugin( "Diablo Mod Quest: Playtime", "0.0.1", "Xellath" );
	
	QuestPointer[ _20 ] = DBM_RegisterQuest( 
		"QUEST_20_HOURS_NAME", 
		"QUEST_20_HOURS_DESC", 
		"quest_20_hours",
		20
		);
		
	QuestPointer[ _200 ] = DBM_RegisterQuest( 
		"QUEST_200_HOURS_NAME", 
		"QUEST_200_HOURS_DESC", 
		"quest_200_hours",
		200
		);
		
	QuestPointer[ _500 ] = DBM_RegisterQuest( 
		"QUEST_500_HOURS_NAME", 
		"QUEST_500_HOURS_DESC", 
		"quest_500_hours", 
		500
		);
}

public Forward_DBM_DelayConnect( const Client )
{
	ObjectiveData[ Client ][ _20 ] = DBM_GetQuestData( Client, QuestPointer[ _20 ] );
	DBM_SetQuestPlayerVal( QuestPointer[ _20 ], Client, ObjectiveData[ Client ][ _20 ] );
	
	if( ObjectiveData[ Client ][ _20 ] >= DBM_GetQuestObjectiveVal( QuestPointer[ _20 ] ) )
	{
		DBM_SetQuestCompleted( Client, QuestPointer[ _20 ], false );
	}
	
	set_task( 0.5, "TaskDelayedData", Client + TaskIdDelayedData );
}

public TaskDelayedData( TaskId )
{
	new Client = TaskId - TaskIdDelayedData;
	ObjectiveData[ Client ][ _200 ] = DBM_GetQuestData( Client, QuestPointer[ _200 ] );
	DBM_SetQuestPlayerVal( QuestPointer[ _200 ], Client, ObjectiveData[ Client ][ _200 ] );
	
	if( ObjectiveData[ Client ][ _200 ] >= DBM_GetQuestObjectiveVal( QuestPointer[ _200 ] ) )
	{
		DBM_SetQuestCompleted( Client, QuestPointer[ _200 ], false );
	}
	
	set_task( 0.5, "TaskDelayedDataLast", Client + TaskIdDelayedData + 100 );
}

public TaskDelayedDataLast( TaskId )
{
	new Client = TaskId - TaskIdDelayedData - 100;
	ObjectiveData[ Client ][ _500 ] = DBM_GetQuestData( Client, QuestPointer[ _500 ] );
	DBM_SetQuestPlayerVal( QuestPointer[ _500 ], Client, ObjectiveData[ Client ][ _500 ] );
	
	if( ObjectiveData[ Client ][ _500 ] >= DBM_GetQuestObjectiveVal( QuestPointer[ _500 ] ) )
	{
		DBM_SetQuestCompleted( Client, QuestPointer[ _500 ], false );
	}
}

public client_disconnect( Client )
{
	for( new QuestIndex; QuestIndex < QuestHeir; QuestIndex++ )
	{
		if( !DBM_GetQuestCompleted( Client, QuestPointer[ QuestIndex ] ) )
		{
			ObjectiveData[ Client ][ QuestIndex ] += ( get_user_time( Client ) / 3600 );
			DBM_SetQuestPlayerVal( QuestPointer[ QuestIndex ], Client, ObjectiveData[ Client ][ QuestIndex ] );
			
			DBM_SaveQuestData( Client, QuestPointer[ QuestIndex ], ObjectiveData[ Client ][ QuestIndex ] );
			
			if( ObjectiveData[ Client ][ QuestIndex ] >= DBM_GetQuestObjectiveVal( QuestPointer[ QuestIndex ] ) )
			{
				DBM_SetQuestCompleted( Client, QuestPointer[ QuestIndex ] );
			}
		}
	}
}