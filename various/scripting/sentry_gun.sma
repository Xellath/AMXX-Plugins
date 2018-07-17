#include < amxmodx >
#include < cstrike >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < xs >

#define FindAliveEnemy(%1,%2) ( ( 1 <= %1 <= g_iMaxPlayers ) && is_user_alive( %1 ) && ( cs_get_user_team( %1 ) != cs_get_user_team( %2 ) ) )

const MaxSlots = 32;
const MaxHitboxes = 8;

const VectorSize = 3;

const m_pPlayer = 41;
const XTRA_LINUX_OFFS = 4;

enum _:_Edict
{
    _Player = 0,
    _Entity
};

new Float:g_flLastTime[ MaxSlots + 1 ];
new Float:g_flCooldown[ MaxSlots + 1 ];
new bool:g_bUsing[ MaxSlots + 1 ];

new g_szSound[ ] = "weapons/m249-1.wav";
new g_szClassName[ ] = "cl_sentry_base";
new g_szBaseModel[ ] = "models/base.mdl";
new g_szSentryModel[ ] = "models/sentry1.mdl"; // 1,2,3

new g_iMaxPlayers;
new g_szSprSmoke, g_szSprBlood, g_szSprBloodspray;

new const Float:g_flDamageMultiplier[ MaxHitboxes ] =
{
    0.8,
    1.45,
    0.80,
    0.95,
    0.5,
    0.5,
    0.35,
    0.35
};

public plugin_init( )
{
    register_plugin( "Sentry API", "0.2", "diablix" ); // Optimized and revised by Xellath

    g_iMaxPlayers = get_maxplayers( );

    RegisterHam( Ham_Spawn, "player", "Forward_Ham_ClientSpawn_Post", 1 );
    RegisterHam( Ham_Killed, "player", "Forward_Ham_ClientKilled_Pre" );

    register_logevent( "LogEvent_RoundEnd", 2, "1=Round_End" );

    register_forward( FM_CmdStart, "Forward_FM_CmdStart_Pre" );

    register_forward( FM_Think, "Forward_FM_SentryThink_Pre" );

    new szWeaponName[ MaxSlots ];
    for( new iWeaponIndex = CSW_P228; iWeaponIndex <= CSW_P90; iWeaponIndex++ )
    {
        if( iWeaponIndex != 2 )
        {
            get_weaponname( iWeaponIndex, szWeaponName, charsmax( szWeaponName ) );

            RegisterHam( Ham_Weapon_PrimaryAttack, szWeaponName, "Forward_Ham_PrimaryAttack_Pre" );
        }
    }
}

public Forward_Ham_ClientSpawn_Post( id )
{
    g_bUsing[ id ] = false;
}

public Forward_Ham_ClientKilled_Pre( id, iKiller, iShouldGib )
{
    g_bUsing[ id ] = false;
}

public Forward_Ham_PrimaryAttack_Pre( iEntity )
{
    new id = get_pdata_cbase( iEntity, m_pPlayer, XTRA_LINUX_OFFS );

    if( g_bUsing[ id ] )
    {
        return HAM_SUPERCEDE;
    }

    return HAM_IGNORED;
}

public LogEvent_RoundEnd( )
{
    new iEntity = FM_NULLENT;
    while( ( iEntity = find_ent_by_class( iEntity, g_szClassName ) ) )
    {
        new iOwner = entity_get_edict( iEntity, EV_ENT_owner );
        entity_set_edict( iOwner, EV_ENT_owner, 0 );
        entity_set_edict( iEntity, EV_ENT_owner, 0 );

        new iBase = entity_get_int( iEntity, EV_INT_iuser1 );
        remove_entity( iBase );
        remove_entity( iEntity );
    }

    arrayset( g_bUsing, false, 33 );
}

public plugin_precache( )
{
    g_szSprSmoke      = precache_model( "sprites/steam1.spr" );
    g_szSprBlood      = precache_model( "sprites/blood.spr" );
    g_szSprBloodspray = precache_model( "sprites/bloodspray.spr" );

    precache_sound( g_szSound );

    precache_model( g_szBaseModel );
    precache_model( g_szSentryModel );

    precache_sound( "debris/bustconcrete0.wav" );
    precache_sound( "debris/bustconcrete1.wav" );
    precache_sound( "debris/bustconcrete2.wav" );
    precache_sound( "debris/bustconcrete3.wav" );
    precache_sound( "debris/concrete0.wav" );
    precache_sound( "debris/concrete1.wav" );
    precache_sound( "debris/concrete2.wav" );
    precache_sound( "debris/concrete3.wav" );

    precache_model( "models/cindergibs.mdl" );
}

