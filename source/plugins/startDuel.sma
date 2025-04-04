#include <amxmodx>
#include <fun>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <amxmisc> 
#include <ChatPrint>

new const Float:player1_spawn[3] = {-170.000137, -4.720420, 36.031250};
new const Float:player2_spawn[3] = { 2.031250, -2.873109, 36.031250};

new player1 = 0;
new player2 = 0;
new bool:isWaitingMessageShown = false;
new taskID_checkPlayerCount;
new waitingMessageCount = 0;
new bool:isWaitSoundPlaying = false;
new g_cvarInGame

new g_last_winner = 0;
new g_last_loser = 0;
new g_rematch_decision[33]; // -1: no decidido, 0: no, 1: sí
new bool:g_rematch_processed = false;
new g_waiting_message_task;
new g_rematch_timer;
new bool:g_isGameActive = false;

new const g_szWaitSound[] = "sound/blankShellStart.mp3";
new const g_szGameSound[] = "sound/generalReleaseInGame.mp3";
new const g_szRespawn[] = "sound/generalReleaseInGame.mp3";
new const g_szRevancha[] = "sound/revancha.mp3";
new g_loser_name[32];       // Array para almacenar el nombre del perdedor


public plugin_init()
{
    register_plugin("Player Roles and Spawns with Sounds", "1.0", "Linkmail16");
    register_event("DeathMsg", "event_death", "a");
    register_event("TextMsg", "event_spawn", "a", "2=Spawn");
    register_event("HLTV", "event_connect", "a", "1=0");
    
    taskID_checkPlayerCount = set_task(1.0, "check_player_count", _, _, _, "b");
    g_cvarInGame = register_cvar("inGame", "0");
}

public plugin_precache()
{
    precache_generic(g_szWaitSound);
    precache_generic(g_szGameSound);
    precache_generic(g_szRespawn);
    precache_generic(g_szRevancha);
}

public event_connect(id)
{
   // client_print(id, print_chat, "Bienvenido al servidor.");
}

public check_player_count()
{
    new players[32], num;
    get_players(players, num, "h"); 

    new active_players[32], active_num = 0;
    for(new i = 0; i < num; i++)
    {
        new id = players[i];
        if(cs_get_user_team(id) != CS_TEAM_SPECTATOR && is_user_alive(id))
        {
            active_players[active_num++] = id;
        }
    }

    if(active_num == 1)
    {
        if(!player1)
        {
            player1 = active_players[0];
            turn(player1, 180, 1);
        }

        if(!isWaitingMessageShown && waitingMessageCount < 3)
        {
            show_waiting_message();
        }
    }
    else if(active_num == 2)
    {
        if(!player1 || !player2)
        {
            // Resetear variables de revancha al iniciar un nuevo juego
            reset_rematch_variables();
            
            player1 = active_players[0];
            player2 = active_players[1];
            
            // Verificar que ambos jugadores están vivos
            if(is_user_alive(player1) && is_user_alive(player2))
            {
                client_print(player1, print_center, "Eres el Jugador 1");
                client_print(player2, print_center, "Eres el Jugador 2");
                
                // Detener el sonido de espera para player1
                client_cmd(player1, "mp3 stop");
                spawn_players();
                turn(player1, 180, 1);
                turn(player2, 180, 1);
                
                // Programar el sonido del juego después de 2 segundos
                set_task(2.0, "play_game_sound", 0);

                // Depuración: Mostrar en chat quién es cada jugador
                ChatPrint(player1, "\wEres el Jugador \r1");
                ChatPrint(player2, "\wEres el Jugador \r2");

                set_cvar_num("inGame", 1);
            }
            else
            {
                // Si algún jugador no está vivo, no iniciar el juego
                player1 = 0;
                player2 = 0;
            }
        }
    }
    else if(active_num > 2)
    {
        client_print(0, print_chat, "Advertencia: Más de 2 jugadores en equipos de juego.");
    }
}
public show_waiting_message()
{
    if(player1)
    {
        set_hudmessage(255, 0, 0, 0.50, 0.25, 2, 0.1, 5.0, 0.1, 0.2, -1);
        show_hudmessage(player1, "Esperando al contrincante");
        set_cvar_num("inGame", 0);
        // Reproducir el sonido solo si no está ya reproduciéndose
        if(!isWaitSoundPlaying)
        {
            client_cmd(player1, "mp3 play %s", g_szWaitSound);
            isWaitSoundPlaying = true; // Marcar que el sonido ya está sonando
        }
        isWaitingMessageShown = true;
        waitingMessageCount++;
        set_task(5.0, "reset_waiting_message");
    }
}

