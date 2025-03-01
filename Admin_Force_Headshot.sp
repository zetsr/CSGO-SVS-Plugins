#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define DMG_HEADSHOT (1 << 30)

public Plugin myinfo = 
{
    name = "Admin Force Headshot",
    author = "zetsr",
    description = "Forces all admin attacks to be headshots with proper damage and hitgroup",
    version = "1.0",
    url = "https://github.com/zetsr"
};

public void OnPluginStart()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
        }
    }
    // PrintToServer("Admin Force Headshot plugin loaded.");
}

public void OnClientPostAdminCheck(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
    // PrintToServer("Hooked client %N (ID: %d)", client, client);
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if (attacker < 1 || attacker > MaxClients || !IsClientInGame(attacker))
        return Plugin_Continue;
    
    if (!IsClientAdmin(attacker))
    {
        // PrintToServer("Attacker %N is not an admin.", attacker);
        return Plugin_Continue;
    }
    
    if (!(damagetype & DMG_BULLET))
    {
        // PrintToServer("Damage by %N is not bullet damage.", attacker);
        return Plugin_Continue;
    }
    
    // 修改伤害和爆头标志
    float originalDamage = damage;
    int originalDamagetype = damagetype;
    damage *= 4.0; // 模拟爆头伤害
    damagetype |= DMG_HEADSHOT; // 添加爆头标志
    PrintToServer("Admin %N attacking %N: Original damage %.1f -> Modified to %.1f, Damagetype %d -> %d", 
                  attacker, victim, originalDamage, damage, originalDamagetype, damagetype);
    
    return Plugin_Changed;
}

stock bool IsClientAdmin(int client)
{
    if (!IsClientInGame(client) || !IsClientConnected(client))
        return false;
    
    bool isAdmin = CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC);
    // PrintToServer("Client %N admin check: %s", client, isAdmin ? "true" : "false");
    return isAdmin;
}