public plugin_natives( )
{
    register_library( "Diablix's Lib" );

    register_native( "diablix_create_cannon", "native_create_cannon" );
}

public client_PreThink( id )
{
    if( g_bUsing[ id ] )
    {
        entity_set_vector( id, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } );
    }
}

public Forward_FM_CmdStart_Pre( id, hHandle )
{
    if( !is_user_alive( id ) )
    {
        return FMRES_IGNORED;
    }

    new iButtons = get_uc( hHandle, UC_Buttons );
    new iOldbuttons = entity_get_int( id, EV_INT_oldbuttons );

    new iEntity = entity_get_edict( id, EV_ENT_owner );
    if( iEntity && is_valid_ent( iEntity ) )
    {
        new iOwner = entity_get_edict( iEntity, EV_ENT_owner );
        if( iOwner == id )
        {
            new Float:flOrigin[ _Edict ][ VectorSize ];
            entity_get_vector( id, EV_VEC_origin, flOrigin[ _Player ] );
            entity_get_vector( iEntity, EV_VEC_origin, flOrigin[ _Entity ] );

            if( ( get_distance_f( flOrigin[ _Player ], flOrigin[ _Entity ] ) <= 85.0 ) && ( entity_get_int( id, EV_INT_flags ) & FL_ONGROUND ) )
            {
                set_hudmessage( g_bUsing[ id ] ? 255 : 0, g_bUsing[ id ] ? 0 : 255, 0, 0.42, 0.55, 1, 0.1, 0.1, 0.1, 0.1 );
                show_hudmessage( id, "Press E to %s sentry^nCooldown: %.1f", ( g_bUsing[ id ] ? "deactivate the" : "use the" ), ( ( g_flCooldown[ id ] - get_gametime( ) < 0.0 ) ? 0.0 : ( g_flCooldown[ id ] - get_gametime( ) ) ) );

                if( ( iButtons & IN_USE ) && !( iOldbuttons & IN_USE ) )
                {
                    g_bUsing[ id ] = !g_bUsing[ id ];
                }

                if( g_bUsing[ id ] && ( iButtons & IN_ATTACK ) )
                {
                    new Float:flCooldown = entity_get_float( iEntity, EV_FL_fuser4 );
                    if( ( get_gametime( ) - g_flLastTime[ id ] ) >= flCooldown )
                    {
                        new iAimOrigin[ VectorSize ], Float:flAimOrigin[ VectorSize ];
                        get_user_origin( id, iAimOrigin, 3 );
                        IVecFVec( iAimOrigin, flAimOrigin );

                        entity_get_vector( iEntity, EV_VEC_origin, flOrigin[ _Entity ] );
                        flOrigin[ _Entity ][ 2 ] += 31.5;

                        message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
                        {
                            write_byte( TE_TRACER );
                            write_coord( floatround( flOrigin[ _Entity ][ 0 ] ) );
                            write_coord( floatround( flOrigin[ _Entity ][ 1 ] ) );
                            write_coord( floatround( flOrigin[ _Entity ][ 2 ] ) );
                            write_coord( iAimOrigin[ 0 ] );
                            write_coord( iAimOrigin[ 1 ] );
                            write_coord( iAimOrigin[ 2 ] );
                        }
                        message_end( );

                        flOrigin[ _Entity ][ 2 ] -= 7.5;

                        message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
                        {
                            write_byte( TE_SMOKE );
                            write_coord( floatround( flOrigin[ _Entity ][ 0 ] ) );
                            write_coord( floatround( flOrigin[ _Entity ][ 1 ] ) );
                            write_coord( floatround( flOrigin[ _Entity ][ 2 ] ) );
                            write_short( g_szSprSmoke );
                            write_byte( 10 );
                            write_byte( 6 );
                        }
                        message_end( );

                        message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
                        {
                            write_byte( TE_ARMOR_RICOCHET );
                            write_coord( iAimOrigin[ 0 ] );
                            write_coord( iAimOrigin[ 1 ] );
                            write_coord( iAimOrigin[ 2 ] );
                            write_byte( 12 );
                        }
                        message_end( );

                        emit_sound( iEntity, CHAN_STATIC, g_szSound, 0.35, ATTN_NORM, 0, PITCH_NORM );

                        new Float:flViewOfs[ VectorSize ], Float:flEnd[ VectorSize ];
                        entity_get_vector( id, EV_VEC_origin, flOrigin[ _Player ] );
                        entity_get_vector( id, EV_VEC_view_ofs, flViewOfs );

                        xs_vec_add( flOrigin[ _Player ], flViewOfs, flOrigin[ _Player ] );

                        entity_get_vector( id, EV_VEC_v_angle, flEnd );
                        angle_vector( flEnd, ANGLEVECTOR_FORWARD, flEnd );

                        xs_vec_mul_scalar( flEnd, 999.0, flEnd );

                        xs_vec_add( flOrigin[ _Player ], flEnd, flEnd );

                        new iTrace = create_tr2( );
                        engfunc( EngFunc_TraceLine, flOrigin[ _Player ], flEnd, 0, id, iTrace );

                        new iHit = get_tr2( iTrace, TR_pHit );
                        if( FindAliveEnemy( iHit, id ) )
                        {
                            new iHitbox = get_tr2( iTrace, TR_iHitgroup );

                            message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
                            {
                                write_byte( TE_BLOODSPRITE );
                                write_coord( iAimOrigin[ 0 ] );
                                write_coord( iAimOrigin[ 1 ] );
                                write_coord( iAimOrigin[ 2 ] );
                                write_short( g_szSprBloodspray );
                                write_short( g_szSprBlood );
                                write_byte( 248 );
                                write_byte( floatround( g_flDamageMultiplier[ iHitbox ] * 13 ) );
                            }
                            message_end( );

                            new iDamage = entity_get_int( iEntity, EV_INT_iuser2 );
                            ExecuteHam( Ham_TakeDamage, iHit, iEntity, iOwner, ( iDamage * g_flDamageMultiplier[ iHitbox ] ), ( 1 << 9^5 ) );

                            free_tr2( iTrace );
                        }

                        g_flLastTime[ id ] = get_gametime( );
                        g_flCooldown[ id ] = g_flLastTime[ id ] + flCooldown;
                    }
                }
            }
            else
            {
                g_bUsing[ id ] = g_bUsing[ id ] ? !g_bUsing[ id ] : g_bUsing[ id ];
            }
        }
    }

    return FMRES_IGNORED;
}

