# frozen_string_literal: true

## Copyright 2024 Dan Higgins
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #     http://www.apache.org/licenses/LICENSE-2.0
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.

module Dmis
module Sudoku
  # Basic management of a 2-D grid of values, with extra logic for extra speed
  # when checking rows or columns for a specific value.

  # This design avoids caches by keeping both a column-wise and a row-wise copy
  # of the grid. While this doubles memory, it avoids all possible calculation
  # when accessing entire rows or columns.
  #
  module XyGrid
    include Enumerable

    def init_grid(width, height, init_value=nil)
      @grid_w, @grid_h, @grid_init_value = width, height, init_value
      new_grid(width, height)
    end

    def new_grid(width, height)
      @grid_cols = Array.new(width) { Array.new(height, @grid_init_value) }
      @grid_rows = Array.new(height) { Array.new(width, @grid_init_value) }
    end

    def copy_grid(target_grid)
      @grid_rows.each.with_index { |row, y| target_grid.set_row(y, row) }
    end

    def each(&block)
      if ! block
        block = ->(x, y, v) { [x, y, v] }
        return to_enum(:each, &block)
      end
      @grid_rows.each.with_index do |row, y|
        row.each.with_index do |v, x|
          block.call(x, y, v)
        end
      end
    end

    def [](x, y)
      @grid_cols[x][y]
    end

    def []=(x, y, value)
      @grid_cols[x][y] = @grid_rows[y][x] = value
    end

    def set_value(x, y, value)
      self[x, y] = value
      self
    end

    def set_row(y, values)
      raise "Invalid row size #{values.size}: Must be #{@grid_w}" if values.size != @grid_w
      (0...@grid_w).each { |x| self[x, y] = values[x] }
      self
    end

    def set_column(x, values)
      raise "Invalid column size #{values.size}: Must be #{@grid_h}" if values.size != @grid_h
      (0...@grid_h).each { |y| self[x, y] = values[y] }
      self
    end

    def column(x) = @grid_cols[x]

    def row(y) = @grid_rows[y]

    def for_cells(x, y, w, h, &block)
      if ! block
        block = ->(x, y, v) { [x, y, v] }
        return to_enum(:for_cells, x, y, w, h, &block)
      end
      ye = y + h; y  = y - 1
      xe = x + w; x0 = x - 1
      while (y += 1) < ye
        x = x0
        while (x += 1) < xe
          block.call(x, y, self[x, y])
        end
      end
    end
  end
end
end
