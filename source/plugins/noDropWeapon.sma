#include <amxmodx>

public plugin_init() {
    register_plugin("Disable drop weapon", "0.1", "themike007")
    
    register_clcmd("drop", "cmd_drop")
}

public cmd_drop(id) {
    return PLUGIN_HANDLED;
} 