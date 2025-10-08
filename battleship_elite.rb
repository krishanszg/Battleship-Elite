require 'rubygems'
require 'gosu'

module ZOrder
    BACKGROUND, BOARD, SPRITE, UI, POPUP, FRAME, POPUP_TEXT = *0..6
end

module Rotation
    NORTH = 90
    EAST = 0
end

CHARACTER = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]

TITLE = ["B", "A", "T", "T", "L", "E", "S", "H", "I", "P", " ", "E", "L", "I", "T", "E"]

CELL_SIZE = 40

ACCENT = Gosu::Color.argb(255 ,255, 87, 129)

## GAME BOARD CLASSES

class Ocean
    attr_accessor :tile_frames, :x_count, :y_count
    def initialize(tile_frames, x_count, y_count)
        @tile_frames = tile_frames
        @x_count = (1200 / x_count) + 1
        @y_count = (1000 / y_count) + 1
    end
end

class Cell
    attr_accessor :x, :y, :occupied, :hit, :ship
    def initialize(x, y)
        @x = x
        @y = y
        @occupied = false
        @hit = false
        @ship = nil
    end
end

## GAME MECHANIC ENUMERATION MAPS

HEALTH = {
    2 => {text: "SUNK", color: Gosu::Color.argb(255, 255, 0, 0)},
    1 => {text: "DAMAGED", color: Gosu::Color.argb(255, 255, 255, 0)},
    0 => {text: "AFLOAT", color: Gosu::Color.argb(255, 0, 255, 0)}
}

SHIPS = {
    0 => {name: 'Carrier', size: 5, sprite: "sprites/carrier.png"},
    1 => {name: 'Battleship', size: 4, sprite: "sprites/battleship.png"},
    2 => {name: 'Destroyer', size: 3, sprite: "sprites/destroyer.png"},
    3 => {name: 'Submarine', size: 2, sprite: "sprites/submarine.png"},
    4 => {name: 'Patrol Boat', size: 2, sprite: "sprites/patrol_boat.png"}
}

POWERUPS = {
    0 => {name: 'Torpedo', sprite: "sprites/torpedo.png"},
    1 => {name: 'Air Strike', sprite: "sprites/air_strike.png"},
    2 => {name: 'Ghost', sprite: "sprites/ghost.png"}
}

AVAILABILITY = {
    true => {text: "AVAILABLE", color: Gosu::Color.argb(255, 0, 255, 0)},
    false => {text: "NOT READY", color: ACCENT}
}


## GAME OBJECT CLASSSES

class Ship
    attr_accessor :name, :origin, :direction, :size, :hit, :sprite
    def initialize(type)
        ship_ref = SHIPS[type]
        @name = ship_ref[:name]
        @origin = nil
        @direction = nil
        @size = ship_ref[:size]
        @hit = 0
        @sprite = Gosu::Image.new(ship_ref[:sprite])
    end
end

class PowerUp
    attr_accessor :type, :player_index, :active
    def initialize(type, player_index)
        powerup_ref = POWERUPS[type]
        @name = powerup_ref[:name]
        @player_index = player
        @active = true
    end
end





