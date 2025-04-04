#include <amxmodx> 
#include <fakemeta> 

public plugin_init() { 
    register_plugin("Block Kill Command", "1.0", "xPaw"); 
    register_forward(FM_ClientKill, "fwdClientKill"); 
} 

public fwdClientKill(id) { 
    if(!is_user_alive(id)) 
        return FMRES_IGNORED; 

    client_print(id, print_console, "No puedes matarte, no seas tramposo."); 
    return FMRES_SUPERCEDE; 
} 