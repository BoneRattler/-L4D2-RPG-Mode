#include <sourcemod>
#include <sdktools>
#define VERSION "1.2.2"
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3
#define ZOMBIECLASS_TANK 8
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD
#define MAXLEVEL 100

public Plugin:myinfo=
{
	name = "RPG Mode",
	author = "Bone Rattler",
	description = "RPG plugin for L4D2",
	version = VERSION,
	url = ""
};

//Create variable to hold level for players
new Lv[MAXPLAYERS+1]
//Create variable to hold experience for players
new EXP[MAXPLAYERS+1]
//경험치량
//좀비가 줄..
new Handle:JocExp
new Handle:HunExp
new Handle:ChaExp
new Handle:SmoExp
new Handle:SpiExp
new Handle:BooExp
new Handle:TanExp
new Handle:WitExp
new Handle:ComExp
//경험치 체킹
new Handle:CheckExp[MAXPLAYERS+1]
//좀비 클래스
new ZC
//스테이터스
new ISCONFIRM[MAXPLAYERS+1]
new Str[MAXPLAYERS+1]
new Agi[MAXPLAYERS+1]
new Health[MAXPLAYERS+1]
new Endurance[MAXPLAYERS+1]
new Intelligence[MAXPLAYERS+1]
//능력
new LegValue
//스테이터스 포인트
new Handle:LvUpSP
new StatusPoint[MAXPLAYERS+1]
//스킬 - 힐링
new bool:HealingBool[MAXPLAYERS+1]
new HealingLv[MAXPLAYERS+1]
//스킬 - 지진
new Float:NowLocation[MAXPLAYERS+1][3]
new bool:EQBool[MAXPLAYERS+1]
new EarthQuakeLv[MAXPLAYERS+1]
//스킬 포인트
new SkillPoint[MAXPLAYERS+1]
new SkillConfirm[MAXPLAYERS+1]
//리바이빙 이벤트
new Handle:ReviveExp
//디피브릴레이터 이벤트
new Handle:DefExp
//직업
new bool:JobChooseBool[MAXPLAYERS+1]
new JD[MAXPLAYERS+1] = 0
//기술자
new bool:AcolyteBool[MAXPLAYERS+1]
//기술자 - Overcharged Clip
new OverchargedClipLv[MAXPLAYERS+1]
new bool:EnableOvClip[MAXPLAYERS+1]
//기술자 - Fortify Weapon
new FWLv[MAXPLAYERS+1]
//솔져
new bool:SoldierBool[MAXPLAYERS+1]
//솔져 - 단련된 체력 - Health
new TrainedHealthLv[MAXPLAYERS+1]
//솔져 - 질주
new SprintLv[MAXPLAYERS+1]
new bool:EnaSprint[MAXPLAYERS+1]
//솔져 - 총알 난사
new bool:EnaUG[MAXPLAYERS+1]
new bool:UGBool[MAXPLAYERS+1]
new UpgradeGunLv[MAXPLAYERS+1]
//생체병기
new bool:BioWeaponBool[MAXPLAYERS+1]
//생체병기 - 생체방패
new BioShieldLv[MAXPLAYERS+1]
new bool:EnaBioS[MAXPLAYERS+1]
new bool:ActiBioS[MAXPLAYERS+1]
//생체병기 - 공속
new WRQ[MAXPLAYERS+1]
new WRQL
new OffAW = -1
new OffNPA = -1
new Float:Multi
//생체병기 및 군인 - 탄환 수
new C1 = -1
new C2 = -1

public OnPluginStart()
{
	CreateConVar("l4d2_RPG_Mode_Version", VERSION, "RPG 모드 버전", CVAR_FLAGS)
	
	RegConsoleCmd("statusconfirm", ConfirmChooseMenu)
	RegConsoleCmd("usestatus", StatusChooseMenu)
	RegConsoleCmd("useskill", SkillChooseMenu)
	RegConsoleCmd("DS", DetermineSkillMenu)
	RegConsoleCmd("myexp", ShowMyExp)
	RegConsoleCmd("usejob", Job)
	RegConsoleCmd("myinfo", MyInfo)
	RegConsoleCmd("jobinfo", JobInfo)
	RegConsoleCmd("jobskillinfo", JobSkillInfo)
	RegConsoleCmd("rpgmenu", RPG_Menu)
	
	RegAdminCmd("sm_giveexp",Command_GiveExp,ADMFLAG_KICK,"sm_giveexp [#userid|name] [number of points]")
	RegAdminCmd("sm_givelv",Command_GiveLevel,ADMFLAG_KICK,"sm_givelv [#userid|name] [number of points]")
	
	//각각 특좀에게서 얻을 경험치량
	JocExp = CreateConVar("sm_JocExp","80","EXP that Jockey gives", FCVAR_PLUGIN)
	HunExp = CreateConVar("sm_HunExp","100", "EXP that Hunter gives", FCVAR_PLUGIN)
	ChaExp = CreateConVar("sm_ChaExp","110","EXP that Charger gives", FCVAR_PLUGIN)
	SmoExp = CreateConVar("sm_SmoExp","70","EXP that Smoker gives", FCVAR_PLUGIN)
	SpiExp = CreateConVar("sm_SpiExp","50","EXP that Spitter gives", FCVAR_PLUGIN)
	BooExp = CreateConVar("sm_BooExp","50","EXP that Boomer gives", FCVAR_PLUGIN)
	TanExp = CreateConVar("sm_TanExp","2000","EXP that Tank gives", FCVAR_PLUGIN)
	WitExp = CreateConVar("sm_WitExp","500","EXP that Witch gives", FCVAR_PLUGIN)
	ComExp = CreateConVar("sm_ComExp","25","EXP that Common Zombie gives", FCVAR_PLUGIN)
	
	//레벨 업 할때 얻는 스테이터스 포인트
	LvUpSP = CreateConVar("sm_LvUpSP","5","given Status Points when level's up", FCVAR_PLUGIN)
	
	//리바이빙 이벤트
	ReviveExp = CreateConVar("sm_ReviveExp","120","EXP when you succeed Setting someone up", FCVAR_PLUGIN)
	
	//살리기 이벤트
	DefExp = CreateConVar("sm_DefExp","200","EXP when you succeed to revive someone with defibrillator", FCVAR_PLUGIN)

	//이벤트를 걸러내자.
	HookEvent("witch_killed", WK)
	HookEvent("player_death", PK)
	HookEvent("infected_death", IK)
	HookEvent("player_first_spawn", PFS)
	HookEvent("player_spawn", PlayerS)
	HookEvent("player_hurt", PH)
	HookEvent("infected_hurt", IH)
	HookEvent("heal_success", HealSuc)
	HookEvent("jockey_ride_end", JocRideEnd)
	HookEvent("round_start", RoundStart)
	HookEvent("revive_success", RevSuc)
	HookEvent("defibrillator_used", DefUsed)
	HookEvent("weapon_fire", WeaponF, EventHookMode_Post)
	
	
	//좀비 클래스를 얻고
	ZC = FindSendPropInfo("CTerrorPlayer", "m_zombieClass")
	
	//기타 오프셋을 얻자
	LegValue = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue")
	OffAW = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon")
	OffNPA = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack")
	C1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")
	C2 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip2")
	
	//공격 속도 수정..
	Multi = 0.5
	
	//CFG파일 생성
	AutoExecConfig(true, "l4d2_RollPlayingGameMode")
}

