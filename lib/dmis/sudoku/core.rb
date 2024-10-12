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
  class Core
    attr_accessor :board, :config, :progress_throttle, :solver

    def initialize(config)
      @config = config

      @board             = Board.new(config.block_size)
      @solver            = Solver.new
      @progress_throttle = config.watch_board ? config.throttle : -1

      RubyVM::YJIT.enable if defined?(RubyVM::YJIT)
    end

    def run
      solver.solve(board,
        progress_throttle: progress_throttle, guess_throttle: config.slow,
        multi: config.all, style: config.solve_style
      )
    end

    def test_run
      solved = []
      for xy in [[board.block_size, 0]]
        valids = board.valids(*xy)
        test_vals = [valids.first, valids.last]

        solved.clear
        for test_val in test_vals
          board.set_value(*xy, test_val)
          solver.solve(board.copy, progress_throttle: progress_throttle)
          solved << solver.progress_info
        end

        s = "Valids for #{xy.inspect}: #{valids.inspect}"
        puts "\n%s\n%s" % ["_" * s.size, s]
        puts "\nSolved boards for #{xy.inspect} in #{test_vals.inspect}:"
        solved.each.with_index do |progress_info, i|
          progress_info.update_progress_text.write
          puts "test_val=#{test_vals[i]}"
        end
      end
    end
  end
end
end
