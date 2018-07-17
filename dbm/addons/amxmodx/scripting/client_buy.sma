/*	Formatright © 2010, ConnorMcLeod

	This plugin is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this plugin; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

#include <amxmodx>
#include <fakemeta>
#include <cstrike>

#define VERSION "0.1.1"
#define PLUGIN "client_buy forward"

enum {
	CSW_DEFUSER = 33,
	CSW_NVGS,
	CSW_SHIELD,
	CSW_PRIMAMMO,
	CSW_SECAMMO
}

enum _:iMenus {
	Menu_Buy = 4,
	Menu_BuyPistol = 5,
	Menu_BuyRifle = 6,
	Menu_BuyMachineGun = 7,
	Menu_BuyShotgun = 8,
	Menu_BuySubMachineGun = 9,
	Menu_BuyItem = 10
}

const TE_WEAPONS = 1<<CSW_ELITE | 1<<CSW_GALIL | 1<<CSW_AK47 | 1<<CSW_SG552 | 1<<CSW_G3SG1 | 1<<CSW_MAC10
const CT_WEAPONS = 1<<CSW_FIVESEVEN | 1<<CSW_FAMAS | 1<<CSW_M4A1 | 1<<CSW_AUG | 1<<CSW_SG550 | 1<<CSW_TMP | 1<<CSW_SHIELD

#define m_iMenu 205
#define cs_get_user_menu(%0)	get_pdata_int(%0, m_iMenu)

new const g_iMenuItemsTe[][] = {
	{0, 0, 0, 0, 0, 0, CSW_PRIMAMMO, CSW_SECAMMO, 0}, /* Menu_Buy */
	{0, CSW_GLOCK18, CSW_USP, CSW_P228, CSW_DEAGLE, CSW_ELITE, 0, 0, 0}, /* Menu_BuyPistol */
	{0, CSW_GALIL, CSW_AK47, CSW_SCOUT, CSW_SG552, CSW_AWP, CSW_G3SG1, 0, 0}, /* Menu_BuyRifle */
	{0, CSW_M249, 0, 0, 0, 0, 0, 0, 0}, /* Menu_BuyMachineGun */
	{0, CSW_M3, CSW_XM1014, 0, 0, 0, 0, 0, 0}, /* Menu_BuyShotgun */
	{0, CSW_MAC10, CSW_MP5NAVY, CSW_UMP45, CSW_P90, 0, 0, 0, 0}, /* Menu_BuySubMachineGun */
	{0, CSW_VEST, CSW_VESTHELM, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_NVGS, 0, 0} /* Menu_BuyItem */
}

new const g_iMenuItemsCt[][] = {
	{0, 0, 0, 0, 0, 0, CSW_PRIMAMMO, CSW_SECAMMO, 0}, /* Menu_Buy */
	{0, CSW_GLOCK18, CSW_USP, CSW_P228, CSW_DEAGLE, CSW_FIVESEVEN, 0, 0, 0}, /* Menu_BuyPistol */
	{0, CSW_FAMAS, CSW_SCOUT, CSW_M4A1, CSW_AUG, CSW_SG550, CSW_AWP, 0, 0}, /* Menu_BuyRifle */
	{0, CSW_M249, 0, 0, 0, 0, 0, 0, 0}, /* Menu_BuyMachineGun */
	{0, CSW_M3, CSW_XM1014, 0, 0, 0, 0, 0, 0}, /* Menu_BuyShotgun */
	{0, CSW_TMP, CSW_MP5NAVY, CSW_UMP45, CSW_P90, 0, 0, 0, 0}, /* Menu_BuySubMachineGun */
	{0, CSW_VEST, CSW_VESTHELM, CSW_FLASHBANG, CSW_HEGRENADE, CSW_SMOKEGRENADE, CSW_NVGS, CSW_DEFUSER, CSW_SHIELD} /* Menu_BuyItem */
}

new g_iBuyForward, g_iReturn

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "ConnorMcLeod")
}

