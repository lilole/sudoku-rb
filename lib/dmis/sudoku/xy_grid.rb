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
  module XyGrid
    include Enumerable

    def init_grid(width, height, init_value=nil)
      @grid_w, @grid_h, @grid_init_value = width, height, init_value
      @row_cache = ValidCache.new
      @grid = new_grid(width, height, init_value)
    end

    def new_grid(width, height, init_value) = Array.new(width) { Array.new(height, init_value) }

    def copy_grid(target_object) = @grid.each.with_index { |col, x| target_object.set_column(x, col) }

    def each(&block)
      if ! block
        block = ->(x, y, v) { [x, y, v] }
        return to_enum(:each, &block)
      end
      @grid.each.with_index do |col, x|
        col.each.with_index do |v, y|
          block.call(x, y, v)
        end
      end
    end

    def [](x, y)
      @grid[x][y]
    end

    def []=(x, y, value)
      @row_cache.invalidate(y)
      @grid[x][y] = value
    end

    def values(x, y, w, h)
      new_grid(w, h, nil).tap do |result|
        xo = x; yo = y
        for_cells(x, y, w, h) { |x, y, v| result[x - xo][y - yo] = v }
      end
    end

    def set_columns(x, y, w, h, columns)
      raise "Invalid column count: Must be #{w}: Found #{columns.size}" if columns.size != w
      raise "Invalid column size: All columns must be #{h} values" if columns.any? { |col| col.size != h }
      xo = x; yo = y
      for_cells(xo, yo, w, h) do |x, y, _v|
        self[x, y] = columns[x - xo][y - yo]
        @row_cache.invalidate(y) if x == xo
      end
      self
    end

    def set_value(x, y, value)
      self[x, y] = value
      self
    end

    def set_row(y, values)
      raise "Invalid row size #{values.size}: Must be #{@grid_w}" if values.size != @grid_w
      (0...@grid_w).each { |x| self[x, y] = values[x] }
      @row_cache.invalidate(y)
      self
    end

    def set_column(x, values)
      raise "Invalid column size #{values.size}: Must be #{@grid_h}" if values.size != @grid_h
      (0...@grid_h).each { |y| self[x, y] = values[y]; @row_cache.invalidate(y) }
      self
    end

    def column(x)
      @grid[x]
    end

    def row(y)
      if @row_cache.key?(y)
        @row_cache.fetch(y)
      else
        @row_cache.set(y) { (0...@grid_w).map { |x| self[x, y] } }
      end
    end

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
