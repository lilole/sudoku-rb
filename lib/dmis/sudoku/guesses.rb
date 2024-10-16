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
  class Guesses
    class << self
      attr_reader :rand_seed
    end

    def self.rng
      set_rand_seed if ! rand_seed
      @rng ||= Random.new(rand_seed)
    end

    def self.set_rand_seed(value=nil)
      @rng = nil
      @rand_seed = value || Board.rand_seed || Board.set_rand_seed
    end

    def self.find_unsolved_xys(board, style: "default")
      xy_pairs = SolveStyles.xy_pairs_pattern(style, board)
      xy_pairs.map do |(x, y)|
        (v = board[x, y]) < 1 ? [x, y] : nil
      end.compact
    end

    attr_reader :cur_idx, :max_idx, :valids, :x, :y

    def initialize(x, y, board)
      @x         = x
      @y         = y
      @valids    = board.valids(x, y)

      raise "Can't find at least one valid guess for [#{x}, #{y}] in:\n#{board}" if valids.empty?

      3.times { valids.shuffle!(random: Guesses.rng) }

      @cur_idx = 0
      @max_idx = valids.size - 1
    end

    def done? = cur_idx == max_idx

    def next? = cur_idx < max_idx

    def value = valids[cur_idx]

    def next
      @cur_idx += 1
      self
    end

    def reset
      @cur_idx = 0
      self
    end

    def rotate(count=1)
      valids.rotate!(count)
      self
    end
  end
end
end
