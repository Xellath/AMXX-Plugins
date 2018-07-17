#if defined _achievement_api_included
    #endinput
#endif

#define _achievement_api_included

enum Status
{
	_In_Progress = 0,
	_Unlocked
};

/*
 * Registers an achievement
 * 
 * @param		Name - Achievement name
 * @param		Description - Description of objective to complete achievement
 * @param		SaveName - Save key that is used to set data
 * @param		MaxValue - Max value to complete achievement
 * 
 * @return 		Pointer to achievement
 */
native RegisterAchievement( const Name[ ], const Description[ ], const SaveName[ ], const MaxValue );

/*
 * Sets the current achievement status
 * 
 * @param		Client - Index of player
 * @param		AchievementPointer - Pointer from the registration of the achievement
 * @param		Announce - Whether to announce achievement earned or not (default: true)
 * 
 * @noreturn
 */
native ClientAchievementCompleted( const Client, AchievementPointer, bool:Announce = true );

/*
 * Gets the current achievement status
 * 
 * @param		AchievementPointer - Pointer from the registration of the achievement
 * @param		Objective - Client value to check whether its over max value or not
 * 
 * @return		Returns the current Status of achievement
 *
 * @note		enum Status
 *				{
 *					_In_Progress = 0,
 *					_Unlocked
 *				};
 */
native Status:GetClientAchievementStatus( AchievementPointer, Objective );

/*
 * Returns the name of the achievement
 * 
 * @param		AchievementPointer - Pointer from the registration of the achievement
 * @param		Description - Name passed by reference
 * 
 * @return		Returns the name by reference (2nd param)
 */
native GetAchievementName( AchievementPointer, Name[ ] );

/*
 * Returns the description of the achievement
 * 
 * @param		AchievementPointer - Pointer from the registration of the achievement
 * @param		Description - Description passed by reference
 * 
 * @return		Returns the description by reference (2nd param)
 */
native GetAchievementDesc( AchievementPointer, Description[ ] );

/*
 * Returns the save key that is required to complete achievement
 * 
 * @param		AchievementPointer - Pointer from the registration of the achievement
 * @param		SaveKey - Key passed by reference
 * 
 * @return		Returns the save key by reference (2nd param)
 */
native GetAchievementSaveKey( AchievementPointer, SaveKey[ ] );

/*
 * Returns the max value that is required to complete achievement
 * 
 * @param		AchievementPointer - Pointer from the registration of the achievement
 * 
 * @return		Returns the max value that is required to complete achievement
 */
native GetAchievementMaxValue( AchievementPointer );

/*
 * Returns the total number of achievements client has completed
 * 
 * @param		Client - Index of player
 * 
 * @return		Returns the total number of achievements client has completed
 */
native GetClientAchievementsCompleted( const Client );

/*
 * Returns the total number of achievements
 * 
 * @noparams
 * 
 * @return		Returns the total number of achievements
 */
native GetMaxAchievements( );

/*
 * Assign an integer value to Key in database/vault
 * 
 * @param		Key - Key to where to set data (mainly used as steamid)
 * @param		SaveName - Save name used in the init of an achievement (RegisterAchievement() param 4)
 * @param		Data - Integer value assigned to Key
 * 
 * @noreturn
 */
native SetAchievementData( const Key[ ], const SaveName[ ], Data );

/*
 * Gets an integer value from database/vault
 * 
 * @param		Key - Key to where to look for data (mainly used as steamid)
 * @param		SaveName - Save name used in the init of an achievement (RegisterAchievement() param 4)
 * 
 * @return		Returns the value on success, 0 on failure to get data (and if there is no progress)
 */
native GetAchievementData( const Key[ ], const SaveName[ ] );

/*
 * Called when a player has recently earned an achievement
 * 
 * @param		AchiPointer - Pointer to achievement
 * @param		Client - Index of player
 * 
 * @noreturn
 * 
 */
forward Forward_ClientEarnedAchievement( const AchiPointer, const Client );