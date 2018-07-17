#if defined _ammo_stocks_included
	#endinput
#endif
#define _ammo_stocks_included

#include < cstrike >
#include < fun >

/*
CSW_P228		1
...
CSW_SCOUT		3
CSW_HEGRENADE	4
CSW_XM1014		5
CSW_C4			6
CSW_MAC10		7
CSW_AUG			8
CSW_SMOKEGRENADE9
CSW_ELITE		10
CSW_FIVESEVEN	11
CSW_UMP45		12
CSW_SG550		13
CSW_GALIL		14
CSW_FAMAS		15
CSW_USP			16
CSW_GLOCK18		17
CSW_AWP			18
CSW_MP5NAVY		19
CSW_M249		20
CSW_M3			21
CSW_M4A1		22
CSW_TMP			23
CSW_G3SG1		24
CSW_FLASHBANG	25
CSW_DEAGLE		26
CSW_SG552		27
CSW_AK47		28
CSW_KNIFE		29
CSW_P90			30

1   weapon_p228             250     13     52     9   ammo_357sig        600      50   p228      228compact  
...  
 3   weapon_scout            260     10     90     2   ammo_762nato      2750      80   scout                
 4   weapon_hegrenade        250             1    12                      300       0   hegren               
 5   weapon_xm1014           240      7     32     5   ammo_buckshot     3000      65   xm1014    autoshotgun
 6   weapon_c4               250      0      1    14                        0       0                        
 7   weapon_mac10            250     30    100     6   ammo_45acp        1400      25   mac10                
 8   weapon_aug              240     30     90     4   ammo_556nato      3500      60   aug       bullpup    
 9   weapon_smokegrenade     250             1    13                      300       0   sgren                
10   weapon_elite            250     30    120    10   ammo_9mm           800      20   elites               
11   weapon_fiveseven        250     20    100     7   ammo_57mm          750      50   fn57      fiveseven  
12   weapon_ump45            250     25    100     6   ammo_45acp        1700      25   ump45                
13   weapon_sg550            210     30     90     4   ammo_556nato      4200      60   sg550     krieg550   
14   weapon_galil            240     35     90     4   ammo_556nato      2000      60   galil     defender   
15   weapon_famas            240     25     90     4   ammo_556nato      2250      60   famas     clarion    
16   weapon_usp              250     12    100     6   ammo_45acp         500      25   usp       km45       
17   weapon_glock18          250     20    120    10   ammo_9mm           400      20   glock     9x19mm     
18   weapon_awp              210     10     30     1   ammo_338magnum    4750     125   awp       magnum     
19   weapon_mp5navy          250     30    120    10   ammo_9mm          1500      20   mp5       smg        
20   weapon_m249             220    100    200     3   ammo_556natobox   5750      60   m249                 
21   weapon_m3               230      8     32     5   ammo_buckshot     1700      65   m3        12gauge    
22   weapon_m4a1             230     30     90     4   ammo_556nato      3100      60   m4a1                 
23   weapon_tmp              250     30    120    10   ammo_9mm          1250      20   tmp       mp         
24   weapon_g3sg1            210     20     90     2   ammo_762nato      5000      80   g3sg1     d3au1      
25   weapon_flashbang        250             2    11                      200       0   flash                
26   weapon_deagle           250      7     35     8   ammo_50ae          650      40   deagle    nighthawk  
27   weapon_sg552            235     30     90     4   ammo_556nato      3500      60   sg552     krieg552   
28   weapon_ak47             221     30     90     2   ammo_762nato      2500      80   ak47      cv47       
29   weapon_knife            250      0      0     0                        0       0               
30   weapon_p90              245     50    100     7   ammo_57mm         2350      50   p90       c90         
*/

stock const AmmoBPSize[ ] =
{
	0,
	52,
	0,
	90,
	1,
	32,
	0,
	100,
	90,
	1,
	120,
	100,
	100,
	90,
	90,
	90,
	100,
	120,
	30,
	120,
	200,
	32,
	90,
	120,
	90,
	2,
	35,
	90,
	90,
	0,
	100
};

stock const AmmoClipSize[ ] =
{
	0,
	13,
	0,
	10,
	0,
	7,
	0,
	30,
	30,
	0,
	30,
	20,
	25,
	30,
	35,
	25,
	12,
	20,
	10,
	30,
	100,
	8,
	30,
	30,
	20,
	0,
	7,
	30,
	30,
	0,
	50
};