public plugin_cfg()
{
	new pluginsNum = get_pluginsnum()
	for(new pluginIndex; pluginIndex<pluginsNum; pluginIndex++)
	{
		if( get_func_id("client_buy", pluginIndex) != -1 )
		{
			register_clcmd("menuselect", "ClCmd_MenuSelect")
			g_iBuyForward = CreateMultiForward("client_buy", ET_STOP, FP_CELL, FP_CELL)
			break
		}
	}
	
	if( !g_iBuyForward )
	{
		log_amx("client_buy forward is not used by any other plugin, pausing plugin.")
		pause("ad")
	}
}

public plugin_natives()
{
	register_library("cl_buy")
}

public client_command(id)
{
	if( is_user_alive(id) )
	{
		new szCommand[13] // autoshotgun
		if( read_argv(0, szCommand, charsmax(szCommand)) < 12 )
		{
			return CheckBuyCmd(id, szCommand)
		}
	}
	return PLUGIN_CONTINUE
}

public CS_InternalCommand(id, const szCommand[])
{
	if( is_user_alive(id) )
	{
		new szCmd[13]
		if( copy(szCmd, charsmax(szCmd), szCommand) < 12 )
		{
			return CheckBuyCmd(id, szCmd)
		}
	}
	return PLUGIN_CONTINUE
}

CheckBuyCmd(id , szCmd[])
{
	new iItem = GetAliasId( szCmd )
	if( iItem )
	{
		if( TE_WEAPONS & 1<<iItem )
		{
			if( cs_get_user_team(id) != CS_TEAM_T )
			{
				return PLUGIN_CONTINUE
			}
		}
		else if( CT_WEAPONS & 1<<iItem )
		{
			if( cs_get_user_team(id) != CS_TEAM_CT )
			{
				return PLUGIN_CONTINUE
			}
		}

		return CanBuyItem(id, iItem)
	}
	return PLUGIN_CONTINUE
}

public ClCmd_MenuSelect( id )
{
	if( !is_user_alive(id) )
	{
		return PLUGIN_CONTINUE
	}
	new szSlot[3]
	if( read_argv(1, szSlot, charsmax(szSlot)) == 1 )
	{
		new iSlot = szSlot[0] - '0'
		if( 1 <= iSlot <= 8 )
		{
			new iMenu = cs_get_user_menu(id)
			if( Menu_Buy <= iMenu <= Menu_BuyItem )
			{
				new iItem
				switch( cs_get_user_team(id) )
				{
					case CS_TEAM_T:iItem = g_iMenuItemsTe[iMenu-4][iSlot]
					case CS_TEAM_CT:iItem = g_iMenuItemsCt[iMenu-4][iSlot]
				}
				if( iItem )
				{
					return CanBuyItem(id, iItem)
				}
			}
		}
	}
	return PLUGIN_CONTINUE
}