public reset_waiting_message()
{
    isWaitingMessageShown = false;
}

public play_game_sound()
{
    if(player1 && player2)
    {
        client_cmd(player1, "mp3 loop %s", g_szGameSound);
        client_cmd(player2, "mp3 loop %s", g_szGameSound);
    }
}

public play_waitSound2()
{
    if(player1 && player2)
    {
        client_cmd(player1, "mp3 play %s", g_szRevancha);
        client_cmd(player1, "mp3 play %s", g_szRevancha);
    }
}

public spawn_players()
{
    if(player1)
    {
        
        entity_set_origin(player1, player1_spawn);
    }
    if(player2)
    {
        
        entity_set_origin(player2, player2_spawn);
    }
}

public event_spawn()
{
    if(player1)
    {
        
        entity_set_origin(player1, player1_spawn);
    }
    if(player2)
    {
       
        entity_set_origin(player2, player2_spawn);
    }
}

public event_death()
{
    new killer = read_data(1);
    new victim = read_data(2);

    if ((victim == player1 && killer == player2) || (victim == player2 && killer == player1))
    {
        declare_winner(killer);
    }
    else if (victim == player1 || victim == player2)
    {
        // Declarar al otro jugador como ganador si sigue vivo
        if (victim == player1 && is_user_alive(player2))
        {
            declare_winner(player2);
        }
        else if (victim == player2 && is_user_alive(player1))
        {
            declare_winner(player1);
        }
    }

    if(player1) client_cmd(player1, "mp3 stop");
    if(player2) client_cmd(player2, "mp3 stop");
    client_cmd(player1, "mp3 play sound/revancha.mp3");
    client_cmd(player2, "mp3 play sound/revancha.mp3");
    player1 = 0;
    player2 = 0;
    waitingMessageCount = 0;
}
public declare_winner(winner)
{
    new loser = (winner == player1) ? player2 : player1;
    g_last_winner = winner;
    get_user_name(loser, g_loser_name, sizeof(g_loser_name) - 1);
    // Limpiar cualquier estado previo de revancha
    for (new i = 1; i <= 32; i++)
    {
        g_rematch_decision[i] = -1; // Reestablecer a "no decidido" para todos los jugadores
    }
    g_rematch_processed = false;
    
    if (g_waiting_message_task)
        remove_task(g_waiting_message_task);
    if (g_rematch_timer)
        remove_task(g_rematch_timer);
        
    g_waiting_message_task = 0;
    g_rematch_timer = 0;
    
    // Ahora proceder con la declaración de ganador
    new winnerName[32];
    get_user_name(winner, winnerName, sizeof(winnerName) - 1);
    ChatPrint(0, "\g[\nBuckshot Roulette\g] \w%s \gha ganado el juego\w!", winnerName);
 

    new message[128];
    formatex(message, sizeof(message) - 1, "%s es el ganador!", winnerName);
    set_hudmessage(255, 255, 255, 0.50, 0.50, 0, 6.0, 12.0, 0.1, 0.2, -1);
    show_hudmessage(0, message);

    g_last_winner = winner;
    g_last_loser = (winner == player1) ? player2 : player1;

    g_isGameActive = false;
    set_cvar_num("inGame", 0);

    set_task(1.0, "ask_for_rematch");
    set_task(2.0, "play_waitSound2");
}
stock find_player_by_name(const name[])
{
    new players[32], numPlayers;
    get_players(players, numPlayers);
    
    for (new i = 0; i < numPlayers; i++)
    {
        new playerName[32];
        get_user_name(players[i], playerName, sizeof(playerName) - 1);
        if (equal(playerName, name))
        {
            return players[i];
        }
    }
    return -1;
}
public ask_for_rematch()
{
    // Asegurarnos de que todas las variables de voto estén limpias antes de iniciar
    for (new i = 1; i <= 32; i++)
    {
        g_rematch_decision[i] = -1; // Reestablecer a "no decidido" para todos los jugadores
    }
    
    g_rematch_processed = false;
    
    // Después de limpiar las variables, mostrar el menú
    if (is_user_connected(g_last_winner))
        show_rematch_menu(g_last_winner);
    if (is_user_connected(g_last_loser))
        show_rematch_menu(g_last_loser);
    
    // Establecer el temporizador de revancha
  //  g_rematch_timer = set_task(60.0, "rematch_timer_expired");
    
    // Iniciar la tarea para mostrar los mensajes de espera
    g_waiting_message_task = set_task(1.0, "show_rematch_waiting_message", _, _, _, "b");
}

