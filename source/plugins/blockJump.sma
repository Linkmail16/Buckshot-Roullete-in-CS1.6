#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fakemeta>

#define VERSION "0.0.1"

public plugin_init()
{
    register_plugin("No Jump and Duck", VERSION, "ConnorMcLeod & Assistant")
    
    // Registrar el bloqueo del salto
    RegisterHam(Ham_Player_Jump, "player", "Player_Jump")
    // Registrar el bloqueo del agachado
    RegisterHam(Ham_Player_PreThink, "player", "Player_PreThink")
}

public Player_Jump(id)
{
    static iOldbuttons;
    iOldbuttons = entity_get_int(id, EV_INT_oldbuttons)
    if (!(iOldbuttons & IN_JUMP))
    {
        entity_set_int(id, EV_INT_oldbuttons, iOldbuttons | IN_JUMP)
        return HAM_HANDLED
    }
    return HAM_IGNORED
}

public Player_PreThink(id)
{
    // Obtener los botones que el jugador está presionando
    new buttons = pev(id, pev_button)
    // Si IN_DUCK está presionado, quitarlo
    if (buttons & IN_DUCK)
    {
        buttons &= ~IN_DUCK
        set_pev(id, pev_button, buttons)
    }
}