#! /usr/local/bin/ruby

require "gosu"

class Hash

  def has_key?(val)
    a = to_a
    a.each do |item|
      if item[0] == val
        return true
      end
    end
    false
  end

end

module Walls

WIDTH = 800
HEIGHT = 600
BLOCKSIZE = 20

private

class Board

  attr_accessor :grid, :images

  def initialize(level)
    @grid = []
    @images = {:air      => Gosu::Image.new("images/air.png"),
               :new_wall => Gosu::Image.new("images/new_wall.png"),
               :wall     => Gosu::Image.new("images/wall.png")}
    (HEIGHT / BLOCKSIZE).times do |y|
      new_row = []
      (WIDTH / BLOCKSIZE).times do |x|
        if (x == 0 || x == WIDTH / BLOCKSIZE - 1 ||
            y == 0 || y == HEIGHT / BLOCKSIZE - 1)
          new_row.push Wall.new(x, y, @images[:wall])
        else
          new_row.push Air.new(x, y, @images[:air])
        end
      end
      @grid.push new_row
    end
    @enemies = {}
    level.times do |i|
      rand_x = rand((WIDTH / BLOCKSIZE) - 2) + 1
      rand_y = rand((HEIGHT / BLOCKSIZE) - 2) + 1
      @enemies[Point.new(rand_x, rand_y)] = Enemy.new(rand_x, rand_y)
    end
  end

  def draw
    @grid.each do |row|
      row.each do |item|
        item.draw
      end
    end
    @enemies.each do |loc, enemy|
      enemy.draw
    end
  end

  def update
    return_val = nil
    changed_locs = []
    @enemies.each do |loc, enemy|
      var = enemy.update @grid
      if enemy.loc != loc
        changed_locs.push enemy
        @enemies.delete(loc)
      end
      if var == :hit_new_wall
        return_val = var
      end
    end
    changed_locs.each do |enemy|
      @enemies[enemy.loc] = enemy
    end
    @grid.each do |row|
      row.each do |item|
        item.checked = false if item.class == Air
      end
    end
    @grid.each do |row|
      row.each do |item|
        if item.class == Air
          var = check_blocks(item.x.floor, item.y.floor)
          if var == :stoped
            fill_blocks(item.x.floor, item.y.floor)
          end
        end
      end
    end
    walls = 0
    total = (WIDTH / BLOCKSIZE) * (HEIGHT / BLOCKSIZE)
    @grid.each do |row|
      row.each do |item|
        if item.class == Wall
          walls += 1
        end
      end
    end
    if (walls.to_f / total.to_f) * 100.0 >= 80
      return_val = :win
    end
    if return_val == nil
      return_val = (walls.to_f / total.to_f) * 100.0
    end
    return_val
  end

  def check_blocks(x, y)
    if @grid[y][x].class == Wall
      return :wall
    elsif @grid[y][x].class == NewWall
      return :new_wall
    elsif @grid[y][x].checked == true
      return :checked
    end
    if @grid[y][x].class == Air
      @grid[y][x].checked = true
    end
    var0 = check_blocks(x + 1, y + 1) # right
    var1 = check_blocks(x    , y + 1) # left
    var2 = check_blocks(x - 1, y + 1) # down
    var3 = check_blocks(x + 1, y    ) # up
    var4 = check_blocks(x - 1, y    ) # right
    var5 = check_blocks(x + 1, y - 1) # left
    var6 = check_blocks(x    , y - 1) # down
    var7 = check_blocks(x - 1, y - 1) # right
    if (var0 == :enemy || var1 == :enemy || var2 == :enemy || var3 == :enemy ||
        var4 == :enemy || var5 == :enemy || var6 == :enemy || var7 == :enemy)
      return :enemy
    end
    if @enemies.has_key?(Point.new(x, y))
      return :enemy
    end
    if ((var0 == :wall || var0 == :new_wall || var0 == :checked || var0 == :stoped) &&
        (var1 == :wall || var1 == :new_wall || var1 == :checked || var1 == :stoped) &&
        (var2 == :wall || var2 == :new_wall || var2 == :checked || var2 == :stoped) &&
        (var3 == :wall || var3 == :new_wall || var3 == :checked || var3 == :stoped) &&
        (var4 == :wall || var4 == :new_wall || var4 == :checked || var4 == :stoped) &&
        (var5 == :wall || var5 == :new_wall || var5 == :checked || var5 == :stoped) &&
        (var6 == :wall || var6 == :new_wall || var6 == :checked || var6 == :stoped) &&
        (var7 == :wall || var7 == :new_wall || var7 == :checked || var7 == :stoped))
      return :stoped
    end
    nil
  end

  def fill_blocks(x, y)
    if @grid[y][x].class == Wall
      return :wall
    elsif @grid[y][x].class == NewWall
      @grid[y][x] = Wall.new(x, y, @images[:wall])
      return :new_wall
    end
    @grid[y][x] = Wall.new(x, y, @images[:wall])
    var0 = fill_blocks(x + 1, y + 1) # right
    var1 = fill_blocks(x    , y + 1) # left
    var2 = fill_blocks(x - 1, y + 1) # down
    var3 = fill_blocks(x + 1, y    ) # up
    var4 = fill_blocks(x - 1, y    ) # right
    var5 = fill_blocks(x + 1, y - 1) # left
    var6 = fill_blocks(x    , y - 1) # down
    var7 = fill_blocks(x - 1, y - 1) # right
    if ((var0 == :wall || var0 == :new_wall || var0 == :stoped) &&
        (var1 == :wall || var1 == :new_wall || var1 == :stoped) &&
        (var2 == :wall || var2 == :new_wall || var2 == :stoped) &&
        (var3 == :wall || var3 == :new_wall || var3 == :stoped) &&
        (var4 == :wall || var4 == :new_wall || var4 == :stoped) &&
        (var5 == :wall || var5 == :new_wall || var5 == :stoped) &&
        (var6 == :wall || var6 == :new_wall || var6 == :stoped) &&
        (var7 == :wall || var7 == :new_wall || var7 == :stoped))
      return :stoped
    end
    nil
  end

