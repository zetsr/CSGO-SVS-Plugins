#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin myinfo = 
{
    name = "Relive Plugin",
    author = "zetsr",
    description = "Allows admins to revive themselves or others with !relive",
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

    // 检查玩家是否有效
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    // 获取玩家输入的完整文本
    char text[192];
    GetCmdArgString(text, sizeof(text));
    StripQuotes(text);  // 去除引号
    TrimString(text);   // 去除首尾空格

    // 检查是否以 !relive 开头
    if (StrContains(text, "!relive", false) != 0)
    {
        return Plugin_Continue;  // 不是 !relive 命令，继续处理
    }

    // 检查玩家是否为管理员
    if (!IsPlayerAdmin(client))
    {
        PrintToChat(client, "\x04[Relive]\x01 你没有权限使用此命令。");
        return Plugin_Handled;
    }

    // 分割字符串，提取 !relive 后的部分
    char command[16], arg[32];
    if (SplitString(text, " ", command, sizeof(command)) == -1 || !StrEqual(command, "!relive", false))
    {
        if (StrEqual(text, "!relive", false))
        {
            PrintToChat(client, "\x04[Relive]\x01 用法: !relive self 或 !relive <steam32id>");
            return Plugin_Handled;
        }
        return Plugin_Continue;
    }

    // 获取空格后的参数
    strcopy(arg, sizeof(arg), text[strlen(command) + 1]);
    TrimString(arg);  // 去除多余空格

    // 处理参数
    if (StrEqual(arg, "self", false))
    {
        // 复活自己
        if (IsPlayerAlive(client))
        {
            PrintToChat(client, "\x04[Relive]\x01 你已经存活，无需复活。");
            return Plugin_Handled;
        }
        CS_RespawnPlayer(client);
        PrintToChat(client, "\x04[Relive]\x01 你已复活。");
    }
    else
    {
        // 复活指定玩家（通过 Steam32 ID）
        int target = FindClientBySteamID(arg);
        if (target == -1)
        {
            PrintToChat(client, "\x04[Relive]\x01 未找到指定 Steam32 ID 的玩家。");
            return Plugin_Handled;
        }
        if (IsPlayerAlive(target))
        {
            PrintToChat(client, "\x04[Relive]\x01 目标玩家已经存活，无需复活。");
            return Plugin_Handled;
        }
        CS_RespawnPlayer(target);
        PrintToChat(client, "\x04[Relive]\x01 你已复活 Steam32 ID 为 %s 的玩家。", arg);
        PrintToChat(target, "\x04[Relive]\x01 你被管理员复活。");
    }

    return Plugin_Handled;  // 阻止消息广播
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
    return -1; // 未找到
}