/* 
   GeoIP module functions for AMX Mod X
   by David "BAILOPAN" Anderson.
   Modified by Arkshine.
   (C) Copyrighted under the GNU General Public License, Version 2
*/

#if defined geoip_included
    #endinput
#endif
#define _geoip_included

#if AMXX_VERSION_NUM >= 175
    #pragma reqlib geoip
    #if !defined AMXMODX_NOAUTOLOAD
        #pragma loadlib geoip
    #endif
#else
    #pragma library geoip
#endif

/// IP addresses passed to these natives can contain ports, the ports will be ignored.

/**
 * look up the two character country code for a given IP address.
 * e.g: "US", "CA", etc.
 *
 * @param ip		The IP address to look up.
 * @param result	The result buffer.  If the look up does not succeed, the buffer is not modified.
 * @return			true on a successful look up, false on a failed look up.
 */
native bool:geoip_code2_ex( const ip[], result[3] );

/**
 * look up the three character country code for a given IP address.
 * e.g: "USA", "CAN", etc.
 *
 * @param ip		The IP address to look up.
 * @param result	The result buffer.  If the look up does not succeed, the buffer is not modified.
 * @return			true on a successful look up, false on a failed look up.
 */
native bool:geoip_code3_ex( const ip[], result[4] );

/**
 * @deprecated
 * look up the two character country code for a given IP address.
 *
 * @note This native will overflow the buffer by one cell on an unknown ip look up!
 * @note Use geoip_code2_ex instead!
 *
 * @param ip		The IP address to look up.
 * @param result	The result buffer.
 */
native geoip_code2( const ip[], ccode[3] );

/**
 * @deprecated
 * look up the three character country code for a given IP address.
 *
 * @note This native will overflow the buffer by one cell on an unknown ip look up!
 * @note Use geoip_code3_ex instead!
 *
 * @param ip		The IP address to look up.
 * @param result	The result buffer.
 */
native geoip_code3( const ip[], result[4]) ;

/**
 * look up the full country name for the given IP address. Sets the buffer to "error" on
 * an unsuccessful look up.
 *
 * @param ip		The IP address to look up.
 * @param result	The result of the geoip look up.
 * @param len		The maximum length of the result buffer.
 */
native geoip_country( const ip[], result[], len );

/** 
 * look up the full city name for the given IP address. Sets the buffer to "error" on
 * an unsuccessful look up. 
 * 
 * @param ip		The IP address to look up. 
 * @param result	The result of the geoip look up. 
 * @param len		The maximum length of the result buffer. 
 */ 
native geoip_city( const ip[], result[], len ); 

/** 
 * look up the city's latitude for the given IP address.
 * 
 * @param ip		The IP address to look up. 
 * @return			The result of the geoip look up, 0 if latitude is not found.
 */ 
native Float:geoip_latitude( const ip[] ); 

/** 
 * look up the city's longitude for the given IP address. Returns 
 * 
 * @param ip		The IP address to look up. 
 * @return			The result of the geoip look up, 0 if longitude is not found. 
 */ 
native Float:geoip_longitude( const ip[] );

/**
 * look up the region/state code for the given IP address.
 * e.g: "OH", "CA", "11", etc.
 *
 * @note It can be a number depending.
 *
 * @param ip		The IP address to look up.
 * @param result	The result of the geoip look up.
 * @return			true on a successful look up, false on a failed look up.
 */
native bool:geoip_region( const ip[], result[4] );

/**
 * look up the full region/state name for the given IP address. Sets the buffer to "error" on
 * an unsuccessful look up.
 *
 * @param ip		The IP address to look up.
 * @param result	The result of the geoip look up.
 * @param len		The maximum length of the result buffer.
 */
native geoip_region_name( const ip[], result[], len );

/**
 * Look up the full time zone for the given IP address. Sets the buffer to "error" on
 * an unsuccessful look up.
 *
 * @param ip		The IP address to look up.
 * @param result	The result of the geoip look up.
 * @param len		The maximum length of the result buffer.
 */
native geoip_timezone( const ip[], result[], len );

/**
 * Look up the continent code for a given IP address.
 *
 * @note The code can be retrieved as integer or string (2 characters).
 * @note Possible continent codes are AF, AS, EU, NA, OC, SA for 
 * Africa(1), Asia(2), Europe(3), North America(4), Oceania(5) and South America(6).
 *
 * @param ip		The IP address to look up.
 * @param result	The result of the geoip look up. This param is optional. 
 *					If the look up does not succeed, the buffer is not modified.
 * @return			The result of the geoip look up, 0 on a failed look up.
 */
enum Continent
{
	CONTINENT_ERROR = 0,
	AFRICA,
	ASIA,
	EUROPE,
	NORTH_AMERICA,
	OCEANIA,
	SOUTH_AMERICA
}
native Continent:geoip_continent_code( const ip[], result[3] = "" );

/**
 * Calculate the distance between geographical coordinates, latitude and longitude.
 *
 * @param lat1		The first IP latitude.
 * @param lon1		The first IP longitude.
 * @param lat2		The second IP latitude.
 * @param lon2		The second IP longitude.
 * @param system    The system of measurement, 0 = Meteric(kilometers) or 1 = English(miles).  
 * @return			The distance as result in specified system of measurement.
 */
native Float:geoip_distance( Float:lat1, Float:lon1, Float:lat2, Float:lon2, system = 0 );