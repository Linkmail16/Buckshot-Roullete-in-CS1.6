#include <amxmodx>
#include <fun>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <amxmisc>
#include <ChatPrint>
#define MAX_LIVES 4
#define MIN_ROUNDS 3
#define MAX_ROUNDS 6

#define RT_BLANK 0 // Bala de salva
#define RT_LIVE  1 // Bala de fuego

new g_player1 = 0;
new g_player2 = 0;
new g_lives[33];
new g_roundSequence[10];
new g_totalRounds = 0;
new g_currentRoundIndex = 0;
new g_currentTurn = 0;
new bool:g_isGameActive = false;
new g_playerRoundType[33];
new g_player1_name[32];
new g_player2_name[32];
new bool:g_keepTurn = false;
#define FFADE_IN 0x0000
#define FFADE_OUT 0x0001
#define FFADE_MODULATE 0x0002
#define FFADE_STAYOUT 0x0004
new g_fade_alpha[MAX_PLAYERS];
new g_msgScreenShake;

new const Float:entity_positions[][] = {
    {-85.449005, -16.717102, 41.300178},
    {-85.449005, -18.852619, 41.300178},
    {-85.370323, -20.544349, 41.300178},
    {-85.388610, -23.161666, 41.300178},
    {-85.404014, -25.366073, 41.300178},
    {-85.412109, -26.522218, 41.300178},
    {-85.426300, -28.553470, 41.300178},
    {-85.443374, -30.997632, 41.300178}
};
new const bullet_fire_model[] = "models/bulletRed.mdl";
new const bullet_blank_model[] = "models/bulletBlue.mdl";

new const g_szRespawn[] = "sound/respawnSound.mp3";


public plugin_init()
{
    register_plugin("Buckshot Roulette CS", "1.0", "xAI");
    g_msgScreenShake = get_user_msgid("ScreenShake");
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m3", "fw_PrimaryAttack_Post", 1);
    register_event("DeathMsg", "event_death", "a");
    set_task(1.0, "check_game_state", _, _, _, "b");
}

public plugin_precache()
{
    precache_generic(g_szRespawn);
    precache_model(bullet_fire_model);
    precache_model(bullet_blank_model);
}