public Forward_FM_SentryThink_Pre( iEntity )
{
    if( !is_valid_ent( iEntity ) )
    {
        return FMRES_IGNORED;
    }

    new szClassName[ MaxSlots ];
    entity_get_string( iEntity, EV_SZ_classname, szClassName, charsmax( szClassName ) );
    if( equal( szClassName, g_szClassName ) )
    {
        new iOwner = entity_get_edict( iEntity, EV_ENT_owner );

        new szModel[ MaxSlots ];
        entity_get_string( iEntity, EV_SZ_model, szModel, charsmax( szModel ) );
        if( equal( szModel, g_szSentryModel ) && iOwner )
        {
            if( g_bUsing[ iOwner ] )
            {
                new iAimOrigin[ VectorSize ], Float:flAimOrigin[ VectorSize ];
                get_user_origin( iOwner, iAimOrigin, 3 );
                IVecFVec( iAimOrigin, flAimOrigin );

                FixAngle( iEntity, flAimOrigin );
            }

            new Float:flHealth = entity_get_float( iEntity, EV_FL_health );
            if( floatround( flHealth ) <= 0 )
            {
                g_bUsing[ iOwner ] = false;

                entity_set_edict( iOwner, EV_ENT_owner, 0 );
                entity_set_edict( iEntity, EV_ENT_owner, 0 );

                new iBase = entity_get_int( iEntity, EV_INT_iuser1 );
                remove_entity( iBase );
                remove_entity( iEntity );
            }
            else
            {
                entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 0.01 );
            }
        }
    }

    return FMRES_IGNORED;
}

