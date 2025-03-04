#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
    name = "Heal Plugin",
    author = "zetsr",
    description = "Allows admins to heal themselves with !heal <value> when alive",
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
        return Plugin_Handled; // 无效玩家，直接忽略
    }

    // 获取玩家输入的完整文本
    char text[192];
    GetCmdArgString(text, sizeof(text));
    StripQuotes(text);  // 去除引号
    TrimString(text);   // 去除首尾空格

    // 检查是否以 !heal 开头
    if (StrContains(text, "!heal", false) != 0)
    {
        return Plugin_Continue;  // 不是 !heal 命令，继续处理
    }

    // 检查玩家是否为管理员
    if (!IsPlayerAdmin(client))
    {
        PrintToChat(client, "\x04[Heal]\x01 你没有权限使用此命令。");
        return Plugin_Handled;
    }

    // 检查玩家是否存活
    if (!IsPlayerAlive(client))
    {
        PrintToChat(client, "\x04[Heal]\x01 你必须存活才能使用此命令。");
        return Plugin_Handled;
    }

    // 分割字符串，提取 !heal 后的部分
    char command[16], arg[16];
    if (SplitString(text, " ", command, sizeof(command)) == -1 || !StrEqual(command, "!heal", false))
    {
        // 如果没有空格或不是 !heal，直接使用完整字符串判断
        if (StrEqual(text, "!heal", false))
        {
            PrintToChat(client, "\x04[Heal]\x01 用法: !heal <数值> (例如 !heal 20)");
            return Plugin_Handled;
        }
        return Plugin_Continue;
    }

    // 获取空格后的参数
    strcopy(arg, sizeof(arg), text[strlen(command) + 1]);
    TrimString(arg);  // 去除多余空格

    // 调试：输出获取的参数
    // PrintToChat(client, "\x04[Debug]\x01 获取的参数: %s", arg);

    // 转换为整数
    int value = StringToInt(arg);

    // 检查输入值是否有效
    if (value <= 0)
    {
        PrintToChat(client, "\x04[Heal]\x01 无效的恢复值，请输入一个正数。");
        return Plugin_Handled;
    }

    // 增加生命值
    int currentHealth = GetClientHealth(client);
    SetEntityHealth(client, currentHealth + value);
    PrintToChat(client, "\x04[Heal]\x01 你已恢复 %d HP，当前生命值: %d。", value, GetClientHealth(client));

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