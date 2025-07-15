# 🛕 ASCII Quest: Me And Them

> An x86 Assembly adventure, where code meets chaos and temples hum with 16-bit spirit.

  ```
      __  ___        ___              __   ________                 
     /  |/  /__     /   |  ____  ____/ /  /_  __/ /_  ___  ____ ___ 
    / /|_/ / _ \   / /| | / __ \/ __  /    / / / __ \/ _ \/ __ `__ \
   / /  / /  __/  / ___ |/ / / / /_/ /    / / / / / /  __/ / / / / /
/_/  /_/\___/  /_/  |_/_/ /_/\__,_/    /_/ /_/ /_/\___/_/ /_/ /_/ 
                                                                  
  ```

## 🎮 Overview

**Me And Them** is a fully playable top-down ASCII-style game built entirely in **x86 Assembly (MASM)** for Windows. Created as a class project for Assembly & Computer Organization, this game blends old-school aesthetics with modern control logic — music, menus, room transitions, and even a pause screen.

---

## 🧠 Features

* 🎵 **Dynamic Soundtrack**
  Background music playback with `PlaySoundA` using `Amiga500.wav` — toggle music with the `M` key.

* 🧭 **Three Interconnected Rooms**
  Explore ASCII-rendered temple rooms — Center (Main Hall), Left (Mystic Shrine), and Right (Ancient Gate).

* 🎨 **Handcrafted ASCII Art**
  From walls to altars, each scene is drawn using raw character buffers.

* 🕹️ **Controls**

  ```
  W A S D   — Move the player  
  M         — Toggle music  
  ESC       — Open pause menu  
  1,2,3     — Menu selections  
  SPACE     — Advance dialogue
  ```

* 💾 **Menu System**
  Navigate through title screen, instructions, pause menu, and in-game transitions — all from scratch.

* 💡 **State Management**
  Handles game states (menu, game, pause), scene switching, and player coordinates in low-level memory.

---

## 🛠 Requirements

To run this game, you’ll need:

* Windows machine
* **Visual Studio** with MASM support
* `Irvine32.lib` and headers (included in repo)
* Sound file: `Amiga500.wav` in project directory

---

## 🧠 What I Learned

This project taught me how to:

* Manage memory and graphics without a graphics engine.
* Handle state machines in assembly.
* Integrate Windows API for audio playback.
* Think like the CPU — literally.

---

## 🚀 Try It Yourself

Clone the repo.
Open the `.asm` file in Visual Studio, build, and run!
Make sure `Irvine32.lib` is correctly linked in your project settings.

---

## 🤓 About the Developer

Hey! I'm **Rayane EL YASTI**, a Cybersecurity & Data Science double major at Duquesne University. I build tools, write exploits, and automate Linux setups when I'm not drawing temples in ASCII.
Find more of my work here: [GitHub.com/blissio](https://github.com/blissio)
Connect on LinkedIn: [linkedin.com/in/rayaneelyasti](https://www.linkedin.com/in/rayaneelyasti/)