class BattleshipElite < Gosu::Window

    # Initialize window, player, opponent, and ocean
    def initialize
        super 1200, 1000
        self.caption = "Battleship Elite"

        #board_images
        @cell_image = Gosu::Image.new('sprites/grid.png')
        @cell_preview = Gosu::Image.new('sprites/grid_preview.png')
        
        @tick = 0

        #setup_variables
        @player_setup = true
        @opponent_setup = false
        @current_ship_index = 0
        @rotation = Rotation::NORTH

        #fonts
        @resource_text = Gosu::Font.new(20, name: 'sprites/BoldPixels.ttf')
        @letters = Gosu::Font.new(40, name: 'sprites/BoldPixels.ttf')
        @title_letter = Gosu::Font.new(56, name: 'sprites/BoldPixels.ttf')
        @alert_header = Gosu::Font.new(64, name: 'sprites/BoldPixels.ttf')
        
        #processes
        @ocean = initialize_ocean()
        initialize_grid()
        @ships = initialize_ships()
        generate_opponent_board()
    end

        def initialize_grid() #creates a 2D array of a 10x10 grid of cells for both player and opponent
            @north_grid = Array.new(10) {Array.new(10)} 
            @south_grid = Array.new(10) {Array.new(10)}
            column_index = 0
            while (column_index < 10)
                row_index = 0
                while (row_index < 10)
                    @north_grid[column_index][row_index] = Cell.new((50 + (column_index * (CELL_SIZE + 5))), (25 + (row_index * (CELL_SIZE + 5))))
                    @south_grid[column_index][row_index] = Cell.new((50 + (column_index * (CELL_SIZE + 5))), (525 + (row_index * (CELL_SIZE + 5))))
                    row_index += 1
                end
                column_index += 1
            end
        end

        def initialize_ships() # 2D array of ships, top row for opponent, bottom row for player. In this way, it is a pseudo-boolean reference, with 0 being false and 1 being true for the player
            ships = Array.new(5) {Array.new(5)}
            player_index = 0
            while (player_index < 2)
                ship_index = 0
                while (ship_index < 5)
                    ships[player_index][ship_index] = Ship.new(ship_index)
                    ship_index += 1
                end
                player_index += 1
            end
            return(ships)
        end

        def initialize_ocean() #loads ocean sprite sheet into frames in an array and places that into a predefined ocean struct
            ocean_tiles = Array.new()
            ocean_tiles = Gosu::Image.load_tiles("sprites/ocean.png", 128, 128, tileable: true)
            ocean = Ocean.new(ocean_tiles, 128, 128)
            return(ocean)
        end

        def player_setup()
            @current_ship = @ships[1][@current_ship_index]
        end

    def generate_opponent_board()
        grid = @north_grid
        ship_index = 0
        while ship_index < 5
            ship = @ships[0][ship_index]
            placed = false
            until placed == true
                direction = [Rotation::NORTH, Rotation::EAST].sample
                if direction == Rotation::NORTH
                    col = rand(9)
                    row = rand((ship.size - 1)..9)
                    empty = empty_cells(ship, grid, col, row)
                    if empty == true
                        ship.origin = [col, row]
                        ship.direction = direction
                        i = 0
                        while i < ship.size
                            grid[col][row - i].occupied = true
                            grid[col][row - i].ship = ship
                            i += 1
                        end
                        placed = true
                    end
                elsif direction == Rotation::EAST
                    col = rand(0..(ship.size + 1))
                    row = rand(9)
                    empty = empty_cells(ship, grid, col, row)
                    if empty == true
                        ship.origin = [col, row]
                        ship.direction = direction
                        i = 0
                        while i < ship.size
                            grid[col + i][row].occupied = true
                            grid[col + i][row].ship = ship
                            i += 1
                        end
                        placed = true
                    end
                end
            end
            ship_index += 1
        end
    end

    def draw_ocean(ocean)
        tiles = ocean.tile_frames
        i = 0
        while (i < ocean.y_count)
            x = 0
            while (x < ocean.x_count)
                tiles[(@tick / 13) % tiles.length].draw((x * 128), (i * 128), ZOrder::BACKGROUND)
                x += 1
            end
            i += 1
        end
    end

    def draw_game_title()
        row = 2
        letter = 0
        while (row < 10)
            cell = @north_grid[9][row]
            @title_letter.draw_text(TITLE[letter], (cell.x + 700), (cell.y + 20) , ZOrder::BOARD, 1, 1, ACCENT)
            letter += 1
            row += 1
        end
        row = 0
        while (row < 10)
            cell = @south_grid[9][row]
            @title_letter.draw_text(TITLE[letter], (cell.x + 700), (cell.y - 20) , ZOrder::BOARD, 1, 1, ACCENT)
            letter += 1
            row += 1
        end
    end

    def draw_cell(cell, row_index, column_index)
        @cell_image.draw(cell.x, cell.y, ZOrder::BOARD)
        if (column_index == 0)
            if (row_index > 8) # Adjust for 2 digit numbers
                @letters.draw_text((row_index + 1).to_s, (cell.x - 47), (cell.y) , ZOrder::BOARD, 1, 1, ACCENT)
            else # Normal single digit numbers
                @letters.draw_text((row_index + 1).to_s, (cell.x - 35), (cell.y) , ZOrder::BOARD, 1, 1, ACCENT)
            end
        end
    end

    def draw_board()
        column_index = 0
        while (column_index < 10)
            row_index = 0
            while (row_index < 10)
                north_cell = @north_grid[column_index][row_index]
                south_cell = @south_grid[column_index][row_index]
                draw_cell(north_cell, row_index, column_index)
                draw_cell(south_cell, row_index, column_index)
                if (row_index == 9) # Draw letters on bottom of grid
                    @letters.draw_text(CHARACTER[column_index], (north_cell.x + 10), (north_cell.y + 46) , ZOrder::BOARD, 1, 1, ACCENT)
                end
                row_index += 1
            end
            column_index += 1
        end
        draw_resource_area(@north_grid[9][0], "OPPONENT", 0)
        draw_resource_area(@south_grid[9][0], "YOU", 1)
    end

    def draw_resource_area(ref_cell, text, player_index)
        @title_letter.draw_text(text, (ref_cell.x + 250 + (player_index * 80)), (ref_cell.y - 6) , ZOrder::BOARD, 1, 1, Gosu::Color.argb(255,255, 87, 129))
        ship_index = 0
        @letters.draw_text("SHIPS", (ref_cell.x + 200), (ref_cell.y + 70) , ZOrder::BOARD, 1, 1, ACCENT)
        @letters.draw_text("POWER-UPS", (ref_cell.x + 480), (ref_cell.y + 70) , ZOrder::BOARD, 1, 1, ACCENT)
        while (ship_index < 5)
            ship = @ships[player_index][ship_index]
                Gosu.draw_rect((ref_cell.x + 50), (ref_cell.y + 120 + (ship_index * 60)), (CELL_SIZE * 9.75), CELL_SIZE, Gosu::Color.argb(181, 0, 119, 153), ZOrder::BOARD)
                ship.sprite.draw((ref_cell.x + 60), (ref_cell.y + 120 + (ship_index * 60)), ZOrder::UI)
                @resource_text.draw_text("#{ship.name}: #{HEALTH[ship.hit][:text]}", (ref_cell.x + 70 + (40 * ship.size)), (ref_cell.y + 130 + (ship_index * 60)) , ZOrder::UI, 1, 1, HEALTH[ship.hit][:color])
            ship_index += 1
        end
        p = 0
        while (p < POWERUPS.length)
            powerup = POWERUPS[p]
            Gosu.draw_rect((ref_cell.x + 475), (ref_cell.y + 120 + (p * 100)), 200, 80, Gosu::Color.argb(181, 0, 119, 153), ZOrder::BOARD)
            sprite = Gosu::Image.new(powerup[:sprite])
            sprite.draw((ref_cell.x + 485), (ref_cell.y + 130 + (p * 100)), ZOrder::UI)
            @resource_text.draw_text("#{powerup[:name]}", (ref_cell.x + 560), (ref_cell.y + 140 + (p * 100)) , ZOrder::UI, 1, 1, AVAILABILITY[false][:color])
            @resource_text.draw_text("#{AVAILABILITY[false][:text]}", (ref_cell.x + 560), (ref_cell.y + 160 + (p * 100)) , ZOrder::UI, 1, 1, AVAILABILITY[false][:color])
            p += 1
        end
    end

    def draw_popup_frame()
        alternate = ((@tick / 60) % 2)
        if alternate == 0
            Gosu.draw_rect(100, 100, 1000, 10, ACCENT, ZOrder::FRAME)
            Gosu.draw_rect(100, 100, 10, 200, ACCENT, ZOrder::FRAME)
            Gosu.draw_rect(1090, 100, 10, 200, ACCENT, ZOrder::FRAME)
            Gosu.draw_rect(100, 300, 1000, 10, ACCENT, ZOrder::FRAME)
        else
            Gosu.draw_rect(100, 100, 1000, 10, Gosu::Color::WHITE, ZOrder::FRAME)
            Gosu.draw_rect(100, 100, 10, 200, Gosu::Color::WHITE, ZOrder::FRAME)
            Gosu.draw_rect(1090, 100, 10, 200, Gosu::Color::WHITE, ZOrder::FRAME)
            Gosu.draw_rect(100, 300, 1000, 10, Gosu::Color::WHITE, ZOrder::FRAME)
        end
        Gosu.draw_rect(100, 100, 1000, 200, Gosu::Color.argb(235, 0, 53, 68), ZOrder::POPUP)
    end

    def draw_preview(ship) #gets current grid position and draws a green box for how long the ship being placed is
        if @current_pos && @current_pos[0] == 1
            col = @current_pos[1]
            row = @current_pos[2]
            grid = @south_grid
            length = 0
            while (length < ship.size)
                if @rotation == Rotation::NORTH && (row - ship.size) > -2 #conditions to make sure the placement is within the bounds of the grid
                    @cell_preview.draw(grid[col][row - length].x, grid[col][row - length].y)
                    @origin = [col, row]
                elsif @rotation == Rotation::EAST && (col + ship.size) < 11
                    @cell_preview.draw(grid[col + length][row].x, grid[col + length][row].y)
                    @origin = [col, row]
                end
            length += 1
            end
        else #makes sure origin is emptied if the mouse leaves the grid
            @origin = nil
        end
    end

    def draw_placement(ship) #process for everything involved in visually placing ships
        draw_popup_frame()
        @current_ship = ship
        @alert_header.draw_text_rel("Place your #{ship.name}", 600, 145, ZOrder::POPUP_TEXT, 0.5, 0.5, 1, 1, ACCENT)
        @current_ship.sprite.draw((510 + (5 - ship.size) * 20), 195, ZOrder::POPUP_TEXT)
        @letters.draw_text_rel("Press ↑ for north-facing and → for east-facing", 600, 270, ZOrder::POPUP_TEXT, 0.5, 0.5, 1, 1, ACCENT)
        draw_preview(ship)
    end

    def draw_ships() #once placed, ships are drawn in their correct spot on the player grid.
        player_index = 0
        while (player_index < 2)
            i = 0
            if player_index == 0
                grid = @north_grid
            else
                grid = @south_grid
            end
            while (i < 5)
                ship = @ships[player_index][i]
                if ship.origin != nil
                    cell = grid[ship.origin[0]][ship.origin[1]]
                    if ship.direction == Rotation::NORTH
                        ship.sprite.draw_rot(cell.x, cell.y + 35, ZOrder::SPRITE, ship.direction, 1, 1)
                    else
                        ship.sprite.draw(cell.x, cell.y, ZOrder::SPRITE)
                    end
                end
                i += 1
            end
            player_index += 1
        end
    end

    def empty_cells(ship, grid, col, row) # checks that all cells for the ship being placed are empty
        i = 0
        result = true
        while i < ship.size
            if @rotation == Rotation::NORTH && grid[col][row - i].occupied == true
                result = false
            elsif @rotation == Rotation::EAST && grid[col + i][row].occupied == true
                result = false
            end
            i += 1
        end
        return(result)
    end

    def place_player_ship() #fills the information for the current ship and it's cells based on current placement
        if @origin != nil
            col = @origin[0]
            row = @origin[1]
            ship = @current_ship
            grid = @south_grid
            empty = empty_cells(ship, grid, col, row)
            if empty == true
                ship.origin = [col, row]
                ship.direction = @rotation
                i = 0
                while i < ship.size
                    if ship.direction == Rotation::NORTH
                        grid[col][row - i].occupied = true
                        grid[col][row - i].ship = ship
                    else
                        grid[col + i][row].occupied = true
                        grid[col][row - i].ship = ship
                    end
                    i += 1
                end
                @current_ship_index += 1
                if @current_ship_index > 4
                    @player_setup = false
                end
            end
        end
    end

    def button_down(id)
        case id
            when Gosu::KB_UP
                @rotation = Rotation::NORTH
            when Gosu::KB_RIGHT
                @rotation = Rotation::EAST
            when Gosu::MS_LEFT
                if @player_setup
                    place_player_ship()
                end
                @click_pos = [mouse_x, mouse_y]
        end
    end

    def check_grid(player_index, grid)
        pos_x = mouse_x
        pos_y = mouse_y
        col = 0
        current_pos = nil
        while (col < 10)
            row = 0
            while (row < 10)
                cell = grid[col][row]
                if  pos_x.between?(cell.x, (cell.x + CELL_SIZE)) &&
                    pos_y.between?(cell.y, (cell.y + CELL_SIZE))
                    current_pos = [player_index, col, row]
                    break
                else
                    current_pos = nil
                    row += 1
                end
            end
            if current_pos != nil
                break
            else
                col += 1
            end
        end
        return(current_pos)
    end

    def mouse_position_grid()
        current_pos = check_grid(0, @north_grid)
        if current_pos == nil
            current_pos = check_grid(1, @south_grid)
        end
        return(current_pos)
    end

    def update
        @tick += 1
        @current_pos = mouse_position_grid()
            if @player_setup
                player_setup()
            end
    end

    def draw
        draw_ocean(@ocean)
        draw_game_title()
        draw_board()
            if @player_setup
                draw_placement(@current_ship)
            end
        draw_ships()
    end
end

window = BattleshipElite.new
window.show