public Action:PFS(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	CheckExp[target] = CreateTimer(1.0, CEOP, target, TIMER_REPEAT)
	if(!IsFakeClient(target))
	{
		PrintToChat(target, "\x03Running \x05RPG Mode Version \x04%s", VERSION)
		PrintToChat(target, "\x04Written by Bone Rattler, Original Version by Rayne")
		PrintToChat(target, "\x03Your Level is \x04 %d \x03", Lv[target])
		PrintToChat(target, "\x03STR: \x04%d, \x03AGI: \x04%d, \x03HP: \x04%d, \x03END: \x04%d, \x03INT: \x04%d", Str[target], Agi[target], Health[target], Endurance[target], Intelligence[target])
	}
}

public Action:CEOP(Handle:timer, any:target)
{
	//Level up player according to current level and exp needed function
	
	new expneeded;
	
	if(Lv[target] < 1){
		expneeded = 50;
	}
	else{
		//This function for level exp was calculated trying to preserve the original spirit of the exp per level, but scaled to the new max level of 100
		expneeded = 95*Lv[target]-45;
	}
	
	if(EXP[target] > expneeded && Lv[target] < MAXLEVEL)
	{
		//increment level
		Lv[target] += 1
			
		//add status points
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//add skill points
		SkillPoint[target] += 1
			
		//notify player
		PrintToChat(target, "\x04[LEVEL UP] \x03Level:\x05 %d \x03Just type \x05!rpgmenu \x03to spend status points", Lv[target])
		PrintToChat(target, "\x03Skill Point gained. Type \x05!rpgmenu \x03to upgrade Skills")
			
		//reset exp
		EXP[target] -= expneeded
	}
}

//Award Exp for Special Infected Kills
public Action:PK(Handle:event, String:event_name[], bool:dontBroadcast)	
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"))
	new deadbody = GetClientOfUserId(GetEventInt(event, "userid"))
	new ZClass = GetEntData(deadbody, ZC)
	
	if(killer != 0 && !IsFakeClient(killer) && GetClientTeam(killer) == TEAM_SURVIVORS)
	{
		//This cannot work as a switch, it causes very bad bugs
		if(ZClass == 1)
		{
			EXP[killer] += GetConVarInt(SmoExp)
			PrintToChat(killer, "\x03You received \x04%d \x03EXP from \x05Smoker", GetConVarInt(SmoExp))
		}
	
		if(ZClass == 2)
		{
			EXP[killer] += GetConVarInt(BooExp)
			PrintToChat(killer, "\x03You received \x04%d \x03EXP from \x05Boomer", GetConVarInt(BooExp))
		}
	
		if(ZClass == 3)
		{
			EXP[killer] += GetConVarInt(HunExp)
			PrintToChat(killer, "\x03You received \x04%d \x03EXP from \x05Hunter", GetConVarInt(HunExp))
		}
	
		if(ZClass == 4)
		{
			EXP[killer] += GetConVarInt(SpiExp)
			PrintToChat(killer, "\x03You received \x04%d \x03EXP from \x05Spitter", GetConVarInt(SpiExp))
		}
	
		if(ZClass == 5)
		{
			EXP[killer] += GetConVarInt(JocExp)
			PrintToChat(killer, "\x03You received \x04%d \x03EXP from \x05Jockey", GetConVarInt(JocExp))
		}
	
		if(ZClass == 6)
		{
			EXP[killer] += GetConVarInt(ChaExp)
			PrintToChat(killer, "\x03You received \x04%d \x03EXP from \x05Charger", GetConVarInt(ChaExp))
		}
		
		if(IsPlayerTank(deadbody))
		{
			EXP[killer] += GetConVarInt(TanExp)
			PrintToChat(killer, "\x03You received \x04%d \x03EXP from \x05Tank", GetConVarInt(TanExp))
		}
	}
}

public Action:WK(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "userid"))
	if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer))
	{
		EXP[killer] += GetConVarInt(WitExp)
		PrintToChat(killer, "\x03You received \x04%d \x03EXP from \x05Witch", GetConVarInt(WitExp))
	}
}

public Action:IK(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"))
	if(killer != 0 && GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer))
	{
		EXP[killer] += GetConVarInt(ComExp)
	}
}

public Action:PH(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new hurted = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new dmg = GetEventInt(event, "dmg_health")
	
	//인내력 - Endurance
	if(GetClientTeam(hurted) == TEAM_SURVIVORS && !IsFakeClient(hurted))
	{
		if(Endurance[hurted] < 51)
		{
			new EndHealth = GetEventInt(event, "health")
			new Float:EndFloat = Endurance[hurted]*0.01
			new EndAddHealth = RoundToNearest(dmg*EndFloat)
			SetEndurance(hurted, EndHealth, EndAddHealth)
		}
		else
		{
			new EndHealth = GetEventInt(event, "health")
			new EndAddHealth = RoundToNearest(dmg*0.5)
			SetEndurance(hurted, EndHealth, EndAddHealth)
			//Damage Reflection
			if(attacker != 0){
				new Float:RefFloat = (Endurance[hurted]-50)*0.01
				new RefDecHealth = RoundToNearest(dmg*RefFloat)
				new RefHealth = GetClientHealth(attacker)
				SetEndReflect(attacker, RefHealth, RefDecHealth)
			}
		}
		
		if(ActiBioS[hurted] == true)
		{
			new BioHealth = GetEventInt(event, "health")
			SetEndurance(hurted, BioHealth, dmg)
		}
	}
	
	//힘 - Strength
	if(GetClientTeam(hurted) == TEAM_INFECTED)
	{
		new StrHealth = GetEventInt(event, "health")
		new Float:StrFloat = Str[attacker]*0.02
		new StrRedHealth = RoundToNearest(dmg*StrFloat)
		SetStrDamage(hurted, StrHealth, StrRedHealth)
	}
}

//Endurance health modification
SetEndurance(client, health, endurance)
{
	SetEntityHealth(client, health+endurance)
}

//인내 반사력 형성
SetEndReflect(client, health, endurance)
{
	if(health > endurance)
	{
		SetEntityHealth(client, health-endurance)
	}
	else
	{
		ForcePlayerSuicide(client)
	}
}

//힘 - Strength 데미지 형성
SetStrDamage(client, health, str)
{
	if(health > str)
	{
		SetEntityHealth(client, health-str)
	}
}

public Action:IH(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new hurted = GetEventInt(event, "entityid")
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new dmg = GetEventInt(event, "amount")
	if(attacker != 0 && GetClientTeam(attacker) == TEAM_SURVIVORS && !IsFakeClient(attacker))
	{
		new Float:StrFloat = Str[attacker]*0.02
		new StrRedHealth = RoundToNearest(dmg*StrFloat)
		if(GetEntProp(hurted, Prop_Data, "m_iHealth") > StrRedHealth)
		{
			SetEntProp(hurted, Prop_Data, "m_iHealth", GetEntProp(hurted, Prop_Data, "m_iHealth")-StrRedHealth)
		}
	}
}

//방장 명령어
public Action:Command_GiveExp(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: sm_giveexp [Name] [Amount Of EXP to give]");
		return Plugin_Handled;
	}

	new String:arg[MAX_NAME_LENGTH], String:arg2[16];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new targetclient;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		PrintToChatAll("\x03Admin gave \x04%d \x05EXP %d", arg, arg2);
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			EXP[targetclient] += StringToInt(arg2);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_GiveLevel(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: sm_giveexp [Name] [Amount of Level to give]");
		return Plugin_Handled;
	}

	new String:arg[MAX_NAME_LENGTH], String:arg2[16];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new targetclient;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			if(Lv[targetclient] + StringToInt(arg2) < MAXLEVEL+1)
			{
				Lv[targetclient] += StringToInt(arg2);
				StatusPoint[targetclient] += GetConVarInt(LvUpSP)*StringToInt(arg2)
				SkillPoint[targetclient] += StringToInt(arg2)
				PrintToChatAll("\x03Admin gave \x04%s \x05%d EXP", arg, arg2);
			}
			else
			{
				PrintToChat(client, "\x04 %s \x03Max Level is %d. You can't level someone past that", MAXLEVEL);
			}
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

