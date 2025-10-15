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

MISS = ["Missed.", "No damage detected.", "*splash*", "Off-target."]

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

## GAME MECHANIC ENUMERATIONS

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
        @player_index = player_index
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
        @current_ship_index = 0
        @rotation = Rotation::NORTH
        @round_count = 1
        @target = nil
        @end_step = false
        @player_hits_in_a_row = 0
        @enemy_hits_in_a_row = 0
        @enemy_misses_in_a_row = 0
        @game_end = nil
        @select_new = true
        @start_animation = true

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

    def generate_opponent_board() #for every ship the functions selected a random starting cell within the bounds of the ship size and checks if they're empty. Repeats until they're all placed.
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
                    empty = empty_cells(ship.size, grid, col, row, direction)
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
                    col = rand(0..(10 - ship.size))
                    row = rand(9)
                    empty = empty_cells(ship.size, grid, col, row, direction)
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

    def draw_game_title() # cycles through title enumeration for every cell on the right column, them pushes them to the far right
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

    def draw_cell(cell, row_index, column_index) # draws the cell sprite with the passed in variables, and puts reference numbers on the left side of the board
        @cell_image.draw(cell.x, cell.y, ZOrder::BOARD)
        if (column_index == 0)
            if (row_index > 8) # Adjust for 2 digit numbers
                @letters.draw_text((row_index + 1).to_s, (cell.x - 47), (cell.y) , ZOrder::BOARD, 1, 1, ACCENT)
            else # Normal single digit numbers
                @letters.draw_text((row_index + 1).to_s, (cell.x - 35), (cell.y) , ZOrder::BOARD, 1, 1, ACCENT)
            end
        end
    end

    def draw_board() # 
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

    def draw_popup_window(offset, button)
        alternate = ((@tick / 60) % 2)
        if alternate == 0
            Gosu.draw_rect(100, 100 + offset, 1000, 10, ACCENT, ZOrder::FRAME)
            Gosu.draw_rect(100, 100 + offset, 10, 200, ACCENT, ZOrder::FRAME)
            Gosu.draw_rect(1090, 100 + offset, 10, 200, ACCENT, ZOrder::FRAME)
            Gosu.draw_rect(100, 300 + offset, 1000, 10, ACCENT, ZOrder::FRAME)
        else
            Gosu.draw_rect(100, 100 + offset, 1000, 10, Gosu::Color::WHITE, ZOrder::FRAME)
            Gosu.draw_rect(100, 100 + offset, 10, 200, Gosu::Color::WHITE, ZOrder::FRAME)
            Gosu.draw_rect(1090, 100 + offset, 10, 200, Gosu::Color::WHITE, ZOrder::FRAME)
            Gosu.draw_rect(100, 300 + offset, 1000, 10, Gosu::Color::WHITE, ZOrder::FRAME)
        end
        Gosu.draw_rect(100, 100 + offset, 1000, 200, Gosu::Color.argb(235, 0, 53, 68), ZOrder::POPUP)
        if button != nil
            Gosu.draw_rect(500, 210 + offset, 200, 60, ACCENT, ZOrder::FRAME)
            @title_letter.draw_text_rel(button, 600, 237 + offset, ZOrder::POPUP_TEXT, 0.5, 0.5, 1, 1, Gosu::Color::WHITE)
            if @button_hover == true
                Gosu.draw_rect(495, 205 + offset, 210, 5, Gosu::Color::WHITE, ZOrder::POPUP_TEXT)
                Gosu.draw_rect(495, 205 + offset, 5, 70, Gosu::Color::WHITE, ZOrder::POPUP_TEXT)
                Gosu.draw_rect(700, 205 + offset, 5, 70, Gosu::Color::WHITE, ZOrder::POPUP_TEXT)
                Gosu.draw_rect(495, 270 + offset, 210, 5, Gosu::Color::WHITE, ZOrder::POPUP_TEXT)
            end
        end
    end

    def draw_hover(activate)
        pos_x, pos_y = @mouse_hover
        if  @annoucement == true &&
            pos_x >= 500 &&
            pos_x <= 700 &&
            pos_y >= 200 &&
            pos_y <= 260
                @button_hover = true
                if activate == true
                    @annoucement = false
                    @opponent_select = true
                    @animation_end = @tick + 50
                end
        else
            @button_hover = false
        end
    end

    def draw_preview(ship) #gets current grid position and draws a green box for how long the ship being placed is
        if @player_setup && @current_pos && @current_pos[0] == 1
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
        elsif @player_turn && @current_pos && @current_pos[0] == 0
            col = @current_pos[1]
            row = @current_pos[2]
            grid = @north_grid
            if grid[col][row].hit == false
                @cell_preview.draw(grid[col][row].x, grid[col][row].y)
                @target = [col, row]
            end
        else #makes sure origin is emptied if the mouse leaves the grid
            @origin = nil
            @target = nil
        end
    end

    def draw_placement(ship) #process for everything involved in visually placing ships
        draw_popup_window(0, nil)
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
                        if player_index == 0 && ship.hit == 2
                            ship.sprite.draw_rot(cell.x, cell.y + 35, ZOrder::SPRITE, ship.direction, 1, 1)
                        elsif player_index == 1
                            ship.sprite.draw_rot(cell.x, cell.y + 35, ZOrder::SPRITE, ship.direction, 1, 1)
                        end
                    else
                        if player_index == 0 && ship.hit == 2 
                            ship.sprite.draw(cell.x, cell.y, ZOrder::SPRITE)
                        elsif player_index == 1
                            ship.sprite.draw(cell.x, cell.y, ZOrder::SPRITE)
                        end
                    end
                end
                i += 1
            end
            player_index += 1
        end
    end

    def empty_cells(target, grid, col, row, direction) # checks that all cells for the ship being placed are empty
        i = 0
        result = true
        while i < target
            if direction == Rotation::NORTH && grid[col][row - i].occupied == true
                result = false
            elsif direction == Rotation::EAST && grid[col + i][row].occupied == true
                result = false
            end
            i += 1
        end
        return(result)
    end

    def select_origin() #fills the information for the current ship and it's cells based on current placement
        if @origin != nil
            col = @origin[0]
            row = @origin[1]
            ship = @current_ship
            grid = @south_grid
            empty = empty_cells(ship.size, grid, col, row, @rotation)
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
                        grid[col + i][row].ship = ship
                    end
                    i += 1
                end
                @current_ship_index += 1
                if @current_ship_index > 4
                    @player_setup = false
                    @rotation = nil
                    @player_turn = true
                end
            end
        end
    end

    def end_of_attack(player_index, target)
        if player_index == 1
            if target.occupied == true
                check_ships_hit()
                end_condition()
                if @game_end == 0
                    @result = "ENEMY DEFEATED. YOU WIN!"
                elsif target.ship.hit == 2
                    @result = "Enemy #{target.ship.name} SUNK!"
                else
                    @result = "Enemy #{target.ship.name} HIT!"
                end
                @player_hits_in_a_row += 1
            else
                @result = MISS.sample
                @player_hits_in_a_row = 0
            end
        else
            if target.occupied == true
                check_ships_hit()
                end_condition()
                if @game_end == 1
                    @result = "YOUR FLEET HAS SUNK!"
                elsif target.ship.hit == 2
                    @result = "Your #{target.ship.name} has SUNK!"
                else
                    @result = "Your #{target.ship.name} has been HIT!"
                end
                @enemy_hits_in_a_row += 1
                @enemy_misses_in_a_row = 0
            else
                @result = MISS.sample
                @enemy_hits_in_a_row = 0
                @enemy_misses_in_a_row += 1
            end
        end
    end

    # TURN FUNCTIONS
    def check_ships_hit()
        player_index = 0
        while player_index < 2
            ships = @ships[player_index]
            if player_index == 0
                grid = @north_grid
            else
                grid = @south_grid
            end
            i = 0
            while i < ships.length
                ship = ships[i]
                destroyed = true
                c = 0
                while c < ship.size
                    if ship.direction == Rotation::NORTH
                        cell = grid[ship.origin[0]][ship.origin[1] - c]
                        if cell.hit == true
                            ship.hit = 1
                        else
                            destroyed = false
                        end
                    elsif ship.direction == Rotation::EAST
                        cell = grid[ship.origin[0] + c][ship.origin[1]]
                        if cell.hit == true
                            ship.hit = 1
                        else
                            destroyed = false
                        end
                    end
                    c += 1
                end
                if destroyed == true
                    ship.hit = 2
                end
                destroyed = true
                i += 1
            end
            player_index += 1
        end
    end

    def check_cell_hit(cell)
        if cell.hit == true && cell.occupied == true
            @title_letter.draw_text('X', cell.x + 6, cell.y - 9, ZOrder::UI, 1, 1, Gosu::Color::RED)
        elsif cell.hit == true && cell.occupied != true
            @title_letter.draw_text('X', cell.x + 6, cell.y - 9, ZOrder::UI, 1, 1, Gosu::Color::WHITE)
        end
    end
    
    def draw_hit_cells()
        col = 0
        while col < 10
            row = 0
            while row < 10
                north_cell = @north_grid[col][row]
                south_cell = @south_grid[col][row]
                check_cell_hit(north_cell)
                check_cell_hit(south_cell)
                row += 1
            end
            col += 1
        end     
    end
    
    def draw_target()
        draw_popup_window(550, nil)
        @alert_header.draw_text_rel("Select target cell", 600, 750, ZOrder::POPUP_TEXT, 0.5, 0.5, 1, 1, ACCENT)
        draw_preview(0)
    end
    
    def select_target()
        if @target != nil && @current_pos[0] == 0
            col = @target[0]
            row = @target[1]
            grid = @north_grid
            target = grid[col][row]
            target.hit = true
            @select_target = false
            end_of_attack(1, target)
        end
        @popup_end = @tick + 100
    end

    def player_turn()
        if @result == nil
            @select_target = true
        end
    end


    # OPPONENT TURN FUNCTIONS
    def opponent_select_animation()
        grid = @south_grid
        alternate = ((@tick / 20) % 2)
        if alternate == 0 && @select_new == true
            @animate_col = rand(0..9)
            @animate_row = rand(0..9)
            @select_new = false
        elsif alternate == 1 && @select_new == false
            @animate_col = rand(0..9)
            @animate_row = rand(0..9)
            @select_new = true
        elsif @start_animation == true
            @animate_col = rand(0..9)
            @animate_row = rand(0..9)
            @start_animation = false
        end
        @cell_preview.draw(grid[@animate_col][@animate_row].x, grid[@animate_col][@animate_row].y)
        if @animation_end < @tick
            @opponent_select = false
            opponent_attack_select()
        end
    end

    def unhit_cell(grid)
        unhit_cells = Array.new()
        i = 0
        while i < 10
            r = 0
            while r < 10
                current = grid[i][r]
                if current.hit == false && current.occupied == true
                    unhit_cells << [i, r]
                end
                r += 1
            end
            i += 1
        end
        target = unhit_cells.sample
        return(target)
    end

    def least_used(grid)
        lowest_count = 0
        target_columns = Array.new()
        c = 0
        while c < 10
            count = 0
            r = 0
            while r < 10
                if grid[c][r].hit == false
                    count += 1
                end
                r += 1
            end
            if count == lowest_count
                target_columns << c
            elsif count > lowest_count
                lowest_count = count
                target_columns = Array.new()
                target_columns << c
            end
            c += 1
        end
        lowest_count = 0
        target_rows = Array.new()
        r = 0
        while r < 10
            count = 0
            c = 0
            while c < 10
                if grid[c][r].hit == false
                    count += 1
                end
                c += 1
            end
            if count == lowest_count
                target_rows << r
            elsif count > lowest_count
                lowest_count = count
                target_rows = Array.new()
                target_rows << r
            end
            r += 1
        end
        results = [target_columns.sample, target_rows.sample]
        return(results)
    end

    def random_attack(grid, col, row)
        if @round_count > 0 && @round_count < 7 && row == nil # select random cell not at edge in the first 6 rounds, as long as no ships have been hit
            target = grid[rand(1..8)][rand(1..8)]
            target.hit = true
            puts("Random attack")
        elsif row == nil && @enemy_misses_in_a_row > 6 #after 6 misses, there is a 25% chance the AI will hit a ship it hasn't hit yet, helps for game balancing
            chance = rand(0..3)
            hit = false
            puts("chance = #{chance.to_s}")
            until hit == true
                if chance == 0
                    col, row = unhit_cell(grid)
                    target = grid[col][row]
                    target.hit = true
                    hit = true
                else
                    target = grid[rand(0..9)][rand(0..9)]
                    if target.hit == false
                        target.hit = true
                        hit = true
                    end
                end
            end
        elsif row == nil # select least used column and grid
            hit = false
            col, row = least_used(grid)
            until hit == true
                target = grid[col][row]
                if target.hit == false
                    target.hit = true
                    hit = true
                    puts("Least hit")
                else
                    target = grid[rand(0..9)][rand(0..9)]
                    if target.hit == false
                        target.hit = true
                        hit = true
                        puts("Random fallback")
                    end
                end
            end
        else
            grid = @south_grid
            finished = false
            until finished == true
                direction = rand(0..3)
                if direction == 0 && row > 0 && grid[col][row - 1] && grid[col][row - 1].hit == false
                    target = grid[col][row - 1]
                    target.hit = true
                    finished = true
                elsif direction == 1 && col < 9 && grid[col + 1][row] && grid[col + 1][row].hit == false
                    target = grid[col + 1][row]
                    target.hit = true
                    finished = true
                elsif direction == 2 && row < 9 && grid[col][row + 1 ]&& grid[col][row + 1].hit == false
                    target = grid[col][row + 1]
                    target.hit = true
                    finished = true
                elsif direction == 3 && col > 0 && grid[col - 1][row] && grid[col - 1][row].hit == false
                    target = grid[col - 1][row]
                    target.hit = true
                    finished = true
                end
            end
        end
        end_of_attack(0, target)
    end

    def remaining_check(grid, col, row, ship, rotation)
        range = (ship.size - 2) #two cells have already been checked
        i = 0
        candidates = Array.new
        while i < range
            if rotation == 0
                if  (row + 2 + i) < 10 &&
                    grid[col][row + 2 + i].hit == false
                        candidates << grid[col][row + 2 + i]
                end
                if (row - 1 - i) >= 0 &&
                    grid[col][row - 1 - i].hit == false
                        candidates << grid[col][row - 1 - i]
                end
            elsif rotation == 1
                if  (row - 2 - i) >= 0 &&
                    grid[col][row - 2 - i].hit == false
                        candidates << grid[col][row - 2 - i]
                end
                if (row + 1 + i) < 10 &&
                    grid[col][row + 1 + i].hit == false
                        candidates << grid[col][row + 1 + i]
                end
            elsif rotation == 2
                if  (col + 2 + i) < 10 &&
                    grid[col + 2 + i][row].hit == false
                        candidates << grid[col + 2 + i][row]
                end
                if (col - 1 - i) >= 0 &&
                    grid[col - 1 - i][row].hit == false
                        candidates << grid[col - 1 - i][row]
                end
            elsif rotation == 3
                if  (col - 2 - i) >= 0 &&
                    grid[col - 2 - i][row].hit == false
                        candidates << grid[col - 2 - i][row]
                end
                if (col + 1 + i) < 10 &&
                    grid[col + 1 + i][row].hit == false
                        candidates << grid[col + 1 + i][row]
                end
            end
            if candidates.length == 1 #if on first pass there is only one option, it takes it
                target_cell = candidates[0]
                break
            elsif candidates.length == 2 #has one option in either direction after pass
                target_cell = candidates.sample
                break
            end
            i += 1
        end
        target_cell.hit = true
        end_of_attack(0, target_cell)
        return(true)
    end

    def intelligent_attack(grid, red_cells)
        i = 0
        attacked = false
        while i < red_cells.length
            col = red_cells[i][0]
            row = red_cells[i][1]
            ship = grid[col][row].ship
            if ship.hit == 2
                i += 1
            else
                if  row < 9 &&
                    grid[col][row + 1].hit == true && 
                    grid[col][row + 1].occupied == true &&
                    ship.name == grid[col][row + 1].ship.name #same ship so that function doesn't lead to false results
                        rotation = 0 #additional hit to the south
                        attacked = remaining_check(grid, col, row, ship, rotation)
                elsif row > 0 &&
                      grid[col][row - 1].hit == true && 
                      grid[col][row - 1].occupied == true &&
                      ship.name == grid[col][row - 1].ship.name
                        rotation = 1
                        attacked = remaining_check(grid, col, row, ship, rotation)
                elsif col < 9 &&
                      grid[col + 1][row].hit == true && 
                      grid[col + 1][row].occupied == true &&
                      ship.name == grid[col + 1][row].ship.name
                        rotation = 2
                        attacked = remaining_check(grid, col, row, ship, rotation)
                elsif col > 0 &&
                      grid[col - 1][row].hit == true && 
                      grid[col - 1][row].occupied == true &&
                      ship.name == grid[col - 1][row].ship.name
                        rotation = 3
                        attacked = remaining_check(grid, col, row, ship, rotation)
                else
                    attacked = random_attack(grid, col, row) #if no other cells from the same ship have been hit
                end
                i += 1
            end
            if attacked == true
                break
            end
        end
        return(attacked)
    end

    def opponent_attack_select()
        grid = @south_grid
        col = 0
        probability = 0
        red_cells = Array.new()
        prob_cells = Array.new()
        while col < 10
            row = 0
            while row < 10
                current_cell = grid[col][row]
                if current_cell.hit == true && current_cell.occupied == true
                    red_cells << [col, row]
                elsif current_cell.hit == true
                    prob_cells << [probability, col, row]
                    probability = 0
                elsif col == 9 && row == 9
                    prob_cells << [probability, col, row]
                    probability = 0
                else
                    probability += 1
                end
                row += 1
            end
            col += 1
        end
        attacked = false
        if red_cells[0] != nil
            attacked = intelligent_attack(grid, red_cells)
        end
        if attacked == false
            random_attack(grid, nil, nil)
        end
        @popup_end = @tick + 100
    end
                



    def button_down(id)
        case id
            when Gosu::KB_UP
                @rotation = Rotation::NORTH
            when Gosu::KB_RIGHT
                @rotation = Rotation::EAST
            when Gosu::MS_LEFT
                if @player_setup
                    select_origin()
                end
                if @player_turn && @result == nil #ensures no clicks during result popup
                    select_target()
                end
                if @annoucement == true
                    draw_hover(true)
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

    def mouse_position_global()
        position = [mouse_x, mouse_y]
        return(position)
    end

    def end_condition()
        player_index = 0
        while player_index < 2
            destroyed = true
            ships = @ships[player_index]
            s = 0
            while s < ships.length
                ship = ships[s]
                if ship.hit < 2
                    destroyed = false
                end
                s += 1
            end
            if destroyed == true
                @game_end = player_index
                break
            end
            player_index +=1
        end
    end


    def update
        @tick += 1
        @mouse_hover = mouse_position_global()
        if @player_setup
            player_setup()
            @current_pos = mouse_position_grid()
        end
        if @player_turn
            player_turn()
            @current_pos = mouse_position_grid()
            if @popup_end < @tick && @result != nil
                if @game_end != nil
                    close
                end
                @result = nil
                @player_turn = false
                @opponent_turn = true
                @annoucement = true
            end
            check_ships_hit()
        end
        if @opponent_turn
            if @popup_end < @tick && @result != nil
                if @game_end != nil
                    close
                end
                @result = nil
                @opponent_turn = false
                @player_turn = true
                @round_count += 1
            end
            check_ships_hit()
        end
    end

    def draw
        draw_ocean(@ocean)
        draw_game_title()
        draw_board()
            if @player_setup
                draw_placement(@current_ship)
            end
            if @player_turn
                if @select_target
                    draw_target()
                end
                if @result != nil
                    draw_popup_window(300, nil)
                    @alert_header.draw_text_rel(@result, 600, 500, ZOrder::POPUP_TEXT, 0.5, 0.5, 1, 1, ACCENT)
                end
            end
            if @opponent_turn
                if @annoucement == true
                    draw_hover(nil)
                    draw_popup_window(0, "Ready?")
                    @alert_header.draw_text_rel("Opponents Turn: Round #{@round_count}", 600, 162, ZOrder::POPUP_TEXT, 0.5, 0.5, 1, 1, ACCENT)
                end
                if @opponent_select == true
                    opponent_select_animation()
                end
                if @result != nil
                    draw_popup_window(0, nil)
                    @alert_header.draw_text_rel(@result, 600, 200, ZOrder::POPUP_TEXT, 0.5, 0.5, 1, 1, ACCENT)
                end
            end
        draw_ships()
        draw_hit_cells()
    end
end

window = BattleshipElite.new
window.show