public show_rematch_menu(id)
{
    if (!is_user_connected(id))
        return;

    new menu = menu_create("¿Deseas una revancha?", "rematch_menu_handler");
    menu_additem(menu, "Sí", "1");
    menu_additem(menu, "No", "0");
    menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
    menu_display(id, menu);
}

public rematch_menu_handler(id, menu, item)
{
    if (!is_user_connected(id))
        return PLUGIN_HANDLED;

    if (item == MENU_EXIT)
    {
        // Si el usuario intenta salir del menú, contarlo como un "no"
        g_rematch_decision[id] = 0;
        menu_destroy(menu);
        check_rematch_decisions();
        return PLUGIN_HANDLED;
    }

    new data[6], iName[64], access, callback;
    menu_item_getinfo(menu, item, access, data, sizeof(data)-1, iName, sizeof(iName)-1, callback);
    menu_destroy(menu);

    new choice = str_to_num(data);
    g_rematch_decision[id] = choice;

    // Notificar a todos sobre la decisión
    new player_name[32];
    get_user_name(id, player_name, sizeof(player_name)-1);
    
    if (choice == 1)
    {
        ChatPrint(0, "\g[\nBuckshot Roulette\g] \w%s \gha aceptado la revancha\w.", player_name);
        
        // Si este jugador es el segundo en aceptar, procesar inmediatamente
        new other_id = (id == g_last_winner) ? g_last_loser : g_last_winner;
        if (g_rematch_decision[other_id] == 1)
        {
            remove_task(g_rematch_timer);
            check_rematch_decisions();
        }
    }
    else
    {
        ChatPrint(0,  "\g[\nBuckshot Roulette\g] \g%s \rha rechazado la revancha\w.", player_name);
        // Si un jugador rechaza, terminamos inmediatamente el proceso
        remove_task(g_rematch_timer);
        check_rematch_decisions();
    }

    return PLUGIN_HANDLED;
}
public show_rematch_waiting_message()
{
    // Si ya se procesó la decisión, no mostrar mensajes
    if (g_rematch_processed)
    {
        remove_task(g_waiting_message_task);
        return;
    }

    // Si algún jugador ya rechazó, no necesitamos esperar más
    if (g_rematch_decision[g_last_winner] == 0 || g_rematch_decision[g_last_loser] == 0)
    {
        remove_task(g_waiting_message_task);
        check_rematch_decisions();
        return;
    }
    
    // Si los dos aceptaron, procesar inmediatamente
    if (g_rematch_decision[g_last_winner] == 1 && g_rematch_decision[g_last_loser] == 1)
    {
        remove_task(g_waiting_message_task);
        check_rematch_decisions();
        return;
    }

    // Mostrar mensaje personalizado según quién ha votado
    if (g_rematch_decision[g_last_winner] == -1 && is_user_connected(g_last_winner)) 
    {
        // El ganador no ha votado, mostrarle que falta por decidir
        new message[128];
        formatex(message, sizeof(message) - 1, "Faltas tu por decidir");
        set_hudmessage(255, 255, 255, 0.01, 0.01, 0, 6.0, 1.0, 0.1, 0.2, -1);
        show_hudmessage(g_last_winner, message);
        
        // Si el perdedor ya votó, mostrarle mensaje de espera
        if (g_rematch_decision[g_last_loser] != -1 && is_user_connected(g_last_loser)) 
        {
            new winner_name[32];
            get_user_name(g_last_winner, winner_name, sizeof(winner_name) - 1);
            formatex(message, sizeof(message) - 1, "Esperando a que %s decida", winner_name);
            set_hudmessage(255, 255, 255, 0.01, 0.01, 0, 6.0, 1.0, 0.1, 0.2, -1);
            show_hudmessage(g_last_loser, message);
        }
    }
    else if (g_rematch_decision[g_last_loser] == -1 && is_user_connected(g_last_loser)) 
    {
        // El perdedor no ha votado, mostrarle que falta por decidir
        new message[128];
        formatex(message, sizeof(message) - 1, "Faltas tu por decidir");
        set_hudmessage(255, 255, 255, 0.01, 0.01, 0, 6.0, 1.0, 0.1, 0.2, -1);
        show_hudmessage(g_last_loser, message);
        
        // Si el ganador ya votó, mostrarle mensaje de espera
        if (g_rematch_decision[g_last_winner] != -1 && is_user_connected(g_last_winner)) 
        {
            new loser_name[32];
            get_user_name(g_last_loser, loser_name, sizeof(loser_name) - 1);
            formatex(message, sizeof(message) - 1, "Esperando a que %s decida", loser_name);
            set_hudmessage(255, 255, 255, 0.01, 0.01, 0, 6.0, 1.0, 0.1, 0.2, -1);
            show_hudmessage(g_last_winner, message);
        }
    }
}

