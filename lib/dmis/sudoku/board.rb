# frozen_string_literal: true

module Dmis
module Sudoku
  class Board
    include XyGrid

    class << self
      attr_reader :rand_seed
    end

    def self.rng
      set_rand_seed if ! rand_seed
      @rng ||= Random.new(rand_seed)
    end

    def self.set_rand_seed(value=nil)
      @rng = nil
      @rand_seed = value || new_rand_seed
    end

    def self.new_rand_seed = 100_000_000_000 + rand(900_000_000_000)

    attr_reader :block_size, :height, :width

    def initialize(block_size, seed: true)
      @block_size      = block_size
      @height = @width = block_size ** 2

      init_grid(width, height, 0)
      seed and seed!
    end

    def copy
      Board.new(block_size, seed: false).tap do |new_board|
        copy_grid(new_board)
      end
    end

    def valid?(x, y) = valid_guess?(x, y, self[x, y])

    def valid_guess?(x, y, value) # Super optimize!
      slow = self[x, y] == value

      c = column(x)
      prev, c[y] = c[y], 0 if slow
      invalid = c.member?(value)
      c[y] = prev if slow
      return false if invalid

      r = row(y)
      prev, r[x] = r[x], 0 if slow
      invalid = r.member?(value)
      r[x] = prev if slow
      return false if invalid

      prev, @grid[x][y] = @grid[x][y], 0 if slow # Bypass XyGrid caches
      valid = catch(:valid_guess?) do
        check_proc = valid_check_block_proc_for(value)
        for_cells(*block_origin(x, y), block_size, block_size, &check_proc)
        true
      end
      @grid[x][y] = prev if slow
      valid
    end

    def valid_check_block_proc_for(check_val)
      cache = (@valid_check_block_proc_for ||= {})
      cache[check_val] ||= ->(_x, _y, v) { throw(:valid_guess?, false) if v == check_val }
    end

    def valids(x, y)
      (1..width).select { |try_value| valid_guess?(x, y, try_value) }
    end

    def block(x, y)
      bx, by = block_origin(x, y)
      [].tap do |result|
        for_cells(bx, by, block_size, block_size) { |_x, _y, v| result << v }
      end
    end

    def block_origin(x, y)
      cache = (@block_origin_cache ||= Hash.new { |h, k| h[k] = Array.new(height) })
      cache[x][y] ||= [x - x % block_size, y - y % block_size]
    end

    def seed!
      each { |x, y, _v| self[x, y] = 0 }
      vals = (1..width).to_a
      for b in (0...block_size)
        3.times { vals.shuffle!(random: Board.rng) }
        bx, by = block_origin(b * block_size, b * block_size)
        for y in (0...block_size)
          for x in (0...block_size)
            self[bx + x, by + y] = vals[y * block_size + x]
          end
        end
      end
    end

    def to_s
      (+"").tap do |s|
        for y in (0...height)
          vals = row(y).map { |v| v < 1 ? "  " : "%2d" % v }
          s << vals.join(" ") << "\n"
        end
      end
    end
  end
end
end