//메뉴 시작
public Action:StatusChooseMenu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		StatusChooseMenuFunc(client)
	}
	return Plugin_Handled
}

public Action:StatusChooseMenuFunc(clientId)
{
	new Handle:menu = CreateMenu(StatusMenu)
	SetMenuTitle(menu, "Unspent Status Points: %d", StatusPoint[clientId])
	AddMenuItem(menu, "option1", "Strength")
	AddMenuItem(menu, "option2", "Agillity")
	AddMenuItem(menu, "option3", "Health")
	AddMenuItem(menu, "option4", "Endurance")
	AddMenuItem(menu, "option5", "Intelligence")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public StatusMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: //힘 - Strength
			{
				if(StatusPoint[client] > 0)
					{
						Str[client] += 1
						StatusPoint[client] -= 1
						PrintToChat(client, "\x04Strength \x03is now \x05 %d.\n\x03Attack Damage increased by \x05%d \x03Percent", Str[client], Str[client]*2)
						CreateTimer(0.1, StatusUp, client)
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04Status Points \x03Remaining.")
						}
					}
					else
					{
						PrintToChat(client, "\x03You have no \x04Status Points \x03left")
					}
			}
			
			case 1: //민첩 - Agility
			{
				if(StatusPoint[client] > 0)
					{
						Agi[client] += 1
						StatusPoint[client] -= 1
						PrintToChat(client, "\x04Agility \x03is now \x05%d. \n\x04Move Speed and Jump height \x03increased by \x05%d \x03Percent", Agi[client], Agi[client])
						CreateTimer(0.1, StatusUp, client)
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04Status Points \x03Remaining.")
						}
					}
					else
					{
						PrintToChat(client, "\x03You have no \x04Status Points \x03left")
					}
			}
			
			case 2: //체력 - Health
			{
				if(StatusPoint[client] > 0)
					{
						Health[client] += 1
						StatusPoint[client] -= 1
						PrintToChat(client, "\x04Health \x03is increased by \x05%d", 10)
						new HealthForStatus = GetClientHealth(client)
						CreateTimer(0.1, StatusUp, client)
						if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
						{
							SetEntData(client, FindDataMapOffs(client, "m_iHealth"), HealthForStatus+10, 4, true)
						}
						if(JD[client] == 2)
						{
							if(TrainedHealthLv[client] < 2)
							{
								SetEntData(client, FindDataMapOffs(client, "m_iHealth"), HealthForStatus+10, 4, true)
							}
							else
							{
								SetEntData(client, FindDataMapOffs(client, "m_iHealth"),  HealthForStatus+(10*TrainedHealthLv[client]), 4, true)
							}
						}
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04Status Points \x03Remaining.")
						}
					}
					else
					{
						PrintToChat(client, "\x03You have no \x04Status Points \x03left")
					}
			}
			
			case 3: //인내력 - Endurance
			{
				if(StatusPoint[client] > 0)
					{
						Endurance[client] += 1
						StatusPoint[client] -= 1
						if(Endurance[client] < 51)
						{
							PrintToChat(client, "\x04Endurance \x03is now \x05%d. \n\x03You take \x05%d \x03Percent \x04less Damage", Endurance[client], Endurance[client])
							PrintToChat(client, "\x03Over 50 Endurance adds \x04Damage Reflection.")
						}
						CreateTimer(0.1, StatusUp, client)
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04Status Points \x03Remaining.")
						}
						if(Endurance[client] > 50)
						{
							PrintToChat(client, "\x04Damage Reflection: \x05%d \x03Percent", (Endurance[client]-50))
						}
					}
					else
					{
						PrintToChat(client, "\x03You have no \x04Status Points \x03left")
					}
			}
			
			case 4: //지능 - Intelligence
			{
				if(StatusPoint[client] > 0)
					{
						Intelligence[client] += 1
						StatusPoint[client] -= 1
						PrintToChat(client, "\x04Intelligence \x03is now \x05%d. \n\x03Skill Efficiency increased", Intelligence[client])
						CreateTimer(0.1, StatusUp, client)
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04Status Points \x03Remaining.")
						}
					}
					else
					{
						PrintToChat(client, "\x03You have no \x04Status Points \x03left")
					}
			}
		}
	}
}

public Action:ConfirmChooseMenu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		StatusConfirmFunc(client)
	}
	return Plugin_Handled
}

