require 'rubygems'
require 'gosu'

module ZOrder
    BACKGROUND, BOARD, SPRITE, UI, POPUP = *0..4
end

CHARACTER = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]

TITLE = ["B", "A", "T", "T", "L", "E", "S", "H", "I", "P", " ", "E", "L", "I", "T", "E"]

CELL_SIZE = 40

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
    false => {text: "NOT READY", color: Gosu::Color.argb(255, 255, 0, 0)}
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

        @cell_image = Gosu::Image.new('sprites/grid.png')
        @tick = 0
        @resource_text = Gosu::Font.new(20, name: 'sprites/BoldPixels.ttf')
        @letters = Gosu::Font.new(40, name: 'sprites/BoldPixels.ttf')
        @title_letter = Gosu::Font.new(56, name: 'sprites/BoldPixels.ttf')
        
        @ocean = initialize_ocean()
        initialize_grid()
        @ships = initialize_ships()
    end

        def initialize_grid()
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

        def initialize_ships()
            ships = Array.new(5) {Array.new(5)}
            # 2D array of ships, top row for opponent, bottom row for player. In this way, it is a pseudo-boolean reference, with 0 being false and 1 being true for the player
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

        def initialize_ocean()
            ocean_tiles = Array.new()
            ocean_tiles = Gosu::Image.load_tiles("sprites/ocean.png", 128, 128, tileable: true)
            ocean = Ocean.new(ocean_tiles, 128, 128)
            return(ocean)
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
            @title_letter.draw_text(TITLE[letter], (cell.x + 700), (cell.y + 20) , ZOrder::BOARD, 1, 1, Gosu::Color.argb(255 ,255, 87, 129))
            letter += 1
            row += 1
        end
        row = 0
        while (row < 10)
            cell = @south_grid[9][row]
            @title_letter.draw_text(TITLE[letter], (cell.x + 700), (cell.y - 20) , ZOrder::BOARD, 1, 1, Gosu::Color.argb(255 ,255, 87, 129))
            letter += 1
            row += 1
        end
    end

    def draw_cell(cell, row_index, column_index)
        @cell_image.draw(cell.x, cell.y, ZOrder::BOARD)
        if (column_index == 0)
            if (row_index > 8) # Adjust for 2 digit numbers
                @letters.draw_text((row_index + 1).to_s, (cell.x - 47), (cell.y) , ZOrder::BOARD, 1, 1, Gosu::Color.argb(255 ,255, 87, 129))
            else # Normal single digit numbers
                @letters.draw_text((row_index + 1).to_s, (cell.x - 35), (cell.y) , ZOrder::BOARD, 1, 1, Gosu::Color.argb(255 ,255, 87, 129))
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
                    @letters.draw_text(CHARACTER[column_index], (north_cell.x + 10), (north_cell.y + 46) , ZOrder::BOARD, 1, 1, Gosu::Color.argb(255 ,255, 87, 129))
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
        @letters.draw_text("SHIPS", (ref_cell.x + 200), (ref_cell.y + 70) , ZOrder::BOARD, 1, 1, Gosu::Color.argb(255 ,255, 87, 129))
        @letters.draw_text("POWER-UPS", (ref_cell.x + 480), (ref_cell.y + 70) , ZOrder::BOARD, 1, 1, Gosu::Color.argb(255 ,255, 87, 129))
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

    def update
        @tick += 1
    end

    def draw
        draw_ocean(@ocean)
        draw_game_title()
        draw_board()
    end
end

window = BattleshipElite.new
window.show