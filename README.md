# Buckshot Roullete in CS 1.6

**Buckshot Roullete in CS 1.6** es un plugin de AMX Mod X para Counter-Strike 1.6 que trae la emoción de "Buckshot Roullete" a enfrentamientos PvP. En este proyecto, no juegas contra una máquina, sino que te enfrentas a un jugador real. Además, el código fuente está disponible para quienes quieran mejorarlo o personalizarlo, y también puedes descargar el plugin listo para usar.

## Instalación

1. **Descargar el plugin:**  
   Descarga el plugin compilado o clona el repositorio para obtener el código fuente.

2. **Instalación en CS1.6:**  
   - Copia los archivos `.sma` o `.amxx` en la carpeta correspondiente de tu servidor de CS 1.6.
   - Asegúrate de incluir todos los plugins y complementos mencionados.

## Para desarrolladores:

### Plugins Principales

- **inGame.sma**  
  - Maneja la funcionalidad principal durante el duelo.

- **startDuel.sma**  
  - Gestiona el estado del juego en la fase de inicio del duelo.
  - Se encarga de las revanchas y la transición entre rondas cuando hay un solo jugador.
  - Teletransporta a los jugadores a posiciones predefinidas.

### Plugins de Ayuda

- **blockJump.sma**  
  - Bloquea el salto de los jugadores para que se mantengan en sus posiciones.

- **forceCt2.sma**  
  - Obliga a los dos primeros jugadores a estar en el equipo CT.
  - Congela a los jugadores para mantener la posición y oculta parte del HUD.
  - Los jugadores adicionales se envían al equipo de espectadores.

- **noDropWeapon.sma**  
  - Impide que los jugadores suelten sus armas, asegurando que la acción no se interrumpa.

- **noKill.sma**  
  - Bloquea el comando de suicidio (`kill`) para evitar que los jugadores terminen prematuramente el juego.


## Uso

- **Para usuarios finales:**  
  Descarga el plugin compilado, colócalo en tu servidor y disfruta del duelo PvP.

- **Para desarrolladores:**  
  Si deseas modificar o mejorar el código, el repositorio incluye el código fuente completo. Puedes contribuir con mejoras, reportar errores o sugerir nuevas características.

## Nota 

Me falta añadir el uso de items como en el juego real, items para curar vida, tiro de doble de daño, robar turno, ver la ronda actual, tirar una ronda, etc...

Cualquiera es libre de usar o mejorar este plugin