public Action:StatusConfirmFunc(clientId)
{
	new cost;
	switch(ISCONFIRM[clientId])
	{
		case 0: //힘 - Strength
		{
			cost = 1
		}
		
		case 1: //민첩 - Agility
		{
			cost = 1
		}
		
		case 2: //체력 - Health
		{
			cost = 1
		}
		
		case 3: //인내력 - Endurance
		{
			cost = 1
		}
		
		case 4: //지능 - Intelligence
		{
			cost = 1
		}
		
		case 5: //스킬 힐링
		{
			cost = 1
		}
		
		case 6: //스킬 지진
		{
			cost = 1
		}
		
		case 7: //총알제작
		{
			cost = 1
		}
		
		case 8: //단련된 육체
		{
			cost = 1
		}
		
		case 9: //질주
		{
			cost = 1
		}
		
		case 10: //생체방패
		{
			cost = 1
		}
		
		case 11: //총알 난사
		{
			cost = 1
		}
		
		case 12: //무기 강화
		{
			cost = 1
		}
	}
	new Handle:menu = CreateMenu(StatusConfirmHandler)
	SetMenuTitle(menu, "Required Points: %d", cost)
	AddMenuItem(menu, "option1", "Accept")
	AddMenuItem(menu, "option2", "Cancel")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

//Handles confirmation prompt to add points to skills
public StatusConfirmHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		if(itemNum == 0)
		{
			switch(ISCONFIRM[client])
			{
				//Obsolete Status Point confirm code removed
				case 5: //힐링
				{
					if(SkillPoint[client] > 0)
					{
						HealingBool[client] = true
						HealingLv[client] += 1
						SkillPoint[client] -= 1
						PrintToChat(client, "\x03Skill: \x04Healing")
						PrintToChat(client, "\x03Level: \x05%d", HealingLv[client])
						if(HealingLv[client] < 21)
						{
							PrintToChat(client, "\x03Heal Amount: \x05%d HP \x03Cooldown: \x05%d \xSeconds", Intelligence[client] + 3*HealingLv[client], 60 - 2*HealingLv[client])
						}
						else
						{
							PrintToChat(client, "\x03Heal Amount ::\x05 %d \x03Cooldown ::\x05 %d \xSeconds", Intelligence[client] + 3*HealingLv[client], 20)
						}
						if(SkillPoint[client] > 0)
						{
							SkillChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04Skill Points \x03Remaining.")
						}
					}
					else
					{
						PrintToChat(client, "\x03You have no \x04Skill Points left")
					}
				}
				
				case 6: //지진
				{
					if(SkillPoint[client] > 0)
					{
						if(EarthQuakeLv[client] < 25)
						{
							EQBool[client] = true
							EarthQuakeLv[client] += 1
							SkillPoint[client] -= 1
							PrintToChat(client, "\x04EarthQuake \x03 has become Level \x05 %d.", EarthQuakeLv[client])
							PrintToChat(client, "\x04EarthQuake \x03's Range has become \x05 %d.", (50+Intelligence[client])*EarthQuakeLv[client])
							if(SkillPoint[client] > 0)
							{
								SkillChooseMenuFunc(client)
								PrintToChat(client, "\x03You have \x04Skill Points \x03Remaining.")
							}
						}
						else
						{
							PrintToChat(client, "\x03You already mastered \x04EarthQuake")
						}
					}
					else
					{
						PrintToChat(client, "\x03You have no \x04Skill Points left")
					}
				}
				
				case 7: //총알제작!!
				{
					if(SkillPoint[client] > 0 && JD[client] == 1)
					{
						EnableOvClip[client] = true
						OverchargedClipLv[client] += 1
						SkillPoint[client] -= 1
						PrintToChat(client, "\x03Skill: \x04Overcharged Clip \x03's Level has become \x05 %d.", OverchargedClipLv[client])
						CreateTimer(0.1, StatusUp, client)
						if(SkillPoint[client] > 0)
						{
							SkillChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04Skill Points \x03Remaining.")
						}
					}
					
					if(SkillPoint[client] < 1) 
					{
						PrintToChat(client, "\x03You have no \x04Skill Points left")
					}
					
					if(JD[client] == 0 || JD[client] == 2 || JD[client] == 3)
					{
						PrintToChat(client, "\x03You are not an \x04Engineer")
					}
				}
				
				case 8: //단련된 체력 - Health
				{
					if(SkillPoint[client] > 0 && JD[client] == 2)
					{
						if(TrainedHealthLv[client] < 2)
						{
							TrainedHealthLv[client] += 1
							SkillPoint[client] -= 1
							PrintToChat(client, "\x04Trained Health \x03 has become Level \x05 %d.", TrainedHealthLv[client])
							if(SkillPoint[client] > 0)
							{
								SkillChooseMenuFunc(client)
								PrintToChat(client, "\x03You have \x04Skill Points \x03Remaining.")
							}
						}
						else
						{
							PrintToChat(client, "\x03You already mastered \x04Trained Health")
						}
					}
					else if(SkillPoint[client] < 1) 
					{
						PrintToChat(client, "\x03You have no \x04Skill Points left")
					}
					else if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
					{
						PrintToChat(client, "\x03You are not a \x04Soldier")
					}
				}
				
				case 9: //질주
				{
					if(SkillPoint[client] > 0 && JD[client] == 2)
					{
						EnaSprint[client] = true
						SprintLv[client] += 1
						SkillPoint[client] -= 1
						PrintToChat(client, "\x04Sprint \x03 has become Level \x05 %d.", SprintLv[client])
						if(SkillPoint[client] > 0)
						{
							SkillChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04Skill Points \x03Remaining.")
						}
					}
					else if(SkillPoint[client] < 1) 
					{
						PrintToChat(client, "\x03You have no \x04Skill Points left")
					}
					else if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
					{
						PrintToChat(client, "\x03You are not a \x04Soldier")
					}
				}
				
				case 10: //생체방패
				{
					if(SkillPoint[client] > 0 && JD[client] == 3)
					{
						EnaBioS[client] = true
						ActiBioS[client] = true
						BioShieldLv[client] += 1
						SkillPoint[client] -= 1
						PrintToChat(client, "\x04Bionic Shield \x03 has become Level \x05 %d.", BioShieldLv[client])
						if(SkillPoint[client] > 0)
						{
							SkillChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04Skill Points \x03Remaining.")
						}
					}
					else if(SkillPoint[client] < 1) 
					{
						PrintToChat(client, "\x03You have no \x04Skill Points left")
					}
					else if(JD[client] == 0 || JD[client] == 1 || JD[client] == 2)
					{
						PrintToChat(client, "\x03You are not a \x04Bionic Weapon.")
					}
				}
				
				case 11: //총알 난사
				{
					if(SkillPoint[client] > 0 && JD[client] == 2)
					{
						if(UpgradeGunLv[client] < 10)
						{
							UpgradeGunLv[client] += 1
							SkillPoint[client] -= 1
							UGBool[client] = true
							EnaUG[client] = true
							PrintToChat(client, "\x04Infinite Ammo \x03 has become Level \x04%d.", UpgradeGunLv[client])
							if(SkillPoint[client] > 0)
							{
								SkillChooseMenuFunc(client)
								PrintToChat(client, "\x03You have \x04Skill Points \x03Remaining.")
							}
						}
						else
						{
							PrintToChat(client, "\x04You already mastered \x05Infinite Ammo")
						}
					}
					else if(SkillPoint[client] < 1) 
					{
						PrintToChat(client, "\x03You have no \x04Skill Points left")
					}
					else if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
					{
						PrintToChat(client, "\x03You are not a \x04Soldier")
					}
				}
				
				case 12: //무기 강화
				{
					if(SkillPoint[client] > 0 && JD[client] == 1)
					{
						if(FWLv[client] < 10)
						{
							FWLv[client] += 1
							SkillPoint[client] -= 1
							PrintToChat(client, "\x03you \x04Fortified \x03Weapons")
							PrintToChat(client, "\x04Attack Speed \x03Increased by \x05%d \x03Percent", FWLv[client])
							if(SkillPoint[client] > 0)
							{
								SkillChooseMenuFunc(client)
								PrintToChat(client, "\x03You have \x04Skill Points \x03Remaining.")
							}
						}
						else
						{
							PrintToChat(client, "\x03You can't \x04Fortify Weapons \x03anymore")
						}
					}
					else if(SkillPoint[client] < 1) 
					{
						PrintToChat(client, "\x03You have no \x04Skill Points left")
					}
					else if(JD[client] == 0 || JD[client] == 2 || JD[client] == 3)
					{
						PrintToChat(client, "\x03You are not an \x04Engineer")
					}
				}
			}
		}
	}
}

public Action:StatusUp(Handle:timer, any:client)
{
	RebuildStatus(client)
}

RebuildStatus(client)
{
	if(SoldierBool[client] == true)
	{
		if(TrainedHealthLv[client] > 0)
		{
			SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100+(10*Health[client]*TrainedHealthLv[client]), 4, true)
		}
		else
		{
			SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100+(10*Health[client]), 4, true)
		}
	}
	else
	{
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100+(10*Health[client]), 4, true)
	}
	SetEntDataFloat(client, LegValue, 1.0*(1.0 + Agi[client]*0.01), true)
	if(Agi[client] < 50)
	{
		SetEntityGravity(client, 1.0*(1.0-(Agi[client]*0.005)))
	}
	else
	{
		SetEntityGravity(client, 0.50)
	}
}

public Action:HealSuc(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new HealSucTarget = GetClientOfUserId(GetEventInt(event, "subject"))
	if(GetClientTeam(HealSucTarget) == TEAM_SURVIVORS && !IsFakeClient(HealSucTarget) && Lv[HealSucTarget] > 0)
	{
		if(JD[HealSucTarget] == 0 || JD[HealSucTarget] == 1 || JD[HealSucTarget] == 3)
		{
			SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iMaxHealth"), 100+(10*Health[HealSucTarget]), 4, true)
			SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iHealth"), 100+(10*Health[HealSucTarget]), 4, true)
		}
		
		if(JD[HealSucTarget] == 2)
		{
			if(TrainedHealthLv[HealSucTarget] == 0)
			{
				SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iMaxHealth"), 100+(10*Health[HealSucTarget]), 4, true)
				SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iHealth"), 100+(10*Health[HealSucTarget]), 4, true)
			}
			
			if(TrainedHealthLv[HealSucTarget] > 0)
			{
				SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iMaxHealth"), 100+(10*Health[HealSucTarget])*TrainedHealthLv[HealSucTarget], 4, true)
				SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iHealth"), 100+(10*Health[HealSucTarget])*TrainedHealthLv[HealSucTarget], 4, true)
			}
		}
	}
}

public Action:JocRideEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	//code seems to reference outdated jockey_ride_end name structure
	//(subject instead of victim)
	//replaced subject with victim
	new JocEndTarget = GetClientOfUserId(GetEventInt(event, "victim"))
	if(GetClientTeam(JocEndTarget) == TEAM_SURVIVORS && !IsFakeClient(JocEndTarget) && Lv[JocEndTarget] > 0)
	{
		RebuildStatus(JocEndTarget)
	}
}