public check_game_state()
{
    new inGame = get_cvar_num("inGame");
    if (inGame == 1 && !g_isGameActive)
    {
        start_game(); // Inicia el juego si "inGame" es 1 y no está activo
    }
    else if (inGame == 0 && g_isGameActive)
    {
        // "inGame" cambió a 0 durante el juego: probable desconexión
        if (is_user_connected(g_player1) && !is_user_connected(g_player2))
        {
            // g_player2 se desconectó, g_player1 gana
            announce_disconnection(g_player2_name, g_player1_name, g_player1);
        }
        else if (!is_user_connected(g_player1) && is_user_connected(g_player2))
        {
            // g_player1 se desconectó, g_player2 gana
            announce_disconnection(g_player1_name, g_player2_name, g_player2);
        }
        else
        {
            // Ambos desconectados o caso inesperado
            ChatPrint(0, "\g[\nBuckshot Roulette\g] \wJuego terminado.");
        }
        g_isGameActive = false; // Detiene el juego
    }
}
public start_game()
{
    new players[32], num;
    get_players(players, num, "h");
    new active_players[32], active_num = 0;
    for (new i = 0; i < num; i++)
    {
        new id = players[i];
        if (cs_get_user_team(id) != CS_TEAM_SPECTATOR)
        {
            active_players[active_num++] = id;
        }
    }

    if (active_num != 2)
    {
        return;
    }

    g_player1 = active_players[0];
    g_player2 = active_players[1];
    g_lives[g_player1] = MAX_LIVES;
    g_lives[g_player2] = MAX_LIVES;
    g_isGameActive = true;
    ChatPrint(0, "\g[\nBuckshot Roulette\g] \g¡El juego ha comenzado!");
    
    // Almacenar nombres de los jugadores
    get_user_name(g_player1, g_player1_name, sizeof(g_player1_name) - 1);
    get_user_name(g_player2, g_player2_name, sizeof(g_player2_name) - 1);

    set_task(2.0, "start_new_round");
}
public announce_disconnection(disconnectedName[], remainingName[], remainingId)
{
    new message[128];
    formatex(message, sizeof(message) - 1, "El contrincante \g%s \rse ha ido\n, \g%s gana por abandono\r.", disconnectedName, remainingName);
    ChatPrint(0, message);

    // Mensaje en HUD para el jugador restante
    formatex(message, sizeof(message) - 1, "El contrincante se ha ido, tú ganas.");
    set_hudmessage(255, 255, 255, 0.50, 0.50, 0, 6.0, 12.0, 0.1, 0.2, -1);
    show_hudmessage(remainingId, message);
}
public start_new_round()
{
    g_totalRounds = random_num(MIN_ROUNDS, MAX_ROUNDS);
    new liveRounds = random_num(1, g_totalRounds - 1);
    new blankRounds = g_totalRounds - liveRounds;

    g_currentRoundIndex = 0;
    for (new i = 0; i < g_totalRounds; i++)
    {
        if (i < liveRounds)
            g_roundSequence[i] = RT_LIVE;
        else
            g_roundSequence[i] = RT_BLANK;
    }

    for (new i = g_totalRounds - 1; i > 0; i--)
    {
        new j = random_num(0, i);
        new temp = g_roundSequence[i];
        g_roundSequence[i] = g_roundSequence[j];
        g_roundSequence[j] = temp;
    }
    ChatPrint(g_player1, "\w[\gNUEVA RONDA\w]");
    ChatPrint(g_player2, "\w[\gNUEVA RONDA\w]");

    ChatPrint(g_player1, "\g[\nRonda\g] \nHay \r%d \nbalas de fuego y \g%d \nde salva.", liveRounds, blankRounds);
    ChatPrint(g_player2, "\g[\nRonda\g] \nHay \r%d \nbalas de fuego y \g%d \nde salva.", liveRounds, blankRounds);

    set_hudmessage(255, 255, 255, 0.01, 0.15, 0, 6.0, 5.0, 0.1, 0.2, -1);
    show_hudmessage(g_player1, "NUEVA RONDA");
    show_hudmessage(g_player2, "NUEVA RONDA");

    new message[128];
    formatex(message, sizeof(message) - 1, "%d balas de fuego y %d de salva", liveRounds, blankRounds);
    set_hudmessage(255, 255, 255, 0.01, 0.20, 0, 6.0, 5.0, 0.1, 0.2, -1);
    show_hudmessage(g_player1, message);
    show_hudmessage(g_player2, message);
    spawn_bullet_entities(liveRounds, blankRounds);
    set_task(3.0, "hide_bullet_entities");

    if (g_keepTurn)
    {
        show_turn_menu(g_currentTurn);
    }
    else
    {
        g_currentTurn = (random_num(0, 1) == 0) ? g_player1 : g_player2;
        show_turn_menu(g_currentTurn);
    }
    g_keepTurn = false;
}
public spawn_bullet_entities(liveRounds, blankRounds)
{
    new positionIndex = 0;

    for (new i = 0; i < liveRounds; i++)
    {
        if (positionIndex >= sizeof(entity_positions))
            break;
        spawn_entity_at_position(entity_positions[positionIndex], bullet_fire_model);
        positionIndex++;
    }

    for (new i = 0; i < blankRounds; i++)
    {
        if (positionIndex >= sizeof(entity_positions))
            break;
        spawn_entity_at_position(entity_positions[positionIndex], bullet_blank_model);
        positionIndex++;
    }
}

public spawn_entity_at_position(Float:origin[3], const model[])
{
    new entity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
    if (entity == -1)
    {
        server_print("[ERROR] No se pudo crear la entidad.");
        return;
    }

    entity_set_string(entity, EV_SZ_classname, "bullet_entity");
    entity_set_model(entity, model);
    entity_set_vector(entity, EV_VEC_origin, origin);
    entity_set_int(entity, EV_INT_solid, SOLID_BBOX);
    entity_set_size(entity, Float:{-16.0, -16.0, -16.0}, Float:{16.0, 16.0, 16.0});

    set_pev(entity, pev_rendermode, kRenderTransAlpha);
    set_pev(entity, pev_renderamt, 0.0);

    set_task(0.1, "bullet_fade_in", entity + 1000, _, _, "b");
}
public bullet_fade_in(taskid)
{
    new entity = taskid - 1000;
    if (!is_valid_ent(entity))
    {
        remove_task(taskid);
        return;
    }

    new Float:alpha;
    pev(entity, pev_renderamt, alpha);
    alpha += 25.0;
    if (alpha >= 255.0)
    {
        alpha = 255.0;
        remove_task(taskid);
        set_task(2.0, "bullet_start_fade_out", entity + 2000);
    }
    set_pev(entity, pev_renderamt, alpha);
}
public bullet_start_fade_out(taskid)
{
    new entity = taskid - 2000;
    if (!is_valid_ent(entity))
        return;

    set_task(0.1, "bullet_fade_out", entity + 3000, _, _, "b");
}