CanBuyItem(id, iItem)
{
	ExecuteForward(g_iBuyForward, g_iReturn, id, iItem)
	if( g_iReturn != PLUGIN_CONTINUE )
	{
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

GetAliasId( szAlias[] )
{
	static Trie:tAliasesIds = Invalid_Trie
	if( tAliasesIds == Invalid_Trie )
	{
		tAliasesIds = TrieCreate()
		TrieSetCell(tAliasesIds, "p228",		CSW_P228)
		TrieSetCell(tAliasesIds, "228compact",	CSW_P228)
		TrieSetCell(tAliasesIds, "scout",		CSW_SCOUT)
		TrieSetCell(tAliasesIds, "hegren",		CSW_HEGRENADE)
		TrieSetCell(tAliasesIds, "xm1014",		CSW_XM1014)
		TrieSetCell(tAliasesIds, "autoshotgun",	CSW_XM1014)
		TrieSetCell(tAliasesIds, "mac10",		CSW_MAC10)
		TrieSetCell(tAliasesIds, "aug",			CSW_AUG)
		TrieSetCell(tAliasesIds, "bullpup",		CSW_AUG)
		TrieSetCell(tAliasesIds, "sgren",		CSW_SMOKEGRENADE)
		TrieSetCell(tAliasesIds, "elites",		CSW_ELITE)
		TrieSetCell(tAliasesIds, "fn57",		CSW_FIVESEVEN)
		TrieSetCell(tAliasesIds, "fiveseven",	CSW_FIVESEVEN)
		TrieSetCell(tAliasesIds, "ump45",		CSW_UMP45)
		TrieSetCell(tAliasesIds, "sg550",		CSW_SG550)
		TrieSetCell(tAliasesIds, "krieg550",	CSW_SG550)
		TrieSetCell(tAliasesIds, "galil",		CSW_GALIL)
		TrieSetCell(tAliasesIds, "defender",	CSW_GALIL)
		TrieSetCell(tAliasesIds, "famas",		CSW_FAMAS)
		TrieSetCell(tAliasesIds, "clarion",		CSW_FAMAS)
		TrieSetCell(tAliasesIds, "usp",			CSW_USP)
		TrieSetCell(tAliasesIds, "km45",		CSW_USP)
		TrieSetCell(tAliasesIds, "glock",		CSW_GLOCK18)
		TrieSetCell(tAliasesIds, "9x19mm",		CSW_GLOCK18)
		TrieSetCell(tAliasesIds, "awp",			CSW_AWP)
		TrieSetCell(tAliasesIds, "magnum",		CSW_AWP)
		TrieSetCell(tAliasesIds, "mp5",			CSW_MP5NAVY)
		TrieSetCell(tAliasesIds, "smg",			CSW_MP5NAVY)
		TrieSetCell(tAliasesIds, "m249",		CSW_M249)
		TrieSetCell(tAliasesIds, "m3",			CSW_M3)
		TrieSetCell(tAliasesIds, "12gauge",		CSW_M3)
		TrieSetCell(tAliasesIds, "m4a1",		CSW_M4A1)
		TrieSetCell(tAliasesIds, "tmp",			CSW_TMP)
		TrieSetCell(tAliasesIds, "mp",			CSW_TMP)
		TrieSetCell(tAliasesIds, "g3sg1",		CSW_G3SG1)
		TrieSetCell(tAliasesIds, "d3au1",		CSW_G3SG1)
		TrieSetCell(tAliasesIds, "flash",		CSW_FLASHBANG)
		TrieSetCell(tAliasesIds, "deagle",		CSW_DEAGLE)
		TrieSetCell(tAliasesIds, "nighthawk",	CSW_DEAGLE)
		TrieSetCell(tAliasesIds, "sg552",		CSW_SG552)
		TrieSetCell(tAliasesIds, "krieg552",	CSW_SG552)
		TrieSetCell(tAliasesIds, "ak47",		CSW_AK47)
		TrieSetCell(tAliasesIds, "cv47",		CSW_AK47)
		TrieSetCell(tAliasesIds, "p90",			CSW_P90)
		TrieSetCell(tAliasesIds, "c90",			CSW_P90)

		TrieSetCell(tAliasesIds, "vest",		CSW_VEST)
		TrieSetCell(tAliasesIds, "vesthelm",	CSW_VESTHELM)

		TrieSetCell(tAliasesIds, "defuser",		CSW_DEFUSER)
		TrieSetCell(tAliasesIds, "nvgs",		CSW_NVGS)
		TrieSetCell(tAliasesIds, "shield",		CSW_SHIELD)
		TrieSetCell(tAliasesIds, "buyammo1",	CSW_PRIMAMMO)
		TrieSetCell(tAliasesIds, "primammo",	CSW_PRIMAMMO)
		TrieSetCell(tAliasesIds, "buyammo2",	CSW_SECAMMO)
		TrieSetCell(tAliasesIds, "secammo",		CSW_SECAMMO)
	}

	strtolower(szAlias)

	new iId
	if( TrieGetCell(tAliasesIds, szAlias, iId) )
	{
		return iId
	}
	return 0
}