public Action:PlayerS(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	if(Lv[target] > 0 && GetClientTeam(target) == TEAM_SURVIVORS && !IsFakeClient(target))
	{
		RebuildStatus(target)
		PrintToChat(target, "\x03Your Level is \x04 %d.", Lv[target])
		PrintToChat(target, "\x03Strenth: \x04%d, \x03Agility: \x04%d, \x03Health: \x04%d, \x03Endurance: \x04%d", Str[target], Agi[target], Health[target], Endurance[target])
		PrintToChat(target, "\x03Intelligence: \x04%d", Intelligence[target])
	}
}

bool:IsPlayerTank(client)
{
	//Is The Player a Tank?
	//EXPERIMENTAL TANK EXCEPTION CATCH
	//This code checks if the player index (NPC in this case) passed through is valid before trying to grab values from it
	//function supplying this index returns 0 if index is inccorrect (Just so happens to be the index of worldspawn)
	if(client != 0)
	{
		if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
	//----OLD----
	//this was the original tank detecion code, with no check for a valid index
	
//	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
//		return true;
//	else
//	return false;
}

public Action:RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	CreateTimer(5.0, DisplayLevelInfo);
}

public Action DisplayLevelInfo(Handle timer){
	//changed loop start to 1 to avoid 0 (worldspawn index)
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS && !IsFakeClient(i))
		{
			RebuildStatus(i)
			PrintToChat(i, "\x03Your Level is \x04 %d.", Lv[i])
			PrintToChat(i, "\x03Strenth: \x04%d, \x03Agility: \x04%d, \x03Health: \x04%d, \x03Endurance: \x04%d", Str[i], Agi[i], Health[i], Endurance[i])
			PrintToChat(i, "\x03Intelligence: \x04%d", Intelligence[i])
		}
	}
}

public Action:SkillChooseMenu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		SkillChooseMenuFunc(client)
	}
	return Plugin_Handled
}

public Action:SkillChooseMenuFunc(clientId)
{
	new Handle:menu = CreateMenu(SkillMenu)
	SetMenuTitle(menu, "Unspent Skill Points: %d", SkillPoint[clientId])
	AddMenuItem(menu, "option1", "Healing")
	AddMenuItem(menu, "option2", "EarthQuake")
	AddMenuItem(menu, "option3", "Overcharged Clip")
	AddMenuItem(menu, "option4", "Trained Health")
	AddMenuItem(menu, "option5", "Sprint")
	AddMenuItem(menu, "option6", "Bionic Sheild")
	AddMenuItem(menu, "option7", "Infinite Ammo")
	AddMenuItem(menu, "option8", "Fortify Weapon")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public SkillMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: //힐링
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 5
			}
			
			case 1: //지진
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 6
			}
			
			case 2: //총알 제작
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 7
			}
			
			case 3: //단련된 체력 - Health
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 8
			}
			
			case 4: //질주
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 9
			}
			
			case 5: //생체 방패
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 10
			}
			
			case 6: //총알 난사
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 11
			}
			
			case 7: //무기강화
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 12
			}
		}
	}
}

public Action:DetermineSkillMenu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		DetermineSkillMenuFunc(client)
	}
	return Plugin_Handled
}

public Action:DetermineSkillMenuFunc(clientId)
{
	new Handle:menu = CreateMenu(DeSkiMenu)
	SetMenuTitle(menu, "Skill to Use")
	AddMenuItem(menu, "option1", "Skill Lock")
	AddMenuItem(menu, "option2", "Healing")
	AddMenuItem(menu, "option3", "EarthQuake")
	AddMenuItem(menu, "option4", "Overcharged Clip")
	AddMenuItem(menu, "option5", "Sprint")
	AddMenuItem(menu, "option6", "Bionic Shield")
	AddMenuItem(menu, "option7", "Infinite Ammo")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public DeSkiMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: //고르지 않음
			{
				SkillConfirm[client] = 0
				PrintToChat(client, "\x03 Lock all Skills")
			}
			
			case 1: //힐링
			{
				if(HealingLv[client] > 0)
				{
					SkillConfirm[client] = 1
					PrintToChat(client, "\x03Skill to Use: \x04Healing")
					PrintToChat(client, "\x03How to Use: Press Zoom")
				}
				else
				{
					PrintToChat(client, "\x03You haven't learned \x04Healing \x03Yet.")
				}
			}
			
			case 2: //지진
			{
				if(EarthQuakeLv[client] > 0)
				{
					SkillConfirm[client] = 2
					PrintToChat(client, "\x03Skill to Use: \x04EarthQuake")
					PrintToChat(client, "\x03How to Use: Press Zoom")
					if(EarthQuakeLv[client] < 21)
					{
						PrintToChat(client, "\x03Delay: \x05%d \x03Seconds",  60-2*EarthQuakeLv[client])
					}
					else
					{
						PrintToChat(client, "\x03Delay: \x05 20 \x03Seconds")
					}
				}
				else
				{
					PrintToChat(client, "\x03You haven't learned \x04EarthQuake \x03Yet.")
				}
			}
			
			case 3: //총알제작
			{
				if(OverchargedClipLv[client] > 0 && JD[client] == 1)
				{
					SkillConfirm[client] = 3
					PrintToChat(client, "\x03Skill to Use: \x04Overcharged Clip")
					PrintToChat(client, "\x03How to Use: Press Zoom")
					PrintToChat(client, "\x03Delay: \x05 %d \x03Seconds", 20+OverchargedClipLv[client])
					PrintToChat(client, "\x03Amount: \x05 %d", 5*OverchargedClipLv[client])
				}
				
				if(OverchargedClipLv[client] < 1)
				{
					PrintToChat(client, "\x03You haven't learned \x04Overcharged Clip \x03Yet.")
				}
				
				if(JD[client] == 0 || JD[client] == 2 || JD[client] == 3)
				{
					PrintToChat(client, "\x03You are not an \x04Engineer")
				}
			}
			
			case 4: //질주
			{
				if(SprintLv[client] > 0 && JD[client] == 2)
				{
					SkillConfirm[client] = 4
					PrintToChat(client, "\x03Skill to Use: \x04Sprint")
					PrintToChat(client, "\x03How to Use: Press Zoom")
				}
				
				if(SprintLv[client] < 1)
				{
					PrintToChat(client, "\x03You haven't learned \x04Sprint \x03Yet.")
				}
				
				if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
				{
					PrintToChat(client, "\x03You are not a \x04Soldier")
				}
			}
			
			case 5: //생체 방패
			{
				if(BioShieldLv[client] > 0 && JD[client] == 3)
				{
					SkillConfirm[client] = 5
					PrintToChat(client, "\x03Skill to Use: \x04Bionic Shield")
					PrintToChat(client, "\x03How to Use: Press Zoom")
				}
				
				if(BioShieldLv[client] < 1)
				{
					PrintToChat(client, "\x03You haven't learned \x04Bionic Shield \x03Yet.")
				}
				
				if(JD[client] == 0 || JD[client] == 1 || JD[client] == 2)
				{
					PrintToChat(client, "\x03You are not a \x04Bionic Weapon")
				}
			}
			
			case 6: //총알 난사
			{
				if(UpgradeGunLv[client] > 0 && JD[client] == 2)
				{
					SkillConfirm[client] = 6
					PrintToChat(client, "\x03Skill to Use: \x04Infinite Ammo")
					PrintToChat(client, "\x03How to Use: Press Zoom")
				}
				else if(UpgradeGunLv[client] < 1)
				{
					PrintToChat(client, "\x03You haven't learned \x04Infinite Ammo \x03Yet.")
				}
				else if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
				{
					PrintToChat(client, "\x03You are not a \x04Soldier")
				}
			}
		}
	}
}