public bullet_fade_out(taskid)
{
    new entity = taskid - 3000;
    if (!is_valid_ent(entity))
    {
        remove_task(taskid);
        return;
    }

    new Float:alpha;
    pev(entity, pev_renderamt, alpha);
    alpha -= 25.0;
    if (alpha <= 0.0)
    {
        alpha = 0.0;
        remove_entity(entity);
        remove_task(taskid);
    }
    else
    {
        set_pev(entity, pev_renderamt, alpha);
    }
}

public hide_bullet_entities()
{
    new entity = -1;
    while ((entity = find_ent_by_class(entity, "info_target")) != 0)
    {
        remove_entity(entity);
    }
}
public show_turn_menu(id)
{
    if (!g_isGameActive || !is_user_alive(id))
        return;

    new opponent = (id == g_player1) ? g_player2 : g_player1;
    new opponentName[32];
    get_user_name(opponent, opponentName, sizeof(opponentName) - 1);

    new currentPlayerName[32];
    get_user_name(id, currentPlayerName, sizeof(currentPlayerName) - 1);

    show_turn_hud(id, currentPlayerName);

    new menu = menu_create("Elige tu acción:", "menu_handler");
    new item[64];
    formatex(item, sizeof(item) - 1, "Disparar a %s", opponentName);
    menu_additem(menu, item, "1");
    menu_additem(menu, "Dispararme a mí mismo", "2");

    menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
    menu_display(id, menu);
}

public show_turn_hud(id, const currentPlayerName[])
{
    new message[128];
    formatex(message, sizeof(message) - 1, "Es tu turno");
    set_hudmessage(255, 255, 255, 0.01, 0.01, 0, 6.0, 12.0, 0.1, 0.2, -1);
    show_hudmessage(id, message);

    new opponent = (id == g_player1) ? g_player2 : g_player1;
    formatex(message, sizeof(message) - 1, "Es turno de %s", currentPlayerName);
    set_hudmessage(255, 255, 255, 0.01, 0.01, 0, 6.0, 12.0, 0.1, 0.2, -1);
    show_hudmessage(opponent, message);
}