public rematch_timer_expired()
{
    // Si el juego ya está en curso, no hacer nada
    if (get_cvar_num("inGame") == 1 || g_rematch_processed || g_last_winner == 0 || g_last_loser == 0)
    {
        return;
    }
    
    if (is_user_connected(g_last_winner) && g_rematch_decision[g_last_winner] == -1)
    {
        g_rematch_decision[g_last_winner] = 0;
    }
    if (is_user_connected(g_last_loser) && g_rematch_decision[g_last_loser] == -1)
    {
        g_rematch_decision[g_last_loser] = 0;
    }

    client_print(0, print_chat, "[Buckshot Roulette] Se ha agotado el tiempo para la revancha.");
    check_rematch_decisions();
}
public check_rematch_decisions()
{
    if (g_rematch_processed)
        return;

    // Verificar si ambos jugadores aún están conectados
    if (!is_user_connected(g_last_winner) || !is_user_connected(g_last_loser))
    {
        if (!is_user_connected(g_last_winner))
        {
            g_rematch_decision[g_last_winner] = 0;
        }
        if (!is_user_connected(g_last_loser))
        {
            g_rematch_decision[g_last_loser] = 0;
        }
    }

    // Contador de votos
    new accept_votes = 0;
    new reject_votes = 0;
    
    if (g_rematch_decision[g_last_winner] == 1) accept_votes++;
    if (g_rematch_decision[g_last_loser] == 1) accept_votes++;
    if (g_rematch_decision[g_last_winner] == 0) reject_votes++;
    if (g_rematch_decision[g_last_loser] == 0) reject_votes++;
    
    // Depuración: Mostrar estado de votos
    server_print("Votos de aceptación: %d, Votos de rechazo: %d", accept_votes, reject_votes);

    // Procesar si ambos aceptaron o hay un rechazo
    if (accept_votes == 2 || reject_votes > 0)
    {
        g_rematch_processed = true;
        server_print("Procesando decisión de revancha...");

    if (reject_votes > 0)
    {
    ChatPrint(0, "\g[\nBuckshot Roulette\g] \rRevancha rechazada\w.");
    
    new loser_id = find_player_by_name(g_loser_name);
    if (loser_id != -1 && is_user_connected(loser_id))
    {
    new loser_name[32];
    get_user_name(loser_id, loser_name, sizeof(loser_name) - 1);
    ChatPrint(0, "\g[\nBuckshot Roulette\g] \g%s \rserá expulsado del servidor\w.", loser_name);
    
    new userid = get_user_userid(loser_id);
    if (userid != -1)
    {
        server_cmd("kick #%d", userid);
    }
    }  
    }     
        else if (accept_votes == 2)
        {
            // Ambos aceptaron la revancha
            set_cvar_num("inGame", 1);
            player1 = g_last_winner;
            player2 = g_last_loser;
            
            // Resetear variables
            g_last_winner = 0;
            g_last_loser = 0;
            g_rematch_processed = true;
            
            // Cancelar tareas pendientes
            if (g_waiting_message_task)
                remove_task(g_waiting_message_task);
            if (g_rematch_timer)
                remove_task(g_rematch_timer);
            
            // Respawn de los jugadores
            if (is_user_connected(player1))
                ExecuteHam(Ham_CS_RoundRespawn, player1);
            if (is_user_connected(player2))
                ExecuteHam(Ham_CS_RoundRespawn, player2);
                
            // Informar a los jugadores
            ChatPrint(0, "\b[\wBuckshot Roulette\b] \g¡Revancha aceptada! \bEl juego comienza de nuevo\w.");
            
            // Mover a los jugadores a sus posiciones
            spawn_players();
            
            // Programar el sonido del juego
            set_task(2.0, "play_game_sound", 0);
        }
        
        // Reiniciar variables
        g_rematch_decision[g_last_winner] = -1;
        g_rematch_decision[g_last_loser] = -1;
        g_rematch_processed = false;
        
        // Limpiar tareas pendientes
        remove_task(g_waiting_message_task);
        remove_task(g_rematch_timer);
    }
    else
    {
        server_print("Aún no hay suficientes votos para procesar.");
    }
}

