#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin myinfo = 
{
    name = "Kill Plugin",
    author = "zetsr",
    description = "Allows admins to kill themselves or others with !kill",
    version = "1.0",
    url = "https://github.com/zetsr"
};

public void OnPluginStart()
{
    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);
}

public Action Command_Say(int client, int args)
{
    if (client == 0) return Plugin_Continue; // 忽略控制台输入

    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    char text[192];
    GetCmdArgString(text, sizeof(text));
    StripQuotes(text);
    TrimString(text);

    // 检查是否为 !kill 命令
    if (StrContains(text, "!kill", false) != 0)
    {
        return Plugin_Continue;
    }

    if (!IsPlayerAdmin(client))
    {
        PrintToChat(client, "\x04[Kill]\x01 你没有权限使用此命令。");
        return Plugin_Handled;
    }

    char command[16], arg[32];
    if (SplitString(text, " ", command, sizeof(command)) == -1 || !StrEqual(command, "!kill", false))
    {
        if (StrEqual(text, "!kill", false))
        {
            PrintToChat(client, "\x04[Kill]\x01 用法: !kill self 或 !kill <steam32id>");
            return Plugin_Handled;
        }
        return Plugin_Continue;
    }

    strcopy(arg, sizeof(arg), text[strlen(command) + 1]);
    TrimString(arg);

    if (arg[0] == '\0')
    {
        PrintToChat(client, "\x04[Kill]\x01 请提供参数：self 或 <steam32id>。");
        return Plugin_Handled;
    }

    if (StrEqual(arg, "self", false))
    {
        if (!IsPlayerAlive(client))
        {
            PrintToChat(client, "\x04[Kill]\x01 你已经死了，无法杀死自己。");
            return Plugin_Handled;
        }
        ForcePlayerSuicide(client);
        PrintToChat(client, "\x04[Kill]\x01 你已自杀。");
    }
    else
    {
        int target = FindClientBySteamID(arg);
        if (target == -1)
        {
            PrintToChat(client, "\x04[Kill]\x01 未找到 Steam32 ID 为 %s 的玩家。", arg);
            return Plugin_Handled;
        }
        if (!IsPlayerAlive(target))
        {
            PrintToChat(client, "\x04[Kill]\x01 Steam32 ID 为 %s 的玩家已经死了。", arg);
            return Plugin_Handled;
        }
        ForcePlayerSuicide(target);
        PrintToChat(client, "\x04[Kill]\x01 你已杀死 Steam32 ID 为 %s 的玩家。", arg);
        PrintToChat(target, "\x04[Kill]\x01 你被管理员杀死。");
    }

    return Plugin_Handled;
}

// 检查玩家是否有效
stock bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

// 检查玩家是否为管理员
stock bool IsPlayerAdmin(int client)
{
    return GetUserAdmin(client) != INVALID_ADMIN_ID;
}

// 根据 Steam32 ID 查找玩家
stock int FindClientBySteamID(const char[] steamID)
{
    char clientAuth[32];
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            GetClientAuthId(i, AuthId_Steam2, clientAuth, sizeof(clientAuth));
            if (StrEqual(clientAuth, steamID, false))
            {
                return i;
            }
        }
    }
    return -1;
}