public menu_handler(id, menu, item)
{
    if (item == MENU_EXIT || !g_isGameActive)
    {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    new data[6], iName[64], access, callback;
    menu_item_getinfo(menu, item, access, data, sizeof(data) - 1, iName, sizeof(iName) - 1, callback);
    menu_destroy(menu);

    new choice = str_to_num(data);

    if (choice == 1)
    {
        strip_user_weapons(id);
        give_item(id, "weapon_m3");
        new weapon_ent = find_ent_by_owner(-1, "weapon_m3", id);
        cs_set_weapon_ammo(weapon_ent, 1);
        cs_set_user_bpammo(id, CSW_M3, 0);
        g_playerRoundType[id] = g_roundSequence[g_currentRoundIndex];
        ChatPrint(id, "\g[\nTurno\g] \wDispara al oponente cuando estés listo.");
        freeze_player(id);
    }
    else if (choice == 2)
    {
        process_self_shot(id);
    }

    return PLUGIN_HANDLED;
}

public fw_PrimaryAttack_Post(weapon)
{
    new id = get_pdata_cbase(weapon, 41, 4);
    if (!g_isGameActive || id != g_currentTurn)
        return HAM_IGNORED;

    new clip = get_pdata_int(weapon, 51, 4);
    if (clip == 0 && g_playerRoundType[id] != -1)
    {
        process_opponent_shot(id);
        g_playerRoundType[id] = -1;
    }

    return HAM_IGNORED;
}

public process_self_shot(id)
{
    // Iniciar el efecto de temblor repetitivo
    set_task(0.2, "apply_screen_shake", id + 1000, _, _, "b"); // "b" para repetir cada 0.2 segundos
    
    // Programar el fin del temblor y la ejecución de delayed_self_shot
    set_task(2.0, "stop_screen_shake", id + 2000);
}
public apply_screen_shake(taskid)
{
    new id = taskid - 1000; // Recuperar el ID del jugador
    
    // Aplicar un temblor leve
    message_begin(MSG_ONE, g_msgScreenShake, {0,0,0}, id);
    write_short(1<<8);               // Amplitud: 256 (muy leve)
    write_short(FixedUnsigned16(0.2, 1<<12)); // Duración: 0.2 segundos (819 unidades)
    write_short(1<<10);              // Frecuencia: 1024 (lento y sutil)
    message_end();
}

public stop_screen_shake(taskid)
{
    new id = taskid - 2000; // Recuperar el ID del jugador
    
    // Detener el temblor eliminando la tarea repetitiva
    remove_task(id + 1000);
    
    // Ejecutar la función original después de los 2 segundos
    delayed_self_shot(id);
}

// Función auxiliar para convertir flotantes a enteros escalados
stock FixedUnsigned16(Float:flValue, iScale)
{
    new iOutput = floatround(flValue * iScale);
    if (iOutput < 0) iOutput = 0;
    if (iOutput > 0xFFFF) iOutput = 0xFFFF;
    return iOutput;
}

public delayed_self_shot(id)
{
    new opponent = (id == g_player1) ? g_player2 : g_player1;
    
    if (!is_user_connected(id))
    {
        return;
    }

    // Obtener el tipo de ronda y avanzar el índice
    new roundType = g_roundSequence[g_currentRoundIndex];
    g_currentRoundIndex++;

    if (roundType == RT_BLANK)
    {
        // Fue una salva
        client_cmd(id, "spk sound/weapons/dryfire_pistol.wav");
        client_cmd(opponent, "spk sound/weapons/dryfire_pistol.wav");
        ChatPrint(id, "\g[\nTurno\g] \b¡Fue una salva! \nObtienes otro turno.");
        g_keepTurn = true;

        if (g_currentRoundIndex >= g_totalRounds)
        {
            set_task(2.0, "start_new_round");
        }
        else
        {
            set_task(2.0, "show_menu_after_delay", id);
        }
    }
    else
    {
        // Fue un disparo real
        client_cmd(id, "spk sound/weapons/m3-1.wav");
        client_cmd(opponent, "spk sound/weapons/m3-1.wav");
        ChatPrint(id, "\g[\nTurno\g] \r¡Fue de fuego! \nPierdes una vida.");
        screen_fade(opponent, 255, 255, 255, 255, 0.1, 0.0, FFADE_IN);
        g_lives[id]--;
        apply_damage_effect(id);

        if (g_lives[id] <= 0)
        {
            user_kill(id);
            declare_winner(id == g_player1 ? g_player2 : g_player1);
        }
        else
        {
            set_user_health(id, 100);
            ChatPrint(id, "\g[\nVidas\g] \nTe quedan \r%d \nvidas.", g_lives[id]);
            g_keepTurn = false;
            if (g_currentRoundIndex >= g_totalRounds)
            {
                set_task(2.0, "start_new_round");
            }
            else
            {
                set_task(2.0, "delayed_turn_change", id);
            }
        }
    }
}
stock freeze_player(id)
{
    set_pev(id, pev_maxspeed, -1.0);
    set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
}
public show_menu_after_delay(id)
{
    if (g_isGameActive && is_user_alive(id))
    {
        show_turn_menu(id);
    }
}



public process_opponent_shot(id)
{
    new opponent = (id == g_player1) ? g_player2 : g_player1;
    new roundType = g_playerRoundType[id];

    if (roundType == RT_LIVE)
    {
      //  set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0); 
        screen_fade(id, 255, 255, 255, 255, 0.1, 0.0, FFADE_IN);
        set_task(0.1, "revert_screen", id); 
      //  set_task(0.1, "revert_rendering", opponent);
        
        

        ChatPrint(id, "\g[\nTurno\g] \r¡Fue de fuego! \nLe quitaste \runa vida\n a tu oponente.");
    }
    else
    {
        ChatPrint(id,  "\g[\nTurno\g] \b¡Fue una salva! No pasó nada.");
    }

    strip_user_weapons(id);
    freeze_player(id);
    g_currentRoundIndex++;

    if (g_currentRoundIndex >= g_totalRounds)
    {
       set_task(2.0, "start_new_round");
    }
    else
    {
        set_task(2.0, "delayed_turn_change", id);
    }
}
public revert_rendering(id)
{
    set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
}
public revert_screen(id)
{
    screen_fade(id, 1, 0, 0, 0, 0, 0, 0); // Volver a transparente
}
public delayed_turn_change(id)
{
    if (g_isGameActive)
    {
        new next_player = (id == g_player1) ? g_player2 : g_player1;
        g_currentTurn = next_player;
        show_turn_menu(g_currentTurn);
    }
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
    if (!g_isGameActive || victim != g_player1 && victim != g_player2 || attacker != g_currentTurn)
        return HAM_IGNORED;

    if (g_playerRoundType[attacker] == RT_BLANK)
    {
        SetHamParamFloat(4, 0.0); // No daño si es bala de salva
        return HAM_SUPERCEDE;
    }
    else if (g_playerRoundType[attacker] == RT_LIVE)
    {
        g_lives[victim]--;
        apply_damage_effect(victim);
        make_invisible_and_fade(victim); // Añadir efecto de invisibilidad

        if (g_lives[victim] <= 0)
        {
            user_kill(victim); // Forzar la muerte
            return HAM_SUPERCEDE; // Prevenir procesamiento adicional
        }
        else
        {
            set_task(0.1, "reset_health", victim);
            ChatPrint(victim, "\g[\nVidas\g] \nTe quedan \r%d \nvidas.", g_lives[victim]);
            return HAM_SUPERCEDE;
        }
    }

    return HAM_IGNORED;
}

public reset_health(id)
{
    if (is_user_alive(id))
        set_user_health(id, 100);
}

public apply_damage_effect(id)
{
    client_cmd(id, "mp3 stop");
    client_cmd(id, "mp3 play %s", g_szRespawn);

    screen_fade(id, 255, 255, 255, 255, 0.1, 0.2, FFADE_OUT);
    set_task(0.3, "apply_black_fade", id);
    set_task(1.7, "play_general_sound", id);
    make_invisible_and_fade(id);
}
public make_invisible_and_fade(id)
{
    // Hacer al jugador completamente invisible
    set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0);
    g_fade_alpha[id] = 0; // Asegurar que el alpha inicial sea 0
    
    // Programar el inicio del efecto de aparición después de 1 segundo
    set_task(10.0, "start_fade", id);
}

