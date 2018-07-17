#include < amxmodx >
#include < dbm_api >

const TaskIdDelayedData = 9897;

enum _:QuestType
{
	_Plantage,
	_Defuser
};

new QuestPointer[ QuestType ];

new ObjectiveData[ MaxSlots + 1 ][ QuestType ];

new Planter;
new Defuser;

public plugin_init( )
{
	register_plugin( "Diablo Mod Quest: Plantage/Defuser", "0.0.1", "Xellath" );
	
	QuestPointer[ _Plantage ] = DBM_RegisterQuest( 
		"QUEST_PLANTAGE_NAME", 
		"QUEST_PLANTAGE_DESC", 
		"quest_plantage",
		50
		);
		
	QuestPointer[ _Defuser ] = DBM_RegisterQuest( 
		"QUEST_DEFUSER_NAME", 
		"QUEST_DEFUSER_DESC", 
		"quest_defuser",
		50
		);
	
	register_event( "SendAudio", "Event_SendAudio_BombDefuse", "a", "2&%!MRAD_BOMBDEF" );
	register_event( "BarTime", "Event_Bartime_Defusing", "be", "1=10", "1=5" );
	
	register_logevent( "LogEvent_BombPlanted", 3, "2=Planted_The_Bomb" );	
	register_event( "StatusIcon", "Event_StatusIcon_HasBomb", "be", "1=1", "1=2", "2=c4" );
}

public Forward_DBM_DelayConnect( const Client )
{
	ObjectiveData[ Client ][ _Plantage ] = DBM_GetQuestData( Client, QuestPointer[ _Plantage ] );
	DBM_SetQuestPlayerVal( QuestPointer[ _Plantage ], Client, ObjectiveData[ Client ][ _Plantage ] );
	
	if( ObjectiveData[ Client ][ _Plantage ] >= DBM_GetQuestObjectiveVal( QuestPointer[ _Plantage ] ) )
	{
		DBM_SetQuestCompleted( Client, QuestPointer[ _Plantage ], false );
	}
	
	set_task( 0.5, "TaskDelayedData", Client + TaskIdDelayedData );
}

public TaskDelayedData( TaskId )
{
	new Client = TaskId - TaskIdDelayedData;
	ObjectiveData[ Client ][ _Defuser ] = DBM_GetQuestData( Client, QuestPointer[ _Defuser ] );
	DBM_SetQuestPlayerVal( QuestPointer[ _Defuser ], Client, ObjectiveData[ Client ][ _Defuser ] );
	
	if( ObjectiveData[ Client ][ _Defuser ] >= DBM_GetQuestObjectiveVal( QuestPointer[ _Defuser ] ) )
	{
		DBM_SetQuestCompleted( Client, QuestPointer[ _Defuser ], false );
	}
}

public Event_StatusIcon_HasBomb( Client )
{ 
	Planter = Client;
} 

public LogEvent_BombPlanted( )
{
	if( is_user_connected( Planter ) 
	&& !DBM_GetQuestCompleted( Planter, QuestPointer[ _Plantage ] ) )
	{
		ObjectiveData[ Planter ][ _Plantage ]++;
		DBM_SetQuestPlayerVal( QuestPointer[ _Plantage ], Planter, ObjectiveData[ Planter ][ _Plantage ] );
		
		DBM_SaveQuestData( Planter, QuestPointer[ _Plantage ], ObjectiveData[ Planter ][ _Plantage ] );
		
		if( ObjectiveData[ Planter ][ _Plantage ] >= DBM_GetQuestObjectiveVal( QuestPointer[ _Plantage ] ) )
		{
			DBM_SetQuestCompleted( Planter, QuestPointer[ _Plantage ] );
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
	&& !DBM_GetQuestCompleted( Defuser, QuestPointer[ _Defuser ] ) )
	{
		ObjectiveData[ Defuser ][ _Defuser ]++;
		DBM_SetQuestPlayerVal( QuestPointer[ _Defuser ], Defuser, ObjectiveData[ Defuser ][ _Defuser ] );
		
		DBM_SaveQuestData( Defuser, QuestPointer[ _Defuser ], ObjectiveData[ Defuser ][ _Defuser ] );
		
		if( ObjectiveData[ Defuser ][ _Defuser ] >= DBM_GetQuestObjectiveVal( QuestPointer[ _Defuser ] ) )
		{
			DBM_SetQuestCompleted( Defuser, QuestPointer[ _Defuser ] );
		}
	}
}