public kickear_perdedor(task_data[])
{
    new id = task_data[0];
    if (is_user_connected(id))
    {
        new userid = get_user_userid(id);
        if (userid != -1)
        {
            server_print("Expulsando al jugador con ID %d y userid %d", id, userid);
            server_cmd("kick #%d", userid);
        }
        else
        {
            server_print("No se pudo obtener el userid para el jugador ID %d", id);
        }
    }
    else
    {
        server_print("El jugador ID %d no está conectado.", id);
    }
}

public reset_rematch_variables()
{
    // Resetear todas las variables relacionadas con la revancha
    g_last_winner = 0;
    g_last_loser = 0;
    g_rematch_processed = false;
    
    // Resetear TODAS las decisiones de revancha para todos los jugadores
    for (new i = 1; i <= 32; i++)
    {
        g_rematch_decision[i] = -1;
    }
    
    // Eliminar todas las tareas relacionadas con la revancha
    if (g_waiting_message_task)
        remove_task(g_waiting_message_task);
    if (g_rematch_timer)
        remove_task(g_rematch_timer);
        
    // Imprimir un mensaje de depuración
    server_print("Todas las variables de revancha han sido reseteadas");
}

public turn(player, nbDegrees, direction)
{
    new Float:pLook[3];
    entity_get_vector(player, EV_VEC_angles, pLook);

    switch(direction)
    {
        case 0: pLook[1] -= float(nbDegrees); // Derecha
        case 1: pLook[1] += float(nbDegrees); // Izquierda
    }

    entity_set_vector(player, EV_VEC_angles, pLook);
    entity_set_int(player, EV_INT_fixangle, 1);

    return PLUGIN_CONTINUE;
}