public Action:Job(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS && Lv[client] > 14)
	{
		JobFunc(client)
	}
	else
	{
		PrintToChat(client, "\x03You are below Level 15")
	}
	return Plugin_Handled
}

public Action:JobFunc(clientId)
{
	new Handle:menu = CreateMenu(JobMenu)
	SetMenuTitle(menu, "Select Class")
	AddMenuItem(menu, "option1", "Engineer")
	AddMenuItem(menu, "option2", "Soldier")
	AddMenuItem(menu, "option3", "Bionic Weapon")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

//Handles Job Selection
public JobMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: // 기술자
			{
				if(JobChooseBool[client] == false && Intelligence[client] < 65)
				{
					PrintToChat(client, "\x03Class Selection: \x04failed. \x04INT:65 \x03required for Engineer.")
				}
				
				if(JobChooseBool[client] == true)
				{
					PrintToChat(client, "\x03You already selected a Class")
				}
				
				if(Intelligence[client] > 64 && JobChooseBool[client] == false)
				{
					AcolyteBool[client] = true
					Intelligence[client] += 50
					Str[client] += 5
					Agi[client] += 5
					Endurance[client] += 5
					JobChooseBool[client] = true
					PrintToChat(client, "\x03Class Selected: \x04Engineer.")
					PrintToChat(client, "\x04Stats increased by \x03STR:\x05 5 \x03, AGI:\x05 5 \x03, END:\x05 5 \x03, INT:\x05 50")
					JD[client] = 1
				}
			}
			
			case 1: //군인
			{
				if(Intelligence[client] > 4 && Agi[client] > 9 && Endurance[client] > 14 && Str[client] > 44 && JobChooseBool[client] == false)
				{
					SoldierBool[client] = true
					Agi[client] += 10
					Str[client] += 30
					Intelligence[client] += 5
					JobChooseBool[client] = true
					PrintToChat(client, "\x03Class Selected: \x04Solider.")
					PrintToChat(client, "\x04Stats increased by \x03STR:\x05 30 \x03, AGI:\x05 10 \x03, INT:\x05 5")
					JD[client] = 2
				}
				
				if(JobChooseBool[client] == true)
				{
					PrintToChat(client, "\x03You already selected a Class")
				}
				
				if(JobChooseBool[client] == false)
				{
					if(Intelligence[client] < 5 || Agi[client] < 10 || Endurance[client] < 15 || Str[client] < 45)
					{
						PrintToChat(client, "\x03Class Selection: \x04failed. \x04INT:5 AGI:10 END:15 STR:45 \x03required for Soldier.")
					}
				}
			}
			
			case 2: //생체 병기
			{
				if(Str[client] > 24 && Agi[client] > 24 && Intelligence[client] > 9 && Endurance[client] > 14 && Health[client] > 19 && JobChooseBool[client] == false)
				{
					BioWeaponBool[client] = true
					Agi[client] += 15
					Health[client] += 40
					Str[client] += 15
					JobChooseBool[client] = true
					PrintToChat(client, "\x03Class Selected: \x04Bionic Weapon.")
					PrintToChat(client, "\x04Stats increased by \x03STR:\x05 15 \x03, AGI:\x05 15 \x03, HP:\x05 40")
					SetEntData(client, FindDataMapOffs(client, "m_iHealth"), 100+10*Health[client], 4, true)
					SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100+10*Health[client], 4, true)
					JD[client] = 3
				}
				
				if(JobChooseBool[client] == true)
				{
					PrintToChat(client, "\x03You already selected a Class")
				}
				
				if(JobChooseBool[client] == false)
				{
					if(Intelligence[client] < 10 || Agi[client] < 25 || Endurance[client] < 15 || Str[client] < 25 || Health[client] < 20)
					{
						PrintToChat(client, "\x03Class Selection: \x04failed. \x04INT:10 AGI:25 END:15 STR:25 HP:20 \x03required for Bionic Weapon.")
					}
				}
			}
		}
	}
}

public Action:MyInfo(client, args)
{
	MyInfoFunc(client)
	return Plugin_Handled
}

public Action:MyInfoFunc(clientId)
{
	new Handle:menu = CreateMenu(MyInfoMenu)
	SetMenuTitle(menu, "Info")
	AddMenuItem(menu, "option1", "Check LVL and STATS")
	AddMenuItem(menu, "option2", "Class Requirements")
	AddMenuItem(menu, "option3", "EXP Progress")
	if(JD[clientId] > 0)
	{
		AddMenuItem(menu, "option4", "Job Skill Information")
	}
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public MyInfoMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: //레벨 및 스테이터스
			{
				PrintToChat(client, "\x03Level: \x06 %d.", Lv[client])
				PrintToChat(client, "\x03STR: \x07%d, \x03AGI: \x07%d, \x03HP: \x07%d, \x03END: \x07%d, \x03INT: \x07%d", Str[client], Agi[client], Health[client], Endurance[client], Intelligence[client])
			}
			
			case 1: //직업 정보
			{
				FakeClientCommand(client, "jobinfo")
			}
			
			case 2:
			{
				PrintToChat(client, "\x07%d EXP \x03to next level.",EXP[client])
			}

			case 3: //직업 스킬 정보
			{
				FakeClientCommand(client, "jobskillinfo")
			}
		}
	}
}

public Action:JobInfo(client, args)
{
	JobInfoFunc(client)
	return Plugin_Handled
}

public Action:JobInfoFunc(clientId)
{
	new Handle:menu = CreateMenu(JobInfoMenu)
	SetMenuTitle(menu, "Class Requirements")
	AddMenuItem(menu, "option1", "Engineer")
	AddMenuItem(menu, "option2", "Soldier")
	AddMenuItem(menu, "option3", "Bionic Weapon")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public JobInfoMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: //기술자
			{
				PrintToChat(client, "\x06Engineer Requirements")
				PrintToChat(client, "\x03INT: \x04 65")
			}
			
			case 1: //군인
			{
				PrintToChat(client, "\x06Soldier Requirements")
				PrintToChat(client, "\x03INT: \x04 5")
				PrintToChat(client, "\x03AGI: \x04 10")
				PrintToChat(client, "\x03END: \x04 15")
				PrintToChat(client, "\x03STR: \x04 45")
			}
			
			case 2: //감염체
			{
				PrintToChat(client, "\x06Bionic Weapon Requirements")
				PrintToChat(client, "\x03INT: \x04 10")
				PrintToChat(client, "\x03AGI: \x04 25")
				PrintToChat(client, "\x03HP: \x04 20")
				PrintToChat(client, "\x03STR: \x04 25")
				PrintToChat(client, "\x03END: \x04 15")
			}
		}
	}
}

public Action:JobSkillInfo(client, args)
{
	JobSkillInfoFunc(client)
	return Plugin_Handled
}

