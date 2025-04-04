#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <fakemeta>

#define PLUGIN_NAME "Force CT Join Plugin"
#define PLUGIN_VERSION "1.3"
#define PLUGIN_AUTHOR "Linkmail16"

#define TEAM_SELECT_VGUI_MENU_ID 2
#define MAX_CT 2 // Máximo de jugadores en CT

// Constantes de HUD
#define HUD_HIDE_CAL (1<<0)      // Arma, munición y lista de armas
#define HUD_HIDE_FLASH (1<<1)    // Linterna
#define HUD_HIDE_RHA (1<<3)      // Radar, salud y armadura
#define HUD_HIDE_TIMER (1<<4)    // Temporizador
#define HUD_HIDE_MONEY (1<<5)    // Dinero
#define HUD_HIDE_CROSS (1<<6)    // Crosshair

// Variables globales para controlar el HUD (valores hardcodeados)
new g_msgHideWeapon;
new bool:g_bHideCAL = false;     // No ocultar armas ni munición
new bool:g_bHideFlash = false;    // Ocultar linterna
new bool:g_bHideRHA = true;      // Ocultar radar, salud y armadura
new bool:g_bHideTimer = true;    // Ocultar temporizador
new bool:g_bHideMoney = true;    // Ocultar dinero
new bool:g_bHideCross = false;   // No ocultar crosshair

new bool:g_unassigned[33];
new bool:g_changed[33];
new g_msgid[33];

#define Keysmenu_YI (1<<0)|(1<<1)|(1<<4)|(1<<5)|(1<<9)

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
    
    // Registro de mensajes y eventos para el HUD
    g_msgHideWeapon = get_user_msgid("HideWeapon");
    register_event("ResetHUD", "onResetHUD", "b");
    register_message(g_msgHideWeapon, "msgHideWeapon");
    
    // Registro para forzar equipo CT
    register_message(get_user_msgid("ShowMenu"), "message_show_menu");
    register_message(get_user_msgid("VGUIMenu"), "message_vgui_menu");
    register_menucmd(register_menuid("mainmenu"), Keysmenu_YI, "_menu_chooseteam");
    register_clcmd("chooseteam", "hook_chooseteam");
}

public hook_chooseteam(id) {
    set_task(0.1, "force_team_join_task", id);
    return PLUGIN_HANDLED;
}

public force_team_join_task(id) {
    if (!is_user_connected(id)) return;
    
    new ct_count = get_ct_count();
    if (ct_count < MAX_CT) {
        team_join(id, "2"); // Forzar unión al equipo CT
       
        ExecuteHam(Ham_CS_RoundRespawn, id);
        client_print(id, print_chat, "¡Forzado al equipo CT y revivido!");
        set_task(0.5, "freeze_player", id); // Retraso para congelar
       
        assign_ct_model(id, "4"); // Modelo GIGN
    } else {
        team_join(id, "6"); // Forzar unión a espectadores
        client_print(id, print_chat, "¡El equipo CT está lleno! Has sido enviado a espectadores.");
    }
}

public freeze_player(id) {
    if (is_user_connected(id) && is_user_alive(id)) {
        fm_set_user_frozen(id, 1);
    } else {
        set_task(0.5, "freeze_player", id); // Reintentar con retraso
    }
}

stock team_join(id, team[]) {
    new menu_msgid = g_msgid[id];
    new msg_block = get_msg_block(menu_msgid);
    set_msg_block(menu_msgid, BLOCK_SET);
    engclient_cmd(id, "jointeam", team);
    set_msg_block(menu_msgid, msg_block);
}

public assign_ct_model(id, model[]) {
    new menu_msgid = g_msgid[id];
    new msg_block = get_msg_block(menu_msgid);
    set_msg_block(menu_msgid, BLOCK_SET);
    engclient_cmd(id, "joinclass", model);
    set_msg_block(menu_msgid, msg_block);
    g_changed[id] = true;
    g_unassigned[id] = false;
}

public message_show_menu(msgid, dest, id) {
    static team_select[] = "#Team_Select";
    static menu_text_code[sizeof team_select];
    get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1);
    if (!equal(menu_text_code, team_select)) return PLUGIN_CONTINUE;
    g_msgid[id] = msgid;
    set_task(0.1, "force_team_join_task", id);
    return PLUGIN_HANDLED;
}

public message_vgui_menu(msgid, dest, id) {
    if (get_msg_arg_int(1) != TEAM_SELECT_VGUI_MENU_ID) return PLUGIN_CONTINUE;
    g_msgid[id] = msgid;
    set_task(0.1, "force_team_join_task", id);
    return PLUGIN_HANDLED;
}

stock fm_set_user_frozen(client, frozen) {
    if (!is_user_alive(client)) return 0;
    new flags = pev(client, pev_flags);
    if (frozen && !(flags & FL_FROZEN)) {
        set_pev(client, pev_maxspeed, -1.0);
        set_pev(client, pev_velocity, Float:{0.0, 0.0, 0.0});
    }
    return 1;
}

// Funciones para el HUD
public onResetHUD(id) {
    new iHideFlags = GetHudHideFlags();
    if (iHideFlags) {
        message_begin(MSG_ONE, g_msgHideWeapon, _, id);
        write_byte(iHideFlags);
        message_end();
    }
}

public msgHideWeapon() {
    new iHideFlags = GetHudHideFlags();
    if (iHideFlags) {
        set_msg_arg_int(1, ARG_BYTE, get_msg_arg_int(1) | iHideFlags);
    }
}

GetHudHideFlags() {
    new iFlags = 0;
    if (g_bHideCAL) iFlags |= HUD_HIDE_CAL;
    if (g_bHideFlash) iFlags |= HUD_HIDE_FLASH;
    if (g_bHideRHA) iFlags |= HUD_HIDE_RHA;
    if (g_bHideTimer) iFlags |= HUD_HIDE_TIMER;
    if (g_bHideMoney) iFlags |= HUD_HIDE_MONEY;
    if (g_bHideCross) iFlags |= HUD_HIDE_CROSS;
    return iFlags;
}

// Función para contar jugadores en CT
stock get_ct_count() {
    new count = 0;
    for (new i = 1; i <= get_maxplayers(); i++) {
        if (is_user_connected(i) && cs_get_user_team(i) == CS_TEAM_CT) {
            count++;
        }
    }
    return count;
}