stock const WeaponClass[ ][ ] =
{
	"",
	"weapon_p228",
	"",
	"weapon_scout",
	"weapon_hegrenade",
	"weapon_xm1014",
	"weapon_c4",
	"weapon_mac10",
	"weapon_aug",
	"weapon_smokegrenade",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_ump45",
	"weapon_sg550",
	"weapon_galil",
	"weapon_famas",
	"weapon_usp",
	"weapon_glock18",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_flashbang",
	"weapon_deagle",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_knife",
	"weapon_p90"
};

enum ReturnTypes
{
	Return_InvalidClientIndex,
	Return_InvalidWeapon,
	Return_Successful
};

/*
 * Gives a weapon and sets ammo
 * 
 * @param		Client - Player Index
 * @param		CSWConstant - Constant CSW ID for the weapon (seen in cstrike includes)
 * @param		FullAmmo - Boolean whether to set full ammo or use next two parameters (true if full ammo, false if not. default: false)
 * @param		ClipAmmo - Ammo to be set in current clip
 * @param		BPAmmo - Ammo to be set in backpack
 * 
 * @note		enum ReturnTypes
 *				{
 *					Return_InvalidClientIndex,
 *					Return_InvalidWeapon,
 *					Return_Successful
 *				};
 *
 * @return 		Returns values from enum above (ReturnTypes)
 */

stock ReturnTypes:GiveClientWeapon( const Client, const CSWConstant = 0, const bool:FullAmmo = false, const ClipAmmo = 0, const BPAmmo = 0 )
{
	if( !( 1 <= CSWConstant <= 30 ) || CSWConstant == 2 )
	{
		return Return_InvalidWeapon;
	}
	
	if( !( 1 <= Client <= get_maxplayers( ) ) )
	{
		return Return_InvalidClientIndex;
	}
	
	if( CSWConstant == CSW_C4 || CSWConstant ==  CSW_KNIFE )
	{
		give_item( Client, WeaponClass[ CSWConstant ] );
	}
	else
	{
		new WeaponId = give_item( Client, WeaponClass[ CSWConstant ] );
		
		if( FullAmmo )
		{
			cs_set_weapon_ammo( WeaponId, AmmoClipSize[ CSWConstant ] );
			cs_set_user_bpammo( Client, CSWConstant, AmmoBPSize[ CSWConstant ] );
		}
		else
		{
			cs_set_weapon_ammo( WeaponId, ( ClipAmmo < 0 ? 0 : ClipAmmo ) );
			cs_set_user_bpammo( Client, CSWConstant, ( BPAmmo < 0 ? 0 : BPAmmo ) );
		}
	}
	
	return Return_Successful;
}

/*

Examples:

// Single Weapon (both full ammo and set ammo):

GiveClientWeapon( Client, CSW_SCOUT, .FullAmmo = true );
GiveClientWeapon( Client, CSW_SCOUT, .FullAmmo = false, 10, 90 );

// Multiple (random) weapons:

enum _:WeaponStruct
{
	Weapon_Name[ 32 ],
	CSW_Constant
};

new const Weapons[ ][ WeaponStruct ] =  
{  
	{ "Scout", CSW_SCOUT },
	{ "XM 1014", CSW_XM1014 },
	{ "Mac 10", CSW_MAC10 },
	{ "Aug", CSW_AUG },
	{ "Ump", CSW_UMP45 },
	{ "SG 550", CSW_SG550 },
	{ "Galil", CSW_GALIL },
	{ "Famas", CSW_FAMAS },
	{ "AWP", CSW_AWP },
	{ "MP5 Navy", CSW_MP5NAVY },
	{ "M249", CSW_M249 },
	{ "M3", CSW_M3 },
	{ "M4A1", CSW_M4A1 },
	{ "TMP", CSW_TMP },
	{ "G3SG1", CSW_G3SG1 },
	{ "SG 552", CSW_SG552 },
	{ "AK 47", CSW_AK47 }
};

new Random = random( sizeof( Weapons ) );
GiveClientWeapon( Client, Weapons[ Random ][ CSW_Constant ], .FullAmmo = true );

// The native also returns values, so if you would want to check values
new ReturnTypes:Return = GiveClientWeapon( Client, CSW_SCOUT, .FullAmmo = true );

if( Return == Return_Successful )
{
	// client recieved weapon and ammo was set
}
*/