public start_fade(id)
{

   
    // Iniciar la tarea repetitiva para el efecto de aparición gradual
    set_task(0.1, "fade_task", id + 1000, _, _, "b"); // "b" para repetir indefinidamente
}

public fade_task(taskid)
{
    new id = taskid - 1000; // Recuperar el ID real del jugador
    

    
    // Incrementar el alpha en 12 por cada paso
    g_fade_alpha[id] += 12;
    
    // Si el alpha alcanza o supera 255, fijarlo en 255 y detener la tarea
    if (g_fade_alpha[id] >= 255)
    {
        g_fade_alpha[id] = 255;
        remove_task(taskid);
    }
    
    // Aplicar el nuevo valor de alpha al renderizado del jugador
    set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, g_fade_alpha[id]);
}

public apply_black_fade(id)
{
    screen_fade(id, 0, 0, 0, 255, 0.5, 1.2, FFADE_IN);
}

public play_general_sound(id)
{
    client_cmd(id, "mp3 loop sound/generalReleaseInGame.mp3");
}

public screen_fade(id, red, green, blue, alpha, Float:fadeTime, Float:holdTime, flags)
{
    static msgid;
    if (!msgid) msgid = get_user_msgid("ScreenFade");
    if (!msgid) return;

    message_begin(MSG_ONE_UNRELIABLE, msgid, _, id);
    write_short(floatround(4096.0 * fadeTime));
    write_short(floatround(4096.0 * holdTime));
    write_short(flags);
    write_byte(red);
    write_byte(green);
    write_byte(blue);
    write_byte(alpha);
    message_end();
}

public event_death()
{
    if (!g_isGameActive)
        return;

    new victim = read_data(2);
    new attacker = read_data(1);

    if ((victim == g_player1 && attacker == g_player2) || (victim == g_player2 && attacker == g_player1))
    {
        declare_winner(attacker);
    }
}

public declare_winner(winner)
{
    new winnerName[32];
    get_user_name(winner, winnerName, sizeof(winnerName) - 1);
    ChatPrint(0, "\g[\nBuckshot Roulette\g] \w%s \gha ganado el juego\w!", winnerName);

    new message[128];
    formatex(message, sizeof(message) - 1, "%s es el ganador!", winnerName);
    set_hudmessage(255, 255, 255, 0.50, 0.50, 0, 6.0, 12.0, 0.1, 0.2, -1);
    show_hudmessage(0, message);

    g_isGameActive = false;
    set_cvar_num("inGame", 0);
}

public client_disconnected(id)
{
    if (g_isGameActive && (id == g_player1 || id == g_player2))
    {
        declare_winner(id == g_player1 ? g_player2 : g_player1);
    }
}