end

class Player

  def initialize
    @x = 0.0
    @y = 0.0
    @image = Gosu::Image.new("images/player.png")
    @speed = 0.1
  end

  def draw
    @image.draw(@x * BLOCKSIZE, @y * BLOCKSIZE, 0)
  end

  def update(var, board)
    grid = board.grid
    if grid[@y.floor][@x.floor].class == Air
      grid[@y.floor][@x.floor] = NewWall.new(@x.floor, @y.floor, board.images[:new_wall])
    end
    if var == :hit_new_wall
      return :game_over
    end
    new_grid = grid
    if grid[@y.floor][@x.floor].class == Wall
      grid.each do |row|
        row.each do |item|
          if item.class == NewWall
            new_grid[item.y][item.x] = Wall.new(item.x, item.y, board.images[:wall])
          end
        end
      end
    end
    grid = new_grid
    grid
  end

  def up
    @y -= @speed if @y > 0
  end

  def down
    @y += @speed if @y < HEIGHT / BLOCKSIZE - 1
  end

  def left
    @x -= @speed if @x > 0
  end

  def right
    @x += @speed if @x < WIDTH / BLOCKSIZE - 1
  end

end

class Block

  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def draw
    @image.draw(@x * BLOCKSIZE, @y * BLOCKSIZE, 0)
  end

end

class Air < Block

  attr_accessor :checked

  def initialize(x, y, image)
    super x, y
    @image = image
    @checked = false
  end

end

class NewWall < Block

  def initialize(x, y, image)
    super x, y
    @image = image
  end

end

class Wall < Block

  def initialize(x, y, image)
    super x, y
    @image = image
  end

end

class Enemy

  attr_reader :x, :y

  def initialize(x, y)
    @x = x.to_f
    @y = y.to_f
    @xv = ((rand(2) * 2) - 1).to_f / 10
    @yv = ((rand(2) * 2) - 1).to_f / 10
    @image = Gosu::Image.new("images/enemy.png")
  end

  def draw
    @image.draw(@x * BLOCKSIZE, @y * BLOCKSIZE, 0)
  end

  def update(grid)
    return_val = nil
    grid.each do |row|
      row.each do |item|
        if item.class == Wall || item.class == NewWall
          if ((@x.floor     == item.x && @y.floor == item.y) ||
              (@x.floor + 1 == item.x && @y.floor == item.y))
            @xv *= -1
            if item.class == NewWall
              return_val = :hit_new_wall
            end
          end
          if ((@x.floor == item.x && @y.floor     == item.y) ||
              (@x.floor == item.x && @y.floor + 1 == item.y))
            @yv *= -1
            if item.class == NewWall
              return_val = :hit_new_wall
            end
          end
        end
      end
    end
    @x += @xv
    @y += @yv
    return_val
  end

  def loc
    return Point.new(@x.round, @y.round)
  end

end

class Point

  attr_accessor :x, :y

  def initialize(x, y)
    @x = x.to_i
    @y = y.to_i
  end

  def ==(other)
    if other.class != Point
      return false
    end
    @x == other.x && @y == other.y
  end

  def eql?(other)
    self == other
  end

  def to_hash
    @x ^ @y
  end

end

public

class Screen < Gosu::Window

  def initialize(level)
    super WIDTH, HEIGHT
    self.caption = "Walls"
    @level = level
    @board = Board.new @level
    @player = Player.new
    @game_over = nil
    @big_font = Gosu::Font.new(50)
    @font = Gosu::Font.new 20
    @percent = 0
  end

  def draw
    @board.draw
    @player.draw
    @font.draw_rel("#{@percent}%", WIDTH - 5, 2, 0, 1, 0, 1, 1, 0xff_ffff00)
    if @game_over == true
      @big_font.draw_rel("Game Over", WIDTH / 2, HEIGHT / 2, 0, 0.5, 0.5, 1, 1, 0xff_ff0000)
    elsif @game_over == false
      @big_font.draw_rel("You Won!!!", WIDTH / 2, HEIGHT / 2, 0, 0.5, 0.5, 1, 1, 0xff_00ff00)
    end
  end

  def update
    if @game_over != nil
      sleep 1
      if @game_over == false
        initialize(@level + 1)
      else
        exit
      end
    end
    var = @board.update
    new_grid = nil
    if var == :win
      @game_over = false
    else
      @percent = var.to_i if var.class == Float
      new_grid = @player.update var, @board
    end
    if new_grid == :game_over
      @game_over = true
    elsif new_grid != nil
      @board.grid = new_grid
    end
    if Gosu::button_down?(Gosu::KbW) || Gosu::button_down?(Gosu::KbUp)
      @player.up
    elsif Gosu::button_down?(Gosu::KbA) || Gosu::button_down?(Gosu::KbLeft)
      @player.left
    elsif Gosu::button_down?(Gosu::KbS) || Gosu::button_down?(Gosu::KbDown)
      @player.down
    elsif Gosu::button_down?(Gosu::KbD) || Gosu::button_down?(Gosu::KbRight)
      @player.right
    end
  end

end

end

Walls::Screen.new(1).show if __FILE__ == $0