public Action:JobSkillInfoFunc(clientId)
{
	new Handle:menu = CreateMenu(JobSkillMenu)
	SetMenuTitle(menu, "Job Skill Information")
	AddMenuItem(menu, "option1", "Overcharged Clip")
	AddMenuItem(menu, "option2", "Passive::Trained Health")
	AddMenuItem(menu, "option3", "Sprint")
	AddMenuItem(menu, "option4", "Bionic Shield")
	AddMenuItem(menu, "option5", "Infinite Ammo")
	AddMenuItem(menu, "option6", "Passive::Fortify Weapon")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public JobSkillMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: //총알 제작
			{
				PrintToChat(client, "\x06Overcharged Clip")
				PrintToChat(client, "\x03Level: \x04 %d", OverchargedClipLv[client])
				PrintToChat(client, "\x03Ammo added to magazine: \x04 %d", 5*OverchargedClipLv[client])
			}
			
			case 1: //패시브::단련된 체력 - Health
			{
				PrintToChat(client, "\x06Trained Health")
				PrintToChat(client, "\x03Level: \x04 %d", TrainedHealthLv[client])
				PrintToChat(client, "\x03Explanation: \x04Increase Efficiency of Health Status")
			}
			
			case 2: //질주
			{
				PrintToChat(client, "\x06Sprint")
				PrintToChat(client, "\x03Level: \x04 %d", SprintLv[client])
				PrintToChat(client, "\x03Lasting Time: \x04%d \x03Seconds", 6+2*SprintLv[client])
				PrintToChat(client, "\x03Explanation: \x04Move Speed is doubled for the Skill duration")
				PrintToChat(client, "\x03Delay: \x04 %d \x03Seconds", 2*(6+2*SprintLv[client]))
			}
			
			case 3: //생체 방패
			{
				PrintToChat(client, "\x06Bionic Shield")
				PrintToChat(client, "\x03Level: \x04 %d", BioShieldLv[client])
				PrintToChat(client, "\x03Lasting Time: \x04%d \x03Seconds", 2*BioShieldLv[client])
				PrintToChat(client, "\x03Explanation: \x04During the Lasting Time, You are Unbeatable")
			}
			
			case 4: //총알 난사
			{
				PrintToChat(client, "\x06Infinite Ammo")
				PrintToChat(client, "\x03Level: \x04 %d", UpgradeGunLv[client])
				PrintToChat(client, "\x03Lasting Time: \x04 %d", 20+2*UpgradeGunLv[client])
				PrintToChat(client, "\x03Explanation: \x04Ammo is Infinite for the Skill duration")
			}
			
			case 5: //무기 강화
			{
				PrintToChat(client, "\x06Fortify Weapon")
				PrintToChat(client, "\x03Level: \x04 %d", FWLv[client])
				PrintToChat(client, "\x03Increasing Rate: \x04 %d \x03Percent", FWLv[client])
				PrintToChat(client, "\x03Explanation: \x04Increases Attack Speed")
			}
		}
	}
}

//RPG메뉴~
public Action:RPG_Menu(client,args)
{
	RPG_MenuFunc(client)

	return Plugin_Handled
}
public Action:RPG_MenuFunc(clientId) 
{
	new Handle:menu = CreateMenu(RPG_MenuHandler)
	SetMenuTitle(menu, "Level: %d",Lv[clientId])
	
	AddMenuItem(menu, "option1", "Use Stat Points")
	AddMenuItem(menu, "option2", "Use Skill Points")
	AddMenuItem(menu, "option3", "Assign Skill to Zoom")
	AddMenuItem(menu, "option4", "Choose Class [At Lv.15 and up]")
	AddMenuItem(menu, "option5", "Check LVL and STATS")
	
	SetMenuExitButton(menu, true)
	
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)

	return Plugin_Handled
}
public RPG_MenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0: // 스텟 포인트 사용
			{
				FakeClientCommand(client,"usestatus")
			}
			case 1: //스킬 포인트 사용
			{
				FakeClientCommand(client,"useskill")
			}
			case 2: //사용할 스킬 지정
			{
				FakeClientCommand(client,"DS")
			}
			case 3: //직업 선택
			{
				FakeClientCommand(client,"usejob")
			}
			case 4: //스텟 및 직업 확인
			{
				FakeClientCommand(client,"myinfo")
			}
		}
	}
}

//버튼
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsPlayerAlive(client) && buttons & IN_ZOOM && GetClientTeam(client) == TEAM_SURVIVORS)
	{
		switch(SkillConfirm[client])
		{
			case 0:
			{
			
			}
			
			case 1:
			{
				if(HealingBool[client])
				{
					new ClientHealth = GetClientHealth(client)
					if(100 + Health[client]*10 > ClientHealth+Intelligence[client]+(3*HealingLv[client]))
					{
						SetEntData(client, FindDataMapOffs(client, "m_iHealth"), ClientHealth+Intelligence[client]+(3*HealingLv[client]), 4, true)
						if(HealingLv[client] < 21)
						{
							CreateTimer(60.0 - 2*HealingLv[client], HealingDelayTimer, client)
						}
						else
						{
							CreateTimer(20.0, HealingDelayTimer, client)
						}
					}
					else
					{
						SetEntData(client, FindDataMapOffs(client, "m_iHealth"), 100+Health[client]*10, 4, true)
						if(HealingLv[client] < 21)
						{
							CreateTimer(60.0 - 2*HealingLv[client], HealingDelayTimer, client)
							PrintToChat(client, "\x03Skill: \x04Healing Lv %d \x03was used. Cooldown: \x05%d \x03Seconds", HealingLv[client], 60-2*HealingLv[client])
						}
						else
						{
							CreateTimer(20.0, HealingDelayTimer, client)
							PrintToChat(client, "\x03Skill: \x04Healing Lv %d \x03was used. Cooldown: \x05%d \x03Seconds", HealingLv[client], 20)
						}
					}	
					HealingBool[client] = false
				}
			}
	
			case 2:
			{
				if(EQBool[client])
				{
					GetClientAbsOrigin(client, NowLocation[client])
					Create_PointHurt(client)
					Shake_Screen(client, 100.0, 1.0, 1.0)
					EmitSoundToAll("player/footsteps/tank/walk/tank_walk05.wav")
					if(EarthQuakeLv[client] < 21)
					{
						CreateTimer(60.0-2*EarthQuakeLv[client], ResetEarthQuakeDelay, client)
					}
					else
					{
						CreateTimer(20.0, ResetEarthQuakeDelay, client)
					}
					EQBool[client] = false
					PrintToChat(client, "\x03Skill: \x04EarthQuake \x03was used. Cooldown: \x05 %d \x03Seconds", 60-2*EarthQuakeLv[client])
				}
			}
		
			case 3:
			{
				if(EnableOvClip[client])
				{
					new ent = GetEntDataEnt2(client, OffAW)
					if(ent != -1)
					{
						new CC1 = GetEntData(ent, C1)
						new CC2 = GetEntData(ent, C2)
						
						SetEntData(ent, C1, CC1+5*OverchargedClipLv[client], 4, true)
						SetEntData(ent, C2, CC2+5*OverchargedClipLv[client], 4, true)
					}
					EnableOvClip[client] = false
					CreateTimer(20.0+OverchargedClipLv[client], OvClipDelay, client)
					PrintToChat(client, "\x03Your \x04Clip is overcharged!")
				}	
			}
			
			case 4:
			{
				if(EnaSprint[client])
				{
					
					new SprintHealth = GetClientHealth(client)
					if(SprintHealth - ((100+10*Health[client])*0.5) > 0)
					{
						SetEntData(client, FindDataMapOffs(client, "m_iHealth"), SprintHealth - RoundToNearest((100+10*Health[client])*0.5), 4, true)
						EnaSprint[client] = false
						CreateTimer(6.0+2*SprintLv[client], SprinDelay, client)
						PrintToChat(client, "\x04Sprint \x03was used.")
						PrintToChat(client, "\x03By the Penalty, You're hurted by \x05%d", RoundToNearest((100+10*Health[client])*0.5))
						SetEntDataFloat(client, LegValue, 2.0*(1.0 + Agi[client]*0.02), true)
					}
					else
					{
						PrintToChat(client, "\x03You can't Sprint because \x04penalty condition is not Satisfied.")
					}
				}
			}
			
			case 5:
			{
				if(EnaBioS[client])
				{
					EnaBioS[client] = false
					ActiBioS[client] = true
					CreateTimer(2.0+2*BioShieldLv[client], BionSDelay, client)
					PrintToChat(client, "\x04Bionic Shield \x03was used")
				}
			}
			
			case 6:
			{
				if(EnaUG[client])
				{
					EnaUG[client] = false
					CreateTimer(20.0+2*UpgradeGunLv[client], UGTimer, client)
					PrintToChat(client, "\x04Infinite Ammo \x03was used. Cooldown: \x04%d \x03Seconds", 20+2*UpgradeGunLv[client])
				}
			}
		}
	}
}

