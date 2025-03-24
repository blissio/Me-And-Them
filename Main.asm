


.386
.model flat, stdcall
.stack 4096

; Windows API Function Declarations
; ExitProcess: Terminates the program with a status code
ExitProcess PROTO, dwExitCode:dword

; PlaySoundA: Windows multimedia function for playing audio
; Parameters:
; - pszSound: Pointer to sound file name or memory location
; - hmod: Handle to module containing audio resource (NULL for file)
; - fdwSound: Flags controlling playback behavior
PlaySoundA PROTO,
    pszSound:PTR BYTE,
    hmod:DWORD,
    fdwSound:DWORD

; Sound Playback Configuration Flags
; These control how the sound system behaves
SND_ASYNC       = 0001h    ; Play asynchronously (don't block program execution)
SND_LOOP        = 0008h    ; Loop the sound continuously
SND_FILENAME    = 00020000h ; pszSound points to a file name

; Include necessary library files
; Irvine32: Provides basic I/O and utility functions
; Macros: Assembly language macro definitions
; Winmm: Windows multimedia functions
Include Irvine32.inc
Include Macros.inc
includelib Winmm.lib

; Data Segment
; Contains all program variables, constants, and data structures
.data
    ; Audio System Variables
    soundFile BYTE "Amiga500.wav", 0      ; Path to background music file
    isMuted BYTE 0                     ; Mute state flag (0=unmuted, 1=muted)
    muteMessage BYTE "Press M to toggle music", 0  ; Mute control instruction
    mutedStatus BYTE "Music: MUTED", 0            ; Status when music is muted
    unmutedStatus BYTE "Music: PLAYING", 0        ; Status when music is playing

    ; Core Game State Variables
    gameState BYTE 0        ; Current game state (0=Menu, 1=Game, 2=Instructions)
    selectedOption BYTE 1   ; Currently selected menu option
    inputChar BYTE ?        ; Storage for keyboard input
    currentScene BYTE 1     ; Current game scene (1=Left Room, 2=Center Room, 3=Right Room)

    ; Movement and Screen Boundary Constants
    BORDER_LEFT     = 7     ; Leftmost allowed player position
    BORDER_RIGHT    = 78    ; Rightmost allowed player position
    BORDER_TOP      = 9     ; Highest allowed player position
    BORDER_BOTTOM   = 14    ; Lowest allowed player position

    ; Scene Transition and Spawn Point Constants
    TRANSITION_Y_MIN = 12    ; Minimum Y position for room transition
    TRANSITION_Y_MAX = 14    ; Maximum Y position for room transition
    SPAWN_Y = 12            ; Default Y position when entering a room
    LEFT_SPAWN_X = 70       ; X position when entering from left
    RIGHT_SPAWN_X = 15      ; X position when entering from right

    ; Player Position Variables
    playerX BYTE 40         ; Current player X coordinate
    playerY BYTE 12         ; Current player Y coordinate

    ; Title Screen ASCII Art
    ; Each line of the title graphic is stored separately
    titleArt1 BYTE "    __  ___                        __   __  __                 ", 0
    titleArt2 BYTE "   /  |/  /__     ____ _____  ____/ /  / /_/ /_  ___  ____ ___ ", 0
    titleArt3 BYTE "  / /|_/ / _ \   / __ `/ __ \/ __  /  / __/ __ \/ _ \/ __ `__ \", 0
    titleArt4 BYTE " / /  / /  __/  / /_/ / / / / /_/ /  / /_/ / / /  __/ / / / / /", 0
    titleArt5 BYTE "/_/  /_/\___/   \__,_/_/ /_/\__,_/   \__/_/ /_/\___/_/ /_/ /_/ ", 0

    ; Main Menu Options
    ; Text for each menu choice and prompt
    menuOption1 BYTE "1. Start Game", 0
    menuOption2 BYTE "2. Instructions", 0
    menuOption3 BYTE "3. Exit", 0
    pressKeyPrompt BYTE "Press the corresponding number to select an option", 0
    
    ; Game Control Instructions
    ; Display of available controls to player
    controlsText BYTE "Controls: WASD - Move, ESC - Pause Menu, M - Toggle Music", 0
    optionsTitle BYTE "Game Controls and Help", 0

    ; Pause Menu Components
    ; Text elements for the pause screen
    pauseTitle BYTE "    - PAUSED -    ", 0
    continueText BYTE "1. Continue Game", 0
    exitText BYTE "2. Exit to Menu", 0
    pausePrompt BYTE "Press the corresponding number", 0
    
    ; Border Characters for UI Elements
    ; Used to draw boxes and boundaries
    borderHorizontal BYTE "-", 0
    borderVertical BYTE "|", 0
    borderCorner BYTE "+", 0

    ; Dialog System Elements
    ; Prompt for continuing dialogue
    continuePrompt BYTE "Press SPACE to continue", 0

    ; Scene Layouts
    ; ASCII art for each room in the game

    ; Scene 1: Center Room (Temple) Layout
    ; Complete ASCII art representation of the temple room
    sceneTemple1  BYTE "      +------------------------------------------------------------------------+", 0  
    sceneTemple2  BYTE "      |            +------------+                                              |", 0
    sceneTemple3  BYTE "      |            |   ,-""-.    |                                              |", 0
    sceneTemple4  BYTE "      |            |  /      \  |                                              |", 0
    sceneTemple5  BYTE "      |            | | ( -- ) | |                                              |", 0
    sceneTemple6  BYTE "      |            |  \      /  |                                              |", 0
    sceneTemple7  BYTE "      |            |   `-..-'   |                       ________               |", 0
    sceneTemple8  BYTE "      |            +------------+                      |        |              |", 0
    sceneTemple9  BYTE "      |------------------------------------------------+--------+--------------|", 0
    sceneTemple10 BYTE "      |                                                                        |", 0
    sceneTemple11 BYTE "      |                                                                        |", 0
    sceneTemple12 BYTE "     _|                                                                        |_", 0
    sceneTemple13 BYTE "    |                                                                            |", 0
    sceneTemple14 BYTE "      |                                                                        |", 0
    sceneTemple15 BYTE "      |                                                                        |", 0
    sceneTemple16 BYTE "      +------------------------------------------------------------------------+", 0

    ; Scene 2: Right Room (Door) Layout
    ; Complete ASCII art representation of the door room
    sceneDoor1  BYTE "      +------------------------------------------------------------------------+", 0  
    sceneDoor2  BYTE "      |   +------------------------------------+                               |", 0
    sceneDoor3  BYTE "      |   |   ~~          _/\\_          ~~~   |                               |", 0
    sceneDoor4  BYTE "      |   |       ~      ( -,- )       ~       |                               |", 0
    sceneDoor5  BYTE "      |   |     ~~      ==\\__/==       ~~~~~  |     _____________             |", 0
    sceneDoor6  BYTE "      |   |                |||                 |    | |/|\|/|\|/|\|            |", 0
    sceneDoor7  BYTE "      |   | ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|    | | | | | | | |            |", 0
    sceneDoor8  BYTE "      |   +------------------------------------+    | | | | | | | |            |", 0
    sceneDoor9  BYTE "      |---------------------------------------------|-|-|-|-|-|-|-|------------|", 0
    sceneDoor10 BYTE "      |                                                                        |", 0
    sceneDoor11 BYTE "      |                                                                        |", 0
    sceneDoor12 BYTE "     _|                                                                        |", 0
    sceneDoor13 BYTE "    |                                                                          |", 0
    sceneDoor14 BYTE "      |                                                                        |", 0
    sceneDoor15 BYTE "      |                                                                        |", 0
    sceneDoor16 BYTE "      +------------------------------------------------------------------------+", 0

    ; Scene 3: Left Room Layout
    ; Complete ASCII art representation of the left room
    sceneLeft1  BYTE "      +------------------------------------------------------------------------+", 0  
    sceneLeft2  BYTE "      |                                                                        |", 0
    sceneLeft3  BYTE "      |                       +------------------------+                       |", 0
    sceneLeft4  BYTE "      |      _______________  |        _/\\_           |  _______________      |", 0
    sceneLeft5  BYTE "      |      |||||||||||||||  |       ( U_U )          |  |  ||||||||||||      |", 0
    sceneLeft6  BYTE "      |      |||||||||||||||  |       |\\__/=/         |  ||||||||||/||||      |", 0
    sceneLeft7  BYTE "      |      |//////||||||||  |         |||            |  |||  ||||||||||      |", 0
    sceneLeft8  BYTE "      |      ||||||\|//|||||  +------------------------+  |||||| ||||||||      |", 0
    sceneLeft9  BYTE "      |------|______|______|------------------------------|______|______|------|", 0
    sceneLeft10 BYTE "      |                                                                        |", 0
    sceneLeft11 BYTE "      |                                                                        |", 0
    sceneLeft12 BYTE "      |                                                                        |_", 0
    sceneLeft13 BYTE "      |                                                                          |", 0
    sceneLeft14 BYTE "      |                                                                        |", 0
    sceneLeft15 BYTE "      |                                                                        |", 0
    sceneLeft16 BYTE "      +------------------------------------------------------------------------+", 0

    ; Scene Transition Tracking
    lastTransition BYTE 0   ; Prevents multiple transitions when crossing room boundaries
    
    ; Dialogue System State
    isDialogueActive BYTE 0         ; Flag indicating if dialogue is currently showing
    currentDialogue DWORD 0         ; Pointer to current dialogue text
    isSpecialDialogue BYTE 0        ; Flag for special dialogue sequences
    
    ; Game State Flags
    isGameEnded BYTE 0              ; Indicates if the game has been completed

    ; Interactive Object Dialogue Text
    ; Each piece of dialogue shown when interacting with objects
    altarDialogue    BYTE "An ancient altar... There's an eerie glow emanating from its center.", 0
    eyeDialogue      BYTE "A mysterious eye symbol. It seems to follow your movement.", 0
    spearDialogue    BYTE "Ancient spears... They appear to be ceremonial, yet dangerously sharp.", 0
    doorPaintingDialogue BYTE "A painting depicting a ritual. The figures are gathered around a bright light.", 0
    leftLibraryDialogue BYTE "Books about ancient civilizations and forgotten languages.", 0
    rightLibraryDialogue BYTE "Scrolls containing mysterious symbols and diagrams.", 0
    centerPaintingDialogue BYTE "A majestic painting showing the temple in its glory days.", 0
    
    ; Item Collection Dialogue
    spearCollectDialogue BYTE "You take one of the ceremonial spears. It feels surprisingly light.", 0
    bookCollectDialogue BYTE "You found an ancient book about agricultural practices.", 0
    
    ; Already Collected Item Dialogue
    spearExaminedDialogue BYTE "You've already taken a spear.", 0
    bookExaminedDialogue BYTE "You've already taken the book.", 0

    ; Victory Dialogue
    specialAltarDialogue1 BYTE "As you approach the altar with both the ancient spear and agricultural text in hand, the air grows thick with anticipation.", 0

    ; Inventory System
    hasSpear BYTE 0                 ; Flag indicating spear collection
    hasBook BYTE 0                  ; Flag indicating book collection
    spearCollectWaiting BYTE 0      ; Flag for pending spear collection dialogue
    
    ; Inventory Display Text
    inventoryTitle BYTE "Inventory:", 0
    spearItem BYTE "- Spear", 0
    bookItem BYTE "- Agriculture Book", 0
    itemCollectedMsg BYTE "You collected: ", 0

    ; Inventory UI Elements
    inventoryBorderVertical BYTE "|", 0
    inventoryWidth = 25             ; Width of inventory display box
    inventoryHeight = 5             ; Height of inventory display box

    ; Interaction Trigger Points
    ; Y-coordinates for various interaction zones
    ALTAR_INTERACT_TOP = 8
    EYE_INTERACT_TOP = 8
    SPEAR_INTERACT_Y = 8
    DOOR_PAINTING_Y = 8
    LIBRARY_INTERACT_Y = 8
    CENTER_PAINTING_Y = 8

    ; X-coordinate ranges for interactions
    DOOR_PAINTING_LEFT_X = 35
    DOOR_PAINTING_RIGHT_X = 45
    LEFT_LIBRARY_LEFT_X = 13
    LEFT_LIBRARY_RIGHT_X = 28
    RIGHT_LIBRARY_LEFT_X = 58
    RIGHT_LIBRARY_RIGHT_X = 73
    CENTER_PAINTING_LEFT_X = 30
    CENTER_PAINTING_RIGHT_X = 56

    ; Altar Interaction Boundaries
    ALTAR_LEFT   = 55              ; Left boundary of altar
    ALTAR_RIGHT  = 65              ; Right boundary of altar
    ALTAR_TOP    = 8               ; Top boundary of altar
    ALTAR_BOTTOM = 9               ; Bottom boundary of altar
    ALTAR_INTERACT_DIST = 1        ; Distance required for altar interaction

    ; Eye Symbol Interaction Zone
    EYE_LEFT = 19                  ; Left boundary of eye symbol
    EYE_RIGHT = 33                 ; Right boundary of eye symbol
    EYE_Y = 8                      ; Y-coordinate of eye symbol

    ; Door Scene Interaction Zones
    DOOR_PAINTING_LEFT = 11        ; Left edge of door painting
    DOOR_PAINTING_RIGHT = 48       ; Right edge of door painting
    DOOR_PAINTING_Y = 8            ; Y-coordinate for painting interaction

    ; Spear Rack Location
    SPEAR_LEFT = 52                ; Left edge of spear rack
    SPEAR_RIGHT = 67               ; Right edge of spear rack
    SPEAR_Y = 8                    ; Y-coordinate for spear interaction
    
    ; Door Position
    DOOR_X = 23                    ; X-coordinate of the door
    DOOR_Y = 11                    ; Y-coordinate of the door

; Begin Code Segment
.code
main PROC
    ; Initialize game environment
    call ClrScr                    ; Clear the screen before starting
    ; Start background music with configured flags
    INVOKE PlaySoundA, OFFSET soundFile, NULL, SND_ASYNC OR SND_LOOP OR SND_FILENAME
    
GameLoop:
    ; Display music controls
    mov dl, 2                      ; Set cursor X position
    mov dh, 2                      ; Set cursor Y position
    call Gotoxy
    mov edx, OFFSET muteMessage    ; Load mute toggle instruction
    call WriteString
    
    ; Update and display mute status
    mov dl, 30                     ; Position for status display
    mov dh, 2
    call Gotoxy
    ; Clear previous status
    mov ecx, 20                    ; Length of status area to clear
    mov al, ' '                    ; Space character for clearing
ClearStatus:
    call WriteChar
    loop ClearStatus
    
    ; Reposition cursor for new status
    mov dl, 30
    mov dh, 2
    call Gotoxy
    
    ; Display appropriate mute status
    cmp isMuted, 1
    je showMuted
    mov edx, OFFSET unmutedStatus
    jmp displayMuteStatus
showMuted:
    mov edx, OFFSET mutedStatus
displayMuteStatus:
    call WriteString

    ; Process game states
    mov al, gameState
    cmp al, 0                      ; Check if in menu state
    je DoProcessMenu
    cmp al, 1                      ; Check if in game state
    je ProcessGameState
    cmp al, 2                      ; Check if in instructions state
    je DoProcessInstructions
    jmp ExitGameProcedure

    DoProcessMenu:
        call ProcessMenuState
        jmp GameLoop
        
    DoProcessInstructions:
        call ProcessInstructionsState
        jmp GameLoop
main ENDP

InitializeGameState PROC
    ; Save all registers
    pushad
    
    ; Set initial game state values
    mov currentScene, 1            ; Start in Temple room
    mov isDialogueActive, 0        ; No active dialogue
    mov playerX, 43               ; Initial player X position
    mov playerY, 14               ; Initial player Y position
    
    ; Restore registers and return
    popad
    ret
InitializeGameState ENDP

ProcessMenuState PROC
    ; Draw the menu and process input
    call DrawMenu                  ; Display menu options
    call ReadChar                  ; Wait for key press
    
    ; Check menu selection
    cmp al, '1'                   ; Start Game
    je InitializeNewGame
    cmp al, '2'                   ; Instructions
    je EnterInstructionsState
    cmp al, '3'                   ; Exit
    je ExitGameProcedure
    cmp al, 'm'                   ; Toggle Music
    je ToggleMusicInMenu
    ret

ToggleMusicInMenu:
    call ToggleMusic              ; Toggle music state
    call DrawMenu                 ; Redraw menu
    ret
ProcessMenuState ENDP

ExitGameProcedure PROC
    call ClrScr                   ; Clear screen before exit
    ; Display exit message
    mov dl, 25
    mov dh, 12
    call Gotoxy
    mWrite "Thanks for playing! Press any key to exit."
    call ReadChar                 ; Wait for final key press
    invoke ExitProcess, 0         ; Exit program
ExitGameProcedure ENDP

ProcessInstructionsState PROC
    call ShowInstructions         ; Display game instructions
    ret
ProcessInstructionsState ENDP

InitializeNewGame PROC
    call InitializeGameState      ; Set up initial game state
    mov gameState, 1              ; Set state to active game
    call ClrScr                   ; Clear screen
    call ProcessGameState         ; Start game processing
    ret
InitializeNewGame ENDP

EnterInstructionsState PROC
    mov gameState, 2              ; Set state to instructions
    call ClrScr                   ; Clear screen
    ret
EnterInstructionsState ENDP

DrawMenu PROC
    ; Draw main title art
    mov dl, 15                    ; X position for title
    mov dh, 5                     ; Y position for first line
    call Gotoxy
    mov edx, OFFSET titleArt1     ; Load first line of title
    call WriteString
    
    ; Draw remaining title lines
    mov dl, 15
    mov dh, 6
    call Gotoxy
    mov edx, OFFSET titleArt2
    call WriteString
    
    mov dl, 15
    mov dh, 7
    call Gotoxy
    mov edx, OFFSET titleArt3
    call WriteString
    
    mov dl, 15
    mov dh, 8
    call Gotoxy
    mov edx, OFFSET titleArt4
    call WriteString

    mov dl, 15
    mov dh, 9
    call Gotoxy
    mov edx, OFFSET titleArt5
    call WriteString

    ; Draw menu options
    mov dl, 25                    ; X position for menu options
    mov dh, 15                    ; Y position for first option
    call Gotoxy
    mov edx, OFFSET menuOption1
    call WriteString

    mov dl, 25
    mov dh, 16
    call Gotoxy
    mov edx, OFFSET menuOption2
    call WriteString

    mov dl, 25
    mov dh, 17
    call Gotoxy
    mov edx, OFFSET menuOption3
    call WriteString

    ; Draw selection prompt
    mov dl, 15
    mov dh, 22
    call Gotoxy
    mov edx, OFFSET pressKeyPrompt
    call WriteString

    ret
DrawMenu ENDP

ProcessGameState PROC
    call ClrScr                   ; Clear screen for new game state
    
    ; Determine which scene to draw
    cmp currentScene, 1
    je DrawTempleRoom
    cmp currentScene, 2
    je DrawLeftRoom
    cmp currentScene, 3
    je DrawDoorRoom
    jmp ContinueGameState
    
DrawTempleRoom:
    call DrawTempleScene
    jmp ContinueGameState
    
DrawLeftRoom:
    call DrawLeftScene
    jmp ContinueGameState
    
DrawDoorRoom:
    call DrawDoorScene
    jmp ContinueGameState

ContinueGameState:
    call DrawPlayer              ; Draw player in current position
    call DrawInventory          ; Display inventory

GameStateLoop:
    call ReadKey                ; Wait for keyboard input
    jz GameStateLoop           ; If no key pressed, keep waiting
    
    cmp al, 1Bh                ; Check for ESC key
    je HandlePause
    
    call HandleKeyInput        ; Process other key inputs
    jmp GameStateLoop

HandlePause:
    call HandlePauseMenu       ; Display and handle pause menu
    cmp eax, 1                 ; Check if returning to main menu
    jne GameStateLoop
    
    mov gameState, 0           ; Set state back to menu
    call ClrScr
    call DrawMenu
    ret
ProcessGameState ENDP

DrawPlayer PROC
    pushad                     ; Save all registers
    
    mov dl, PlayerX           ; Set X position
    mov dh, PlayerY           ; Set Y position
    call Gotoxy
    mov al, "X"               ; Player character
    call WriteChar
    
    popad                     ; Restore all registers
    ret
DrawPlayer ENDP

UpdatePlayer PROC
    pushad                    ; Save all registers
    
    mov dl, PlayerX          ; Set X position
    mov dh, PlayerY          ; Set Y position
    call Gotoxy
    mov al, " "              ; Clear old position with space
    call WriteChar
    
    popad                    ; Restore all registers
    ret
UpdatePlayer ENDP

ShowInstructions PROC
    call ClrScr              ; Clear screen for instructions
    
    ; Draw instructions title
    mov dl, 20
    mov dh, 5
    call Gotoxy
    mWrite "How to Play"
    
    ; Draw control instructions
    mov dl, 15
    mov dh, 7
    call Gotoxy
    mWrite "- Use WASD keys to move your character"
    
    mov dl, 15
    mov dh, 8
    call Gotoxy
    mWrite "- ESC to access the pause menu"
    
    mov dl, 15
    mov dh, 9
    call Gotoxy
    mWrite "- Press M to toggle music"
    
    mov dl, 15
    mov dh, 10
    call Gotoxy
    mWrite "- Explore the temple and discover its secrets"
    
    ; Draw return prompt
    mov dl, 15
    mov dh, 20
    call Gotoxy
    mWrite "Press SPACE to return to menu"
    
WaitForInstructionInput:
    call ReadChar
    cmp al, 20h              ; Check for space key
    jne WaitForInstructionInput
    
    mov gameState, 0         ; Return to menu state
    call ClrScr
    ret
ShowInstructions ENDP

DrawLeftScene PROC
    ; Draw the complete left room layout line by line
    ; First line
    mov dl, 0
    mov dh, 0
    call Gotoxy
    mov edx, OFFSET sceneLeft1
    call WriteString
    
    ; Second line
    mov dl, 0
    mov dh, 1
    call Gotoxy
    mov edx, OFFSET sceneLeft2
    call WriteString
    
    ; Third line
    mov dl, 0
    mov dh, 2
    call Gotoxy
    mov edx, OFFSET sceneLeft3
    call WriteString

    ; Continue with remaining lines
    mov dl, 0
    mov dh, 3
    call Gotoxy
    mov edx, OFFSET sceneLeft4
    call WriteString
    
    mov dl, 0
    mov dh, 4
    call Gotoxy
    mov edx, OFFSET sceneLeft5
    call WriteString
    
    mov dl, 0
    mov dh, 5
    call Gotoxy
    mov edx, OFFSET sceneLeft6
    call WriteString
    
    mov dl, 0
    mov dh, 6
    call Gotoxy
    mov edx, OFFSET sceneLeft7
    call WriteString
    
    mov dl, 0
    mov dh, 7
    call Gotoxy
    mov edx, OFFSET sceneLeft8
    call WriteString
    
    mov dl, 0
    mov dh, 8
    call Gotoxy
    mov edx, OFFSET sceneLeft9
    call WriteString
    
    mov dl, 0
    mov dh, 9
    call Gotoxy
    mov edx, OFFSET sceneLeft10
    call WriteString
    
    mov dl, 0
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET sceneLeft11
    call WriteString
    
    mov dl, 0
    mov dh, 11
    call Gotoxy
    mov edx, OFFSET sceneLeft12
    call WriteString
    
    mov dl, 0
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET sceneLeft13
    call WriteString
    
    mov dl, 0
    mov dh, 13
    call Gotoxy
    mov edx, OFFSET sceneLeft14
    call WriteString
    
    mov dl, 0
    mov dh, 14
    call Gotoxy
    mov edx, OFFSET sceneLeft15
    call WriteString
    
    mov dl, 0
    mov dh, 15
    call Gotoxy
    mov edx, OFFSET sceneLeft16
    call WriteString

    ; Update inventory display
    call DrawInventory
    ret
DrawLeftScene ENDP

ClearDialogueArea PROC
    pushad
    
    ; Clear 4 lines starting from line 20
    mov ecx, 4                ; Number of lines to clear
    mov dh, 20               ; Start at line 20
    
ClearLoop:
    mov dl, 0                ; Start from left edge
    call Gotoxy
    
    push ecx                ; Save line counter
    mov ecx, 100            ; Clear full width of screen
    mov al, ' '             ; Space character
    
ClearLine:
    call WriteChar
    loop ClearLine
    
    inc dh                  ; Move to next line
    pop ecx                ; Restore line counter
    loop ClearLoop
    
    ; Redraw player after clearing
    call DrawPlayer
    
    popad
    ret
ClearDialogueArea ENDP

HandlePauseMenu PROC
    call ClrScr
    
    ; Draw pause menu title
    mov dl, 25
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET pauseTitle
    call WriteString
    
    ; Draw menu options
    mov dl, 25
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET continueText
    call WriteString
    
    mov dl, 25
    mov dh, 13
    call Gotoxy
    mov edx, OFFSET exitText
    call WriteString
    
    ; Draw selection prompt
    mov dl, 25
    mov dh, 15
    call Gotoxy
    mov edx, OFFSET pausePrompt
    call WriteString

WaitForPauseInput:
    call ReadChar
    
    cmp al, '1'             ; Check for continue option
    je ContinueGame
    cmp al, '2'             ; Check for exit option
    je ExitToMenu
    jmp WaitForPauseInput

ContinueGame:
    call ClrScr
    
    ; Redraw current scene based on currentScene value
    cmp currentScene, 1
    je DrawScene1
    cmp currentScene, 2
    je DrawScene2
    call DrawDoorScene
    jmp ContinueDone
    
DrawScene1:
    call DrawTempleScene
    jmp ContinueDone
    
DrawScene2:
    call DrawLeftScene
    
ContinueDone:
    call DrawPlayer
    mov eax, 0              ; Signal to continue game
    ret

ExitToMenu:
    mov eax, 1              ; Signal to return to menu
    ret
HandlePauseMenu ENDP

ToggleMusic PROC
    pushad
    
    ; Toggle mute state
    xor isMuted, 1          ; Switch between 0 and 1
    
    ; Apply new mute state
    cmp isMuted, 1
    je MuteBackgroundMusic
    
    ; Unmute - restart music
    INVOKE PlaySoundA, OFFSET soundFile, NULL, SND_ASYNC OR SND_LOOP OR SND_FILENAME
    jmp ToggleMusicEnd
    
MuteBackgroundMusic:
    ; Mute - stop music
    INVOKE PlaySoundA, NULL, NULL, 0

ToggleMusicEnd:
    popad
    ret
ToggleMusic ENDP

HandleVerticalMovement PROC
    ; Check which vertical movement key was pressed
    cmp al, 'w'                    ; Check for up movement
    je MoveUp
    cmp al, 's'                    ; Check for down movement
    je MoveDown
    ret

MoveUp:
    ; Check current scene for special interactions
    mov bl, currentScene
    cmp bl, 1                     ; Temple scene
    je CheckTempleUp
    cmp bl, 2                     ; Left scene
    je CheckLeftSceneUp
    cmp bl, 3                     ; Door scene
    je CheckDoorUp
    jmp DoMoveUp                  ; Default movement if no special cases

CheckTempleUp:
    ; Check for door interaction
    mov bl, PlayerY
    dec bl                        ; Check position after potential move
    cmp bl, DOOR_Y
    jne CheckEyePos               ; If not at door height, check eye position

    ; Check if at door X position
    mov bl, PlayerX
    cmp bl, DOOR_X
    jne CheckEyePos

    ; Check for win condition (both items)
    call CheckBothItems
    cmp eax, 1
    jne DoMoveUp                  ; Continue normal movement if items missing

    ; Trigger win sequence
    call ClrScr
    call DrawWinScreen
    ret

CheckEyePos:
    ; Check for eye symbol interaction
    mov bl, PlayerY
    dec bl                        ; Look at next position
    cmp bl, EYE_Y
    jne CheckAltarUp
    
    ; Check if within eye X range
    mov bl, PlayerX
    cmp bl, EYE_LEFT
    jl CheckAltarUp
    cmp bl, EYE_RIGHT
    jg CheckAltarUp
    
    ; Show eye dialogue
    mov edx, OFFSET eyeDialogue
    call ShowDialogue
    mov al, 1
    ret
    
CheckAltarUp:
    ; Check for altar interaction
    mov bl, PlayerY
    cmp bl, ALTAR_BOTTOM
    jne DoMoveUp
    
    ; Check if within altar X range
    mov bl, PlayerX
    cmp bl, ALTAR_LEFT
    jl DoMoveUp
    cmp bl, ALTAR_RIGHT
    jg DoMoveUp
    
    ; Check for both items
    push eax
    call CheckBothItems
    cmp eax, 1
    pop eax
    jne ShowRegularAltarDialog
    
    ; Show special altar dialogue if both items present
    mov edx, OFFSET specialAltarDialogue1
    call ShowDialogue

WaitForSpaceKey:
    call ReadKey
    jz WaitForSpaceKey
    
    cmp al, 20h                   ; Wait for space key
    jne WaitForSpaceKey
    
    ; Trigger win sequence
    call ClrScr
    call DrawWinScreen
    ret

ShowRegularAltarDialog:
    mov edx, OFFSET altarDialogue
    call ShowDialogue
    mov al, 1
    ret

CheckLeftSceneUp:
    ; Check for library interactions
    mov bl, PlayerY
    dec bl
    cmp bl, LIBRARY_INTERACT_Y
    jne DoMoveUp
    
    ; Check left library position
    mov bl, PlayerX
    cmp bl, LEFT_LIBRARY_LEFT_X
    jl CheckRightLibrary
    cmp bl, LEFT_LIBRARY_RIGHT_X
    jg CheckRightLibrary
    
    ; Collect book and show dialogue
    mov edx, OFFSET leftLibraryDialogue
    call ShowDialogue
    mov al, 1
    mov hasBook, 1
    ret
    
CheckRightLibrary:
    ; Check right library position
    cmp bl, RIGHT_LIBRARY_LEFT_X
    jl DoMoveUp
    cmp bl, RIGHT_LIBRARY_RIGHT_X
    jg DoMoveUp
    
    ; Show right library dialogue
    mov edx, OFFSET rightLibraryDialogue
    call ShowDialogue
    mov al, 1
    ret
    
CheckDoorUp:
    ; Check for painting interactions
    mov bl, PlayerY
    dec bl
    cmp bl, DOOR_PAINTING_Y
    jne DoMoveUp
    
    ; Check painting position
    mov bl, PlayerX
    cmp bl, DOOR_PAINTING_LEFT
    jl CheckSpearsUp
    cmp bl, DOOR_PAINTING_RIGHT
    jg CheckSpearsUp
    
    ; Show painting dialogue
    mov edx, OFFSET doorPaintingDialogue
    call ShowDialogue
    mov al, 1
    ret

CheckSpearsUp:
    ; Check spear rack position
    mov bl, PlayerX
    cmp bl, SPEAR_LEFT
    jl DoMoveUp
    cmp bl, SPEAR_RIGHT
    jg DoMoveUp
    
    ; Collect spear and show dialogue
    mov edx, OFFSET spearDialogue
    call ShowDialogue
    mov hasSpear, 1
    mov al, 1
    ret

DoMoveUp:
    ; Perform upward movement
    call UpdatePlayer     
    dec PlayerY
    cmp PlayerY, BORDER_TOP
    jge @F              
    mov PlayerY, BORDER_TOP
@@:
    call DrawPlayer
    mov al, 1
    ret
    
MoveDown:
    ; Similar structure to MoveUp but for downward movement
    mov bl, currentScene
    cmp bl, 1
    je CheckTempleDown
    cmp bl, 2
    je CheckLeftSceneDown
    cmp bl, 3
    je CheckDoorDown
    jmp DoMoveDown

CheckTempleDown:
    ; Check for door interaction when moving down
    mov bl, PlayerY
    inc bl                        ; Check position after potential move
    cmp bl, DOOR_Y
    jne CheckAltarDown

    mov bl, PlayerX
    cmp bl, DOOR_X
    jne CheckAltarDown
    
    ; Check win condition
    call CheckBothItems
    cmp eax, 1
    jne DoMoveDown
    
    call ClrScr
    call DrawWinScreen
    ret

CheckAltarDown:
    ; Fall through to next check if no altar interaction

CheckLeftSceneDown:
    ; Check for library interactions
    mov bl, PlayerY
    inc bl
    cmp bl, LIBRARY_INTERACT_Y
    jne CheckCenterPaintingDown
    
    ; Check left library position
    mov bl, PlayerX
    cmp bl, LEFT_LIBRARY_LEFT_X
    jl CheckRightLibraryDown
    cmp bl, LEFT_LIBRARY_RIGHT_X
    jg CheckRightLibraryDown
    
    ; Interact with left library
    mov edx, OFFSET leftLibraryDialogue
    call ShowDialogue
    mov al, 1
    mov hasBook, 1
    ret
    
CheckRightLibraryDown:
    cmp bl, RIGHT_LIBRARY_LEFT_X
    jl DoMoveDown
    cmp bl, RIGHT_LIBRARY_RIGHT_X
    jg DoMoveDown
    
    ; Interact with right library
    mov edx, OFFSET rightLibraryDialogue
    call ShowDialogue
    mov al, 1
    ret
    
CheckCenterPaintingDown:
    ; Check for painting interaction
    cmp bl, CENTER_PAINTING_Y
    jne DoMoveDown
    
    ; Check if in painting X range
    mov bl, PlayerX
    cmp bl, CENTER_PAINTING_LEFT_X
    jl DoMoveDown
    cmp bl, CENTER_PAINTING_RIGHT_X
    jg DoMoveDown
    
    ; Show painting dialogue
    mov edx, OFFSET centerPaintingDialogue
    call ShowDialogue
    mov al, 1
    ret

CheckDoorDown:
    ; Check for painting/spear interactions
    mov bl, PlayerY
    inc bl
    cmp bl, DOOR_PAINTING_Y
    jne DoMoveDown
    
    ; Check painting position
    mov bl, PlayerX
    cmp bl, DOOR_PAINTING_LEFT
    jl CheckSpearsDown
    cmp bl, DOOR_PAINTING_RIGHT
    jg CheckSpearsDown
    
    ; Show painting dialogue
    mov edx, OFFSET doorPaintingDialogue
    call ShowDialogue
    mov al, 1
    ret

CheckSpearsDown:
    ; Check spear rack position
    mov bl, PlayerX
    cmp bl, SPEAR_LEFT
    jl DoMoveDown
    cmp bl, SPEAR_RIGHT
    jg DoMoveDown
    
    ; Collect spear and show dialogue
    mov edx, OFFSET spearDialogue
    call ShowDialogue
    mov hasSpear, 1
    mov al, 1
    ret

DoMoveDown:
    ; Perform downward movement with boundary checking
    call UpdatePlayer
    inc PlayerY
    cmp PlayerY, BORDER_BOTTOM
    jle @F
    mov PlayerY, BORDER_BOTTOM
@@:
    call DrawPlayer
    mov al, 1
    ret

HandleVerticalMovement ENDP

HandleHorizontalMovement PROC
    ; Check movement direction
    cmp al, 'a'
    je ProcessLeft
    cmp al, 'd'
    je ProcessRight
    ret

ProcessLeft:
    ; Check for scene transition
    mov al, playerX
    cmp al, BORDER_LEFT
    jne ContinueLeft
    
    ; Prevent multiple transitions
    cmp lastTransition, 1
    je ContinueLeft
    
    ; Check if in valid Y range for transition
    mov al, playerY
    cmp al, TRANSITION_Y_MIN
    jl ContinueLeft
    cmp al, TRANSITION_Y_MAX
    jg ContinueLeft
    
    ; Set transition flag
    mov lastTransition, 1
    
    ; Handle scene transitions
    mov al, currentScene
    cmp al, 1            ; From Temple to Left scene
    je ToLeftRoom
    cmp al, 3            ; From Door back to Temple
    je ToCenterFromRight
    jmp ContinueLeft

ToLeftRoom:              
    mov currentScene, 2   
    mov PlayerX, 70
    call ClrScr
    call DrawLeftScene
    call DrawPlayer
    mov al, 1
    ret
    
ToCenterFromRight:      
    mov currentScene, 1  
    mov PlayerX, 70
    call ClrScr
    call DrawTempleScene
    call DrawPlayer
    mov al, 1
    ret

ContinueLeft:
    mov lastTransition, 0    ; Clear transition flag
    jmp DoMoveLeft

CheckTempleLeft:
    push eax
    mov currentScene, 1
    mov PlayerX, RIGHT_SPAWN_X
    call ClrScr
    call DrawTempleScene
    call DrawPlayer
    mov al, 1
    ret

CheckLeftSceneLeft:
    ; Check library interactions
    mov bl, PlayerY
    cmp bl, LIBRARY_INTERACT_Y
    je CheckLibraryCollisionLeft
    
    ; Check painting interactions
    cmp bl, CENTER_PAINTING_Y
    je CheckPaintingCollisionLeft
    jmp DoMoveLeft
    
CheckLibraryCollisionLeft:
    mov bl, PlayerX
    dec bl
    cmp bl, LEFT_LIBRARY_RIGHT_X
    je ShowLeftLibrary
    cmp bl, RIGHT_LIBRARY_RIGHT_X
    je ShowRightLibrary
    jmp DoMoveLeft
    
ShowLeftLibrary:
    mov edx, OFFSET leftLibraryDialogue
    call ShowDialogue
    mov al, 1
    mov hasBook, 1
    ret
    
ShowRightLibrary:
    mov edx, OFFSET rightLibraryDialogue
    call ShowDialogue
    mov al, 1
    ret
    
CheckPaintingCollisionLeft:
    mov bl, PlayerX
    dec bl
    cmp bl, CENTER_PAINTING_RIGHT_X
    jne DoMoveLeft
    
    mov edx, OFFSET centerPaintingDialogue
    call ShowDialogue
    mov al, 1
    ret

DoMoveLeft:
    call UpdatePlayer
    dec PlayerX
    cmp PlayerX, BORDER_LEFT
    jge @F
    mov PlayerX, BORDER_LEFT
@@:
    call DrawPlayer
    mov al, 1
    ret

ProcessRight:
    ; Check scene transition
    mov al, playerX
    cmp al, BORDER_RIGHT
    jne ContinueRight
    
    ; Prevent multiple transitions
    cmp lastTransition, 1
    je ContinueRight
    
    ; Check valid Y position for transition
    mov al, playerY
    cmp al, TRANSITION_Y_MIN
    jl ContinueRight
    cmp al, TRANSITION_Y_MAX
    jg ContinueRight
    
    ; Set transition flag
    mov lastTransition, 1
    
    ; Handle scene transitions
    mov al, currentScene
    cmp al, 1            ; Temple to Door scene
    je ToRightRoom
    cmp al, 2            ; Left to Temple
    je ToCenterFromLeft
    jmp ContinueRight

ToCenterFromLeft:       
    mov currentScene, 1
    mov PlayerX, RIGHT_SPAWN_X
    call ClrScr
    call DrawTempleScene
    call DrawPlayer
    mov al, 1
    ret
    
ToRightRoom:           
    mov currentScene, 3
    mov PlayerX, RIGHT_SPAWN_X
    call ClrScr
    call DrawDoorScene
    call DrawPlayer
    mov al, 1
    ret

ContinueRight:
    mov lastTransition, 0
    jmp DoMoveRight

CheckTempleRight:
    ; Check altar interaction
    mov bl, PlayerY
    cmp bl, ALTAR_TOP
    jne DoMoveRight
    
    mov bl, PlayerX
    inc bl
    cmp bl, ALTAR_LEFT
    jne DoMoveRight
    
    mov edx, OFFSET altarDialogue
    call ShowDialogue
    mov al, 1
    ret

DoMoveRight:
    call UpdatePlayer
    inc PlayerX
    cmp PlayerX, BORDER_RIGHT
    jle @F
    mov PlayerX, BORDER_RIGHT
@@:
    call DrawPlayer
    mov al, 1
    ret

HandleHorizontalMovement ENDP

DrawInventory PROC
    pushad
    
    ; Draw inventory box title
    mov dl, 85
    mov dh, 5
    call Gotoxy
    mov edx, OFFSET inventoryTitle
    call WriteString
    
    ; Draw top border
    mov dl, 83
    mov dh, 6
    call Gotoxy
    mov al, '+'
    call WriteChar
    mov ecx, inventoryWidth
    mov al, '-'
DrawTopBorder:
    call WriteChar
    loop DrawTopBorder
    mov al, '+'
    call WriteChar
    
    ; Draw side borders
    mov ecx, inventoryHeight
DrawSides:
    ; Left border
    mov dl, 83
    inc dh
    call Gotoxy
    mov al, '|'
    call WriteChar
    
    ; Right border
    mov dl, 83
    add dl, inventoryWidth
    add dl, 1
    call Gotoxy
    mov al, '|'
    call WriteChar
    loop DrawSides
    
    ; Draw bottom border
    mov dl, 83
    inc dh
    call Gotoxy
    mov al, '+'
    call WriteChar
    mov ecx, inventoryWidth
    mov al, '-'
DrawBottomBorder:
    call WriteChar
    loop DrawBottomBorder
    mov al, '+'
    call WriteChar
    
    ; Display collected items
    mov dl, 85
    mov dh, 8
    call Gotoxy
    cmp hasSpear, 1
    jne CheckBook
    mov edx, OFFSET spearItem
    call WriteString
    
CheckBook:
    mov dl, 85
    mov dh, 10
    call Gotoxy
    cmp hasBook, 1
    jne FinishInventory
    mov edx, OFFSET bookItem
    call WriteString
    
FinishInventory:
    popad
    ret
DrawInventory ENDP

CheckBothItems PROC
    pushad
    
    ; Check if player has spear
    mov al, hasSpear
    cmp al, 1
    jne DoNotHaveItems
    
    ; Check if player has book
    mov al, hasBook
    cmp al, 1
    jne DoNotHaveItems
    
    ; Have both items
    mov eax, 1
    popad
    ret
    
DoNotHaveItems:
    mov eax, 0
    popad
    ret
CheckBothItems ENDP

ShowDialogue PROC
    pushad
    push edx                ; Save dialogue text pointer
    
    ; Clear dialogue area
    call ClearDialogueArea
    
    ; Ensure player remains visible
    call DrawPlayer
    
    ; Draw dialogue box top border
    mov dl, 10
    mov dh, 20
    call Gotoxy
    mov ecx, 60
    mov al, '-'
BorderTop:
    call WriteChar
    loop BorderTop
    
    ; Display dialogue text
    mov dl, 10
    mov dh, 21
    call Gotoxy
    pop edx
    call WriteString
    
    ; Draw bottom border
    mov dl, 10
    mov dh, 22
    call Gotoxy
    mov ecx, 60
    mov al, '-'
BorderBottom:
    call WriteChar
    loop BorderBottom
    
    ; Show continue prompt
    mov dl, 10
    mov dh, 23
    call Gotoxy
    mov edx, OFFSET continuePrompt
    call WriteString
    
    ; Set dialogue active flag
    mov isDialogueActive, 1
    
    popad
    ret
ShowDialogue ENDP

DrawWinScreen PROC
    call ClrScr
    
    ; Display victory message
    mov dl, 25
    mov dh, 10
    call Gotoxy
    mWrite "Congratulations! You have won the game!"
    
    mov dl, 25
    mov dh, 12
    call Gotoxy
    mWrite "You have successfully completed the temple's ritual."
    
    mov dl, 25
    mov dh, 14
    call Gotoxy
    mWrite "Press any key to exit..."
    
    call ReadChar
    call ExitGameProcedure
    ret
DrawWinScreen ENDP

DrawMusicStatus PROC
    pushad
    
    ; Display mute toggle instruction
    mov dl, 2
    mov dh, 17
    call Gotoxy
    mov edx, OFFSET muteMessage
    call WriteString
    
    ; Display current music status
    mov dl, 30
    mov dh, 17
    call Gotoxy
    cmp isMuted, 1
    je ShowMutedStatus
    mov edx, OFFSET unmutedStatus
    jmp DisplayMuteStatus
ShowMutedStatus:
    mov edx, OFFSET mutedStatus
DisplayMuteStatus:
    call WriteString
    
    popad
    ret
DrawMusicStatus ENDP

CheckInteractions PROC
    pushad
    
    ; Skip if dialogue is already active
    cmp isDialogueActive, 1
    je ExitInteractions
    
    ; Check current scene for interactions
    mov al, currentScene
    cmp al, 3              ; Door scene (spears)
    je CheckSpearInteraction
    cmp al, 2              ; Left scene (book)
    je CheckBookInteraction
    jmp CheckAltarInteraction
    
CheckSpearInteraction:
    ; Verify spear height
    mov al, PlayerY
    cmp al, SPEAR_Y
    jne ExitInteractions
    
    ; Check X position
    mov al, PlayerX
    cmp al, SPEAR_LEFT
    jl ExitInteractions
    cmp al, SPEAR_RIGHT
    jg ExitInteractions
    
    ; Set spear collected and show dialogue
    mov hasSpear, 1
    mov edx, OFFSET spearCollectDialogue
    call ShowDialogue
    jmp ExitInteractions
    
SpearAlreadyCollected:
    mov edx, OFFSET spearExaminedDialogue
    jmp ShowInteractionDialogue
    
CheckBookInteraction:
    ; Check library height
    mov al, PlayerY
    cmp al, LIBRARY_INTERACT_Y
    jne ExitInteractions
    
    ; Check left library range
    mov al, PlayerX
    cmp al, LEFT_LIBRARY_LEFT_X
    jl ExitInteractions
    cmp al, LEFT_LIBRARY_RIGHT_X
    jg ExitInteractions
    
    ; Set book collected and show dialogue
    mov hasBook, 1
    mov edx, OFFSET bookCollectDialogue
    call ShowDialogue
    jmp ExitInteractions

BookAlreadyCollected:
    mov edx, OFFSET bookExaminedDialogue
    jmp ShowInteractionDialogue
    
CheckAltarInteraction:
    ; Verify temple room
    mov al, currentScene
    cmp al, 1
    jne ExitInteractions

    ; Check altar position
    mov al, PlayerY
    cmp al, ALTAR_BOTTOM
    jne ExitInteractions

    mov al, PlayerX
    cmp al, ALTAR_LEFT
    jl ExitInteractions
    cmp al, ALTAR_RIGHT
    jg ExitInteractions

    ; Check for both items
    mov al, hasSpear
    cmp al, 1
    jne ShowRegularAltar
    
    mov al, hasBook
    cmp al, 1
    jne ShowRegularAltar

    ; Show victory dialogue if both items present
    mov edx, OFFSET specialAltarDialogue1
    call ShowDialogue
    call ClrScr
    call DrawWinScreen
    jmp ExitInteractions

ShowRegularAltar:
    mov edx, OFFSET altarDialogue
    call ShowDialogue
    jmp ExitInteractions
    
ShowInteractionDialogue:
    call ShowDialogue
    call DrawInventory
    
ExitInteractions:
    popad
    ret
CheckInteractions ENDP

HaveBothItems PROC
    pushad
    
    ; Mark special dialogue active
    mov isSpecialDialogue, 1
    
    ; Show victory dialogue
    mov dl, 8
    mov dh, 17
    call Gotoxy
    mov edx, OFFSET specialAltarDialogue1
    call ShowDialogue
    
    ; Set game completion flag
    mov isGameEnded, 1
    
    ; Transition to win screen
    call ClrScr
    call DrawWinScreen
    
    popad
    ret
HaveBothItems ENDP

DrawTempleScene PROC
    ; Draw the complete temple room layout line by line
    mov dl, 0
    mov dh, 0
    call Gotoxy
    mov edx, OFFSET sceneTemple1
    call WriteString
    
    mov dl, 0
    mov dh, 1
    call Gotoxy
    mov edx, OFFSET sceneTemple2
    call WriteString
    
    mov dl, 0
    mov dh, 2
    call Gotoxy
    mov edx, OFFSET sceneTemple3
    call WriteString
    
    mov dl, 0
    mov dh, 3
    call Gotoxy
    mov edx, OFFSET sceneTemple4
    call WriteString
    
    mov dl, 0
    mov dh, 4
    call Gotoxy
    mov edx, OFFSET sceneTemple5
    call WriteString
    
    mov dl, 0
    mov dh, 5
    call Gotoxy
    mov edx, OFFSET sceneTemple6
    call WriteString
    
    mov dl, 0
    mov dh, 6
    call Gotoxy
    mov edx, OFFSET sceneTemple7
    call WriteString
    
    mov dl, 0
    mov dh, 7
    call Gotoxy
    mov edx, OFFSET sceneTemple8
    call WriteString
    
    mov dl, 0
    mov dh, 8
    call Gotoxy
    mov edx, OFFSET sceneTemple9
    call WriteString
    
    mov dl, 0
    mov dh, 9
    call Gotoxy
    mov edx, OFFSET sceneTemple10
    call WriteString
    
    mov dl, 0
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET sceneTemple11
    call WriteString
    
    mov dl, 0
    mov dh, 11
    call Gotoxy
    mov edx, OFFSET sceneTemple12
    call WriteString
    
    mov dl, 0
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET sceneTemple13
    call WriteString
    
    mov dl, 0
    mov dh, 13
    call Gotoxy
    mov edx, OFFSET sceneTemple14
    call WriteString
    
    mov dl, 0
    mov dh, 14
    call Gotoxy
    mov edx, OFFSET sceneTemple15
    call WriteString
    
    mov dl, 0
    mov dh, 15
    call Gotoxy
    mov edx, OFFSET sceneTemple16
    call WriteString

    call DrawInventory
    ret
DrawTempleScene ENDP

DrawDoorScene PROC
    ; Draw the complete door room layout line by line
    mov dl, 0
    mov dh, 0
    call Gotoxy
    mov edx, OFFSET sceneDoor1
    call WriteString
    
    mov dl, 0
    mov dh, 1
    call Gotoxy
    mov edx, OFFSET sceneDoor2
    call WriteString
    
    mov dl, 0
    mov dh, 2
    call Gotoxy
    mov edx, OFFSET sceneDoor3
    call WriteString
    
    mov dl, 0
    mov dh, 3
    call Gotoxy
    mov edx, OFFSET sceneDoor4
    call WriteString
    
    mov dl, 0
    mov dh, 4
    call Gotoxy
    mov edx, OFFSET sceneDoor5
    call WriteString
    
    mov dl, 0
    mov dh, 5
    call Gotoxy
    mov edx, OFFSET sceneDoor6
    call WriteString
    
    mov dl, 0
    mov dh, 6
    call Gotoxy
    mov edx, OFFSET sceneDoor7
    call WriteString
    
    mov dl, 0
    mov dh, 7
    call Gotoxy
    mov edx, OFFSET sceneDoor8
    call WriteString
    
    mov dl, 0
    mov dh, 8
    call Gotoxy
    mov edx, OFFSET sceneDoor9
    call WriteString
    
    mov dl, 0
    mov dh, 9
    call Gotoxy
    mov edx, OFFSET sceneDoor10
    call WriteString
    
    mov dl, 0
    mov dh, 10
    call Gotoxy
    mov edx, OFFSET sceneDoor11
    call WriteString
    
    mov dl, 0
    mov dh, 11
    call Gotoxy
    mov edx, OFFSET sceneDoor12
    call WriteString
    
    mov dl, 0
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET sceneDoor13
    call WriteString
    
    mov dl, 0
    mov dh, 13
    call Gotoxy
    mov edx, OFFSET sceneDoor14
    call WriteString
    
    mov dl, 0
    mov dh, 14
    call Gotoxy
    mov edx, OFFSET sceneDoor15
    call WriteString
    
    mov dl, 0
    mov dh, 15
    call Gotoxy
    mov edx, OFFSET sceneDoor16
    call WriteString

    call DrawInventory
    ret
DrawDoorScene ENDP

HandleKeyInput PROC
    pushad
    
    ; Check if dialogue is active
    cmp isDialogueActive, 1
    jne RegularInput
    
    ; Handle space key for dialogue
    cmp al, 20h
    jne NoInput
    
    mov isDialogueActive, 0
    call ClearDialogueArea
    call DrawInventory
    call DrawPlayer
    jmp NoInput
    
RegularInput:
    ; Check for special keys
    cmp al, 1Bh        ; ESC key
    je HandleEscKey
    
    cmp al, 'm'        ; Music toggle
    je HandleMuteKey
    
    ; Handle movement
    call HandlePlayerMovement
    
    ; Check for interactions
    call CheckInteractions
    jmp NoInput
    
HandleEscKey:
    call HandlePauseMenu
    jmp NoInput
    
HandleMuteKey:
    call ToggleMusic
    
NoInput:
    popad
    ret
HandleKeyInput ENDP

HandlePlayerMovement PROC 
    pushad                      ; Save all registers
    
    ; Try vertical movement first (W/S keys)
    call HandleVerticalMovement
    cmp al, 1                  ; Check if movement was handled
    je MovementDone
    
    ; If not vertical, try horizontal movement (A/D keys)
    call HandleHorizontalMovement
    
MovementDone:
    popad                      ; Restore all registers
    ret
HandlePlayerMovement ENDP

; Program end point
END main