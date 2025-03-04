#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin myinfo = 
{
    name = "Money Management Plugin",
    author = "zetsr",
    description = "Allows admins to add or remove money with !add_money and !remove_money",
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

    // 检查命令
    bool isAddMoney = StrContains(text, "!add_money", false) == 0;
    bool isRemoveMoney = StrContains(text, "!remove_money", false) == 0;

    if (!isAddMoney && !isRemoveMoney)
    {
        return Plugin_Continue;
    }

    if (!IsPlayerAdmin(client))
    {
        PrintToChat(client, "\x04[Money]\x01 你没有权限使用此命令。");
        return Plugin_Handled;
    }

    char command[16], arg1[32], arg2[32];
    if (SplitString(text, " ", command, sizeof(command)) == -1)
    {
        PrintToChat(client, "\x04[Money]\x01 用法: !add_money/!remove_money self <value> 或 <steam32id> <value>");
        return Plugin_Handled;
    }

    char temp[192];
    strcopy(temp, sizeof(temp), text[strlen(command) + 1]);
    if (SplitString(temp, " ", arg1, sizeof(arg1)) == -1)
    {
        PrintToChat(client, "\x04[Money]\x01 用法: !add_money/!remove_money self <value> 或 <steam32id> <value>");
        return Plugin_Handled;
    }

    strcopy(arg2, sizeof(arg2), temp[strlen(arg1) + 1]);
    TrimString(arg2);

    if (arg2[0] == '\0')
    {
        PrintToChat(client, "\x04[Money]\x01 请提供数值参数。");
        return Plugin_Handled;
    }

    int value = StringToInt(arg2);
    if (value == 0)
    {
        PrintToChat(client, "\x04[Money]\x01 数值不能为 0。");
        return Plugin_Handled;
    }
    if (value < 0)
    {
        PrintToChat(client, "\x04[Money]\x01 数值不能为负数。");
        return Plugin_Handled;
    }

    // 获取服务器的最大金钱值
    ConVar mpMaxMoney = FindConVar("mp_maxmoney");
    int maxMoney = mpMaxMoney != null ? mpMaxMoney.IntValue : 16000; // 默认 16000

    if (StrEqual(arg1, "self", false))
    {
        if (!IsPlayerAlive(client))
        {
            PrintToChat(client, "\x04[Money]\x01 你必须存活才能修改金钱。");
            return Plugin_Handled;
        }
        int newMoney = AdjustMoney(client, client, value, isAddMoney, maxMoney); // 管理员和目标相同
        if (newMoney == -1) // 操作失败
        {
            return Plugin_Handled;
        }
        if (isAddMoney)
        {
            PrintToChat(client, "\x04[Money]\x01 你为自己添加了 %d 块钱，当前余额: %d。", value, newMoney);
        }
        else
        {
            PrintToChat(client, "\x04[Money]\x01 你为自己移除了 %d 块钱，当前余额: %d。", value, newMoney);
        }
    }
    else
    {
        int target = FindClientBySteamID(arg1);
        if (target == -1)
        {
            PrintToChat(client, "\x04[Money]\x01 未找到 Steam32 ID 为 %s 的玩家。", arg1);
            return Plugin_Handled;
        }
        if (!IsPlayerAlive(target))
        {
            PrintToChat(client, "\x04[Money]\x01 目标玩家必须存活才能修改金钱。");
            return Plugin_Handled;
        }
        int newMoney = AdjustMoney(client, target, value, isAddMoney, maxMoney); // 传入管理员和目标
        if (newMoney == -1) // 操作失败
        {
            return Plugin_Handled;
        }
        if (isAddMoney)
        {
            PrintToChat(client, "\x04[Money]\x01 已为 Steam32 ID 为 %s 的玩家添加 %d 块钱。", arg1, value);
            PrintToChat(target, "\x04[Money]\x01 管理员为你添加了 %d 块钱，当前余额: %d。", value, newMoney);
        }
        else
        {
            PrintToChat(client, "\x04[Money]\x01 已从 Steam32 ID 为 %s 的玩家移除 %d 块钱。", arg1, value);
            PrintToChat(target, "\x04[Money]\x01 管理员从你身上移除了 %d 块钱，当前余额: %d。", value, newMoney);
        }
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

// 调整玩家金钱
stock int AdjustMoney(int admin, int target, int value, bool isAdd, int maxMoney)
{
    int currentMoney = GetEntProp(target, Prop_Send, "m_iAccount");

    // 检查边界
    if (isAdd)
    {
        if (currentMoney >= maxMoney)
        {
            PrintToChat(admin, "\x04[Money]\x01 %s金钱已达上限 %d，无法添加更多。", admin == target ? "你的" : "目标", maxMoney);
            if (admin != target)
            {
                PrintToChat(target, "\x04[Money]\x01 你的金钱已达上限 %d，无法添加更多。", maxMoney);
            }
            return -1;
        }
        int potentialMoney = currentMoney + value;
        if (potentialMoney > maxMoney)
        {
            PrintToChat(admin, "\x04[Money]\x01 添加 %d 块钱将超过上限 %d，已调整至最大值。", value, maxMoney);
            if (admin != target)
            {
                PrintToChat(target, "\x04[Money]\x01 添加 %d 块钱将超过上限 %d，已调整至最大值。", value, maxMoney);
            }
            SetEntProp(target, Prop_Send, "m_iAccount", maxMoney);
            return maxMoney;
        }
    }
    else
    {
        if (currentMoney <= 0)
        {
            PrintToChat(admin, "\x04[Money]\x01 %s金钱已为 0，无法移除更多。", admin == target ? "你的" : "目标");
            if (admin != target)
            {
                PrintToChat(target, "\x04[Money]\x01 你的金钱已为 0，无法移除更多。");
            }
            return -1;
        }
        int potentialMoney = currentMoney - value;
        if (potentialMoney < 0)
        {
            PrintToChat(admin, "\x04[Money]\x01 移除 %d 块钱将导致%s余额为负，已调整至 0。", value, admin == target ? "你的" : "目标");
            if (admin != target)
            {
                PrintToChat(target, "\x04[Money]\x01 移除 %d 块钱将导致余额为负，已调整至 0。", value);
            }
            SetEntProp(target, Prop_Send, "m_iAccount", 0);
            return 0;
        }
    }

    // 正常调整
    int newMoney = isAdd ? currentMoney + value : currentMoney - value;
    SetEntProp(target, Prop_Send, "m_iAccount", newMoney);
    return newMoney;
}