public Action:UGTimer(Handle:timer, any:client)
{
	EnaUG[client] = true
	UGBool[client] = false
	CreateTimer(20.0+2*UpgradeGunLv[client], UGTimer2, client)
	PrintToChat(client, "\x04Infinite Ammo \x03has ended.")
}

public Action:UGTimer2(Handle:timer, any:client)
{
	UGBool[client] = true
	PrintToChat(client, "\x04Infinite Ammo \x03Recharged!")
}

public Action:BionSDelay(Handle:timer, any:client)
{
	ActiBioS[client] = false
	PrintToChat(client, "\x04Bionic Shield \x03has ended.")
	CreateTimer(2.0+2*BioShieldLv[client], ResetBionS, client)
}

public Action:ResetBionS(Handle:timer, any:client)
{
	EnaBioS[client] = true
	PrintToChat(client, "\x04Bionic Shield \x03Recharged!")
}

public Action:SprinDelay(Handle:timer, any:client)
{
	RebuildStatus(client)
	PrintToChat(client, "\x04Sprint \x03has ended.")
	CreateTimer(6.0+2*SprintLv[client], ResetSprin, client)
}

public Action:ResetSprin(Handle:timer, any:client)
{
	EnaSprint[client] = true
	PrintToChat(client, "\x04Sprint \x03Recharged!")
}

public Action:OvClipDelay(Handle:timer, any:client)
{
	EnableOvClip[client] = true
	PrintToChat(client, "\x04Overcharged Clip \x03Recharged!")
}

public Action:ShowMyExp(client, args)
{
	ShowMyExpFunc(client)
	return Plugin_Handled
}

public Action:ShowMyExpFunc(clientId)
{
	PrintToChat(clientId, "\x03Your Exp: \x04%d", EXP[clientId])
	return Plugin_Handled
}

public Action:ResetEarthQuakeDelay(Handle:timer, any:client)
{
		EQBool[client] = true
		PrintToChat(client, "\x04EarthQuake \x03Recharged!")
}

public Action:HealingDelayTimer(Handle:timer, any:client)
{
	HealingBool[client] = true
	PrintToChat(client, "\x04Healing \x03Recharged!")
}

//어쓰퀘이크
public bool:Create_PointHurt(client)
{
	new Entity;
	new String:sDamage[128];
	new String:sRadius[128];
	new String:sType[128];
	
	FloatToString(0.0, sDamage, sizeof(sDamage))
	if((50+Intelligence[client])*EarthQuakeLv[client] < 3001)
	{
		FloatToString((50.0+Intelligence[client])*EarthQuakeLv[client], sRadius, sizeof(sRadius))
	}
	else
	{
		FloatToString(4375.0, sRadius, sizeof(sRadius))
	}
	IntToString(64, sType, sizeof(sType))
	
	Entity = CreateEntityByName("point_hurt")
	
	if (!IsValidEdict(Entity)) return false
	DispatchKeyValue(Entity, "targetname", "Point_Hurt");
	DispatchKeyValue(Entity, "DamageRadius", sRadius)
	DispatchKeyValue(Entity, "Damage", sDamage)
	DispatchKeyValue(Entity, "DamageType", sType)
	
	TeleportEntity(Entity, NowLocation[client], NULL_VECTOR, NULL_VECTOR)
	DispatchSpawn(Entity)

	ActivateEntity(Entity)
	AcceptEntityInput(Entity, "Hurt")

	CreateTimer(0.1, DeleteEntity, Entity)
	
	return true
}

public Action:DeleteEntity(Handle:Timer, any:entity)
{
	if(IsValidEntity(entity))
	{
		RemoveEdict(entity);
	}
}

//화면을 흔들어주고..
public Shake_Screen(client, Float:Amplitude, Float:Duration, Float:Frequency)
{
	new Handle:Bfw;
	
	Bfw = StartMessageOne("Shake", client, 1);
	BfWriteByte(Bfw, 0);
	BfWriteFloat(Bfw, Amplitude);
	BfWriteFloat(Bfw, Duration);
	BfWriteFloat(Bfw, Frequency);

	EndMessage();
}

public Action:RevSuc(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Reviver = GetClientOfUserId(GetEventInt(event, "userid"))
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"))
	if(GetClientTeam(Reviver) == TEAM_SURVIVORS)
	{
		EXP[Reviver] += GetConVarInt(ReviveExp)
		RebuildStatus(Subject)
		PrintToChat(Reviver, "\x03Received \x05%d EXP \x03for helping someone up", GetConVarInt(ReviveExp))
	}
}

public Action:DefUsed(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new UserID = GetClientOfUserId(GetEventInt(event, "userid"))
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"))
	if(GetClientTeam(UserID) == TEAM_SURVIVORS && !IsFakeClient(UserID))
	{
		EXP[UserID] += GetConVarInt(DefExp)
		RebuildStatus(Subject)
		PrintToChat(UserID, "\x03Received \x05%d EXP \x03for reviving someone", GetConVarInt(DefExp))
	}
}

public OnGameFrame()
{
	for(new i = 0; i < MaxClients; i++)
	{
		if(BioWeaponBool[i])
		{
			GetWeapSpeed(Multi)
		}
		else if(AcolyteBool[i])
		{
			new Float:Multi2 = 1.0-(FWLv[i]*0.05)
			GetWeapSpeed(Multi2)
		}
	}
}

GetWeapSpeed(Float:MAS)
{
	if(WRQL)
	{
		decl ent, Float:time
		new Float:ETime = GetGameTime()
		
		for(new i = 0; i < WRQL; i++)
		{
			ent = WRQ[i]
			time = (GetEntDataFloat(ent, OffNPA) - ETime)*MAS
			SetEntDataFloat(ent, OffNPA, time + ETime, true)
		}
		
		WRQL = 0
	}
}

public Action:WeaponF(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new id = GetClientOfUserId(GetEventInt(event, "userid"))
	if(BioWeaponBool[id] == true && !IsFakeClient(id))
	{
		new ent = GetEntDataEnt2(id, OffAW)
		
		if(ent != -1)
		{
			WRQ[WRQL++] = ent
		}
	}
	else if(AcolyteBool[id])
	{
		new ent = GetEntDataEnt2(id, OffAW)
		
		if(ent != -1)
		{
			WRQ[WRQL++] = ent
		}
	}
	
	if(EnaUG[id] == false && UGBool[id] == true && GetClientTeam(id) == TEAM_SURVIVORS)
	{
		new ent = GetEntDataEnt2(id, OffAW)
		if(ent != -1)
		{
			SetEntData(ent, C1, 10, 4, true)
			SetEntData(ent, C2, 0, 4, true)
		}
	}
}
/* SUSPECTED DUPLICATE OF ROUND START FUNCTION
public OnMapStart()
{
	//changed loop start to 1 to avoid 0 (worldspawn index)
	for(new i = 1; i < MaxClients; i++)
	{
		//this is supposed to fix the stupid client not in game yet error
		while(!IsClientInGame(i)){
			CreateTimer(10.0, ReportPlayerNotInGame);
		}
		
		if(GetClientTeam(i) == TEAM_SURVIVORS)
		{
			RebuildStatus(i)
		}
	}
}
*/
	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset129 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
