#include < amxmodx >
#include < cstrike >

// team names
// CS_TEAM_UNASSIGNED
// CS_TEAM_T
// CS_TEAM_CT
// CS_TEAM_SPECTATOR
new const TeamNames[ CsTeams ][ ] =
{
    "",
    "Terrorist",
    "Counter-Terrorist",
    ""
};

// variable holding the current round
new CurrentRound;

// bool whether it's the 15th round or not
new bool:LastRound;

// current team round count
new RoundsWon[ CsTeams ];

// holding get_maxplayers( ) value
new MaxPlayers;

public plugin_init( )
{
    register_clcmd( "say /score", "ClientCommand_Score" );

    register_clcmd( "live", "ClientCommand_Live" );
    register_clcmd( "warmup", "ClientCommand_Warmup" );

    // hook round start
    register_logevent( "LogEvent_RoundStart", 2, "1=Round_Start" );

    // hook round win
    register_event( "SendAudio", "Event_SendAudio_TWin", "a", "2&%!MRAD_terwin" );
    register_event( "SendAudio", "Event_SendAudio_CTWin", "a", "2&%!MRAD_ctwin" );

    // assign MaxPlayers the value of get_maxplayers( )
    MaxPlayers = get_maxplayers( );

    state warmup;
}

public ClientCommand_Score( Client ) <warmup>
{
    // print score (in this case warmup doesn't have any scores.. so print a message)
    client_print( Client, print_chat, "Game mode is currently in Warmup mode - no scores available!" );
}

public ClientCommand_Score( Client ) <live>
{
    // print score
    client_print( Client, print_chat, "CT Score: %i T Score: %i", RoundsWon[ CS_TEAM_CT ], RoundsWon[ CS_TEAM_T ] );
}

public ClientCommand_Live( Client )
{
    // switch state to live
    state live;

    RoundsWon[ CS_TEAM_CT ] = 0;
    RoundsWon[ CS_TEAM_T ] = 0;

    Reset( );
}

public ClientCommand_Warmup( Client )
{
    // switch state to warmup
    state warmup;

    Reset( );
}

public LogEvent_RoundStart( ) <warmup>
{
    // print every warmup round
    client_print( 0, print_chat, "Warmup Round", RoundsWon[ CS_TEAM_CT ], RoundsWon[ CS_TEAM_T ] );
}

public LogEvent_RoundStart( ) <live>
{
    // increment round counter
    CurrentRound++;

    client_print( 0, print_chat, "CT Score: %i T Score: %i", RoundsWon[ CS_TEAM_CT ], RoundsWon[ CS_TEAM_T ] );

    // check if rounds == 15, if so, set last true (will be handled when round is won by a team)
    if( CurrentRound == 15 )
    {
        client_print( 0, print_chat, "This is the last round before switching teams!" );

        LastRound = true;
    }
}

public Event_SendAudio_TWin( ) <warmup> { }
public Event_SendAudio_TWin( ) <live>
{
    // increment the team round counter for T team
    RoundsWon[ CS_TEAM_T ]++;

    // check if they have 16 rounds in the bag
    CheckWinner( CS_TEAM_T );

    // if it's the 15th round, reset the round counter, and swap team scores
    if( LastRound )
    {
        Reset( );

        Swap( );
    }
}

public Event_SendAudio_CTWin( ) <warmup> { }
public Event_SendAudio_CTWin( ) <live>
{
    // increment the team round counter for CT team
    RoundsWon[ CS_TEAM_CT ]++;

    // check if they have 16 rounds in the bag
    CheckWinner( CS_TEAM_CT );

    // if it's the 15th round, reset the round counter, and swap team scores
    if( LastRound )
    {
        Reset( );

        Swap( );
    }
}

CheckWinner( CsTeams:Team )
{
    // check if team has won 15 rounds
    if( RoundsWon[ Team ] == 15 )
    {
        client_print( 0, print_chat, "%s team has won 15 rounds now - they're only one away from winning!", TeamNames[ Team ] );
    }
    // check if team has won 16 rounds
    else if( RoundsWon[ Team ] == 16 )
    {
        client_print( 0, print_chat, "%s team has won 16 rounds now, resetting!", TeamNames[ Team ] );

        // reset
        Reset( true );
    }
}

Reset( bool:TeamWon = false )
{
    // check if a teamwon is true (false by default), if so (see comment below)
    if( TeamWon )
    {
        // reset rounds for terrorists and cts
        for( new CsTeams:Team = CS_TEAM_T; Team <= CS_TEAM_CT; Team++ )
        {
            RoundsWon[ Team ] = 0;
        }
    }

    // set round counter to 0
    CurrentRound = 0;

    // restart round
    server_cmd( "sv_restartround 1" );

    // set last round false
    LastRound = false;
}

Swap( )
{
    // iterate through all players
    for( new PlayerIndex = 1; PlayerIndex <= MaxPlayers; PlayerIndex++ )
    {
        // check if connected
        if( is_user_connected( PlayerIndex ) )
        {
            // swap team
            switch( cs_get_user_team( PlayerIndex ) )
            {
                case CS_TEAM_T: cs_set_user_team( PlayerIndex, CS_TEAM_CT );
                case CS_TEAM_CT: cs_set_user_team( PlayerIndex, CS_TEAM_T );
            }
        }
    }

    // swap scores
    new TempScore = RoundsWon[ CS_TEAM_T ];
    RoundsWon[ CS_TEAM_T ] = RoundsWon[ CS_TEAM_CT ];
    RoundsWon[ CS_TEAM_CT ] = TempScore;
}
