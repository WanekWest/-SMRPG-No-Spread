#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required
#include <smrpg>

#define UPGRADE_SHORTNAME "NoSpread"
#define PLUGIN_VERSION "1.0"

ConVar hCVNoSpreadDecrease;
float g_hCVNoSpreadDecrease;

public Plugin myinfo = 
{
	name = "SM:RPG Upgrade > NoSpread",
	author = "WanekWest",
	description = "Reduces the spread of bullets as lvls go up.",
	version = PLUGIN_VERSION,
	url = "https://vk.com/wanek_west"
}

public void OnPluginStart()
{
	LoadTranslations("smrpg_stock_upgrades.phrases");

	HookEvent("player_spawned", Event_PlayerSpawned, EventHookMode_PostNoCopy);
}

public void OnPluginEnd()
{
	if(SMRPG_UpgradeExists(UPGRADE_SHORTNAME))
		SMRPG_UnregisterUpgradeType(UPGRADE_SHORTNAME);
}

public void OnAllPluginsLoaded()
{
	OnLibraryAdded("smrpg");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "smrpg"))
	{
        SMRPG_RegisterUpgradeType("NoSpread", UPGRADE_SHORTNAME, "Reduces the spread of bullets as lvls go up.", 10, true, 5, 15, 10);
        SMRPG_SetUpgradeActiveQueryCallback(UPGRADE_SHORTNAME, SMRPG_ActiveQuery);
        SMRPG_SetUpgradeTranslationCallback(UPGRADE_SHORTNAME, SMRPG_TranslateUpgrade);
		
        hCVNoSpreadDecrease = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_medic_req_level_bonus", "100", "To which level, it will work without.", _, true, 1.0);
        hCVNoSpreadDecrease.AddChangeHook(OnNoSpreadChangeDecrease);
        g_hCVNoSpreadDecrease = hCVNoSpreadDecrease.FloatValue;
    }
}

public void OnNoSpreadChangeDecrease(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	g_hCVNoSpreadDecrease = hCvar.FloatValue;
}

public bool SMRPG_ActiveQuery(int iClient)
{
	return SMRPG_IsEnabled() && SMRPG_IsUpgradeEnabled(UPGRADE_SHORTNAME) && SMRPG_GetClientUpgradeLevel(iClient, UPGRADE_SHORTNAME) > 0;
}

public void SMRPG_TranslateUpgrade(int client, const char[] shortname, TranslationType type, char[] translation, int maxlen)
{
	if (type == TranslationType_Name)
		Format(translation, maxlen, "%T", UPGRADE_SHORTNAME, client);
	else if (type == TranslationType_Description)
	{
		char sDescriptionKey[MAX_UPGRADE_SHORTNAME_LENGTH+12] = UPGRADE_SHORTNAME;
		StrCat(sDescriptionKey, sizeof(sDescriptionKey), " description");
		Format(translation, maxlen, "%T", sDescriptionKey, client);
	}
}

void Event_PlayerSpawned(Event hEvent, const char[] sEvName, bool bdontBoadcast)
{
    for(int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientSourceTV(i) && !IsClientObserver(i))
		{
            int iLevel = SMRPG_GetClientUpgradeLevel(i, UPGRADE_SHORTNAME);
            if (iLevel > 0)
                ApplyMyUpgradeEffect(i, iLevel);
        }
    }

    return;
}

void ApplyMyUpgradeEffect(int iClient, int iLevel)
{
    if (!SMRPG_IsUpgradeEnabled(UPGRADE_SHORTNAME))
		return;
	
    if (IsFakeClient(iClient) && SMRPG_IgnoreBots())
		return;
	
    if (!SMRPG_RunUpgradeEffect(iClient, UPGRADE_SHORTNAME))
		return; 
	
    float cone = 0.01 * Pow(0.95, iLevel * g_hCVNoSpreadDecrease);
    int weapon = GetEntProp(iClient, Prop_Data, "m_hActiveWeapon");
    if (weapon)
    {
        SetEntProp(weapon, Prop_Data, "m_flSpread", cone);
        SetEntProp(weapon, Prop_Data, "m_flAccuracyPenalty", 0.0);
    }

    return;
}