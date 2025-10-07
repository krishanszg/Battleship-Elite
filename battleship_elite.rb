require 'rubygems'
require 'gosu'

module ZOrder
    BACKGROUND, BOARD, SPRITE, UI, POPUP = *0..4
end

CHARACTER = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]

TITLE = ["B", "A", "T", "T", "L", "E", "S", "H", "I", "P", " ", "E", "L", "I", "T", "E"]

CELL_SIZE = 40

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

module ShipType
    CARRIER = 5
    BATTLESHIP = 4
    DESTROYER = 3
    SUBMARINE = 2
    PATROL = 1
end

module ShipSprite
    CARRIER = "sprites/carrier.png"
    BATTLESHIP = "sprites/battleship.png"
    DESTROYER = "sprites/destroyer.png"
    SUBMARINE = "sprites/submarine.png"
    PATROL = "sprites/patrolBoat.png"
end

class Ship
    attr_accessor :ship, :origin, :direction, :size, :sunk
    def initialize(ship, origin, direction, size)
        @ship = ship
        @origin = origin
        @direction = direction
        @size = size
        @sunk = false
    end
end

class BattleshipElite < Gosu::Window

    # Initialize window, player, opponent, and ocean
    def initialize
        super 1200, 1000
        self.caption = "Battleship Elite"

        @cell_image = Gosu::Image.new('sprites/grid.png')
        @tick = 0
        @letters = Gosu::Font.new(40, name: 'sprites/BoldPixels.ttf')
        @title_letter = Gosu::Font.new(56, name: 'sprites/BoldPixels.ttf')
        
        @ocean = initialize_ocean()

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

    def initialize_ocean()
        ocean_tiles = Array.new()
        ocean_tiles = Gosu::Image.load_tiles("sprites/ocean.png", 128, 128, tileable: true)
        ocean = Ocean.new(ocean_tiles, 128, 128)
        return(ocean)
    end

    def player_init()
        
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

    def draw_boards()
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
        draw_resource_area(@south_grid[9][0], "YOU", 80)
    end

    def draw_resource_area(ref_cell, text, offset)
        @title_letter.draw_text(text, (ref_cell.x + 250 + offset), (ref_cell.y - 6) , ZOrder::BOARD, 1, 1, Gosu::Color.argb(255 ,255, 87, 129))
    end

    def update
        @tick += 1
    end

    def draw
        draw_ocean(@ocean)
        draw_boards()
        draw_game_title()
    end
end

window = BattleshipElite.new
window.show