# Battleship Elite
Custom game created by Krishan Gurdon for Swinburne Unit COS10009, Semester 2 2025.

Inspired by the classic Battleship board game, play a modernised, high-speed version of the game against your computer.
Battleship Elite is stylized with colourful pixel art and an animated ocean.

<img width="490" height="401" alt="image" src="https://github.com/user-attachments/assets/12266919-c3f1-4d62-95b7-6f0bffed3dd6"/>

## Playtesting Instructions
In order to playtest the game on your Windows PC, please follow the instructions below.
### 1. Install Ruby (5 minutes)
  - Download Ruby from <a href="https://rubyinstaller.org/">this website.</a>
  - Select all the available options when running the executable.
  - Upon install completetion, make sure to tick the run command to install ruby gems.
  - Select option '3'. Wait until same options come up again, indicating the install is finished
  - After the install is complete, in CMD on your machine, use the command `ruby -v`
  - If the terminal outputs a version number, Ruby has been installed correctly.
### 2. Install Gosu
  - In CMD on your machine, run the command `gem install gosu`.
### 3. Download Latest Playtesting Release
  - On the right-hand side of this page, download the most recent release source-code as a .zip.
  - Place the folder (un-zipped) on your desktop.
### 4. Play the Game
  - In order to play, open CMD as non-admin and run the following commands:
  - `cd Desktop\[unzipped_folder_name]`
  - `ruby battleship-elite.rb`
### 5. Things to Record
For each game you play, record the following information:
  - If the game crashed, note the error that appeared in the terminal.
  - If you are one hit away from winning, do not win, record how many turns it takes for the AI to get to the same position. This counts as a player win.
  - If the AI had a genuine win, how many ships did you have left to hit?

Examples:
  - Match 1: Player win, 18 turns until AI caught up.
  - Match 2: AI win, 2 ships left for player.
  - Match 3: Crash: RB:107 grid[col][row] unspecified method for 'hit='