public native_create_cannon( iPlugin, iParams )
{
    if( iParams != 4 )
    {
        return -1;
    }

    new id                         = get_param( 1 );
    new iHealth                 = get_param( 2 );
    new iDamage                 = get_param( 3 );
    new Float:flCooldown        = get_param_f( 4 );

    if( g_bUsing[ id ] )
    {
        g_bUsing[ id ] = !g_bUsing[ id ];
    }

    new iOrigin[ VectorSize ], Float:flOrigin[ VectorSize ];
    get_user_origin( id, iOrigin, 3 );
    IVecFVec( iOrigin, flOrigin );

    new iBase = create_entity( "info_target" );

    //DispatchKeyValue( iBase, "health", szHealth );
    //DispatchKeyValue( iBase, "material", "4" );

    //DispatchSpawn( iBase );

    //entity_set_string( iBase, EV_SZ_classname, g_szClassName );
    entity_set_model( iBase, g_szBaseModel );

    new Float:flSizeMin[ VectorSize ] = { -17.1, -21.4, -27.0 };
    new Float:flSizeMax[ VectorSize ] = { 17.1, 9.6, 21.5 };
    entity_set_size( iBase, flSizeMin, flSizeMax );

    entity_set_origin( iBase, flOrigin );
    entity_set_vector( iBase, EV_VEC_angles, Float:{ 0.0, 0.0, 0.0 } );

    entity_set_int( iBase, EV_INT_solid, SOLID_BBOX );
    entity_set_int( iBase, EV_INT_movetype, MOVETYPE_NONE );

    //entity_set_edict( iBase, EV_ENT_owner, id );
    //entity_set_edict( id, EV_ENT_owner, iBase );

    //entity_set_float( iBase, EV_FL_takedamage, DAMAGE_YES );

    //entity_set_float( iBase, EV_FL_nextthink, get_gametime( ) + 0.3 );

    CreateSentry( id, iBase, flOrigin, iHealth, iDamage, flCooldown );

    return is_valid_ent( iBase );
}

CreateSentry( id, iBase, Float:flOrigin[ VectorSize ], iHealth, iDamage, Float:flCooldown )
{
    new iSentry = create_entity( "func_breakable" );

    new szHealth[ 10 ];
    num_to_str( iHealth, szHealth, charsmax( szHealth ) );

    DispatchKeyValue( iSentry, "health", szHealth );
    DispatchKeyValue( iSentry, "material", "4" );

    DispatchSpawn( iSentry );

    entity_set_string( iSentry, EV_SZ_classname, g_szClassName );
    entity_set_model( iSentry, g_szSentryModel );

    new Float:flSizeMin[ VectorSize ] = { -28.3, -13.9, -10.4 };
    new Float:flSizeMax[ VectorSize ] = { 30.8, 33.9, 36.7 };
    entity_set_size( iSentry, flSizeMin, flSizeMax );

    flOrigin[ 2 ] += 13.5;
    entity_set_origin( iSentry, flOrigin );
    entity_set_vector( iSentry, EV_VEC_angles, Float:{ 0.0, 0.0, 0.0 } );

    entity_set_int( iSentry, EV_INT_solid, SOLID_SLIDEBOX );
    entity_set_int( iSentry, EV_INT_movetype, MOVETYPE_TOSS );

    entity_set_edict( iSentry, EV_ENT_owner, id );
    entity_set_edict( id, EV_ENT_owner, iSentry );

    entity_set_float( iSentry, EV_FL_takedamage, DAMAGE_YES );

    entity_set_int( iSentry, EV_INT_iuser1, iBase );
    entity_set_int( iSentry, EV_INT_iuser2, iDamage );
    entity_set_float( iSentry, EV_FL_fuser4, flCooldown );

    entity_set_float( iSentry, EV_FL_nextthink, get_gametime( ) + 0.1 );

    return is_valid_ent( iSentry );
}

FixAngle( iEntity, const Float:flOrigin_[ VectorSize ] )
{
    new Float:flOrigin[ VectorSize ], Float:flEntOrigin[ VectorSize ], Float:flLength, Float:flAimVector[ VectorSize ], Float:flNewAngles[ VectorSize ];
    xs_vec_set( flOrigin, flOrigin_[ 0 ], flOrigin_[ 1 ], flOrigin_[ 2 ] );

    entity_get_vector( iEntity, EV_VEC_origin, flEntOrigin );
    xs_vec_sub( flOrigin, flEntOrigin, flOrigin );

    flOrigin[ 2 ] *= -1.0;
    flOrigin[ 2 ] = ( flOrigin[ 2 ] * 2.0 );

    flLength = vector_length( flOrigin );

    xs_vec_set( flAimVector, flOrigin[ 0 ] / flLength, flOrigin[ 1 ] / flLength, flOrigin[ 2 ] / flLength );

    vector_to_angle( flAimVector, flNewAngles );

    flNewAngles[ 0 ] *= -1.0;

    if( flNewAngles[ 1 ] > 180.0 )                                     flNewAngles[ 1 ] -= 360;
    if( flNewAngles[ 1 ] < -180.0 )                                      flNewAngles[ 1 ] += 360;
    if( flNewAngles[ 1 ] == 180.0 || flNewAngles[ 1 ] == -180.0 )          flNewAngles[ 1 ] = -179.999999;

    entity_set_vector( iEntity, EV_VEC_angles, flNewAngles );
    entity_set_int( iEntity, EV_INT_fixangle, 1 );
}
