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
  class Solver
    attr_reader :board, :guesses, :multi, :progress_callback, :progress_info, :slow, :style, :unsolved_xys

    def solve(board, multi: nil, only_xys: nil, guess_throttle: nil, progress_throttle: 5, progress_callback: nil, style: nil)
      @board             = board
      @multi             = multi
      @progress_callback = progress_callback
      @slow              = guess_throttle
      @style             = style || "row_wise"
      @unsolved_xys      = only_xys || Guesses.find_unsolved_xys(board, style: @style)

      return [board] if unsolved_xys.empty?
      assert_unsolved if only_xys
      @guesses = unsolved_xys.map { |(x, y)| Guesses.new(x, y, board) }
      @progress_info = ProgressInfo.new(self, throttle: progress_throttle.to_f)
      guesses[0].valids.slice!(1..-1) if ! multi

      main_loop
    end

    def main_loop
      first_guess = guesses[0].valids[0]
      solved_boards = []
      loop do
        progress_info.add_iter
        solved = inner_loop
        progress_info.disabled? or show_progress

        solved_boards << board.copy if solved

        guesses[0].rotate
        break if guesses[0].valids[0] == first_guess # Rotated back to beginning

        reset_board_unsolved
        progress_info.reset_for_loop
      end
      solved_boards
    end

    def inner_loop
      guesses       = @guesses # Local var is faster
      max_guess_idx = guesses.size - 1
      cur_guess_idx = 0
      cur_guess     = guesses[cur_guess_idx]
      max_tries     = max_tries_estimate # Rotate guess if no solution before this count
      $stderr << "+ Max tries for this board: #{max_tries}\n" if progress_info.iter == 1
      catch(:solve_inner_result) do
        loop do # Super optimize!
          progress_info.add_try

          if board.valid_guess?(cur_guess.x, cur_guess.y, cur_guess.value)
            board[cur_guess.x, cur_guess.y] = cur_guess.value
            break if cur_guess_idx == max_guess_idx # Solved!
            cur_guess = guesses[cur_guess_idx += 1]
            show_progress if progress_info.need_show?
          else
            if cur_guess.done?
              loop do
                throw(:solve_inner_result, false) if cur_guess_idx == 0 # No solution!
                cur_guess.reset
                cur_guess = guesses[cur_guess_idx -= 1]
                board[cur_guess.x, cur_guess.y] = 0
                break if cur_guess.next?
              end
              show_progress if progress_info.need_show?
            end
            cur_guess.next
          end

          break if progress_info.tries_iter >= max_tries # Give up!
          sleep(slow) if slow
        end
        final_check
      end
    end

    def final_check
      board.all? { |x, y, _v| board.valid?(x, y) }.tap do |all_valid|
        if all_valid
          $stderr.puts "\nSuccess: Solved all #{unsolved_xys.size} initial unsolved cells."
        else
          $stderr.puts "\nError: No solution found for #{unsolved_xys.size} initial unsolved cells."
        end
      end
    end

    def reset_board_unsolved
      guesses.each do |guess|
        guess.reset
        board[guess.x, guess.y] = 0
      end
    end

    def max_tries_estimate
      factor = [(guesses.size.to_f - 54) / 446 * 4 + 1, 1.0].max
      (1e+9 * factor).round
    end

    def assert_unsolved
      raise "Unsolved cells must be < 1" if unsolved_xys.any? { |xy| board[*xy] > 0 }
    end

    def show_progress
      if progress_callback
        progress_callback.call(progress_info)
      else
        progress_info.show_progress
      end
    end

    def to_s
      (+"").tap do |s|
        for y in (0...board.height)
          vals = board.row(y).map.with_index do |v, x|
            if    v < 1                 then "  "
            elsif seed_block?(x, y)     then "\033[90m%2d\033[0m" % v # Gray
            elsif last_guess?(x, y, -3) then "\033[91m%2d\033[0m" % v # Red
            elsif last_guess?(x, y, -2) then "\033[93m%2d\033[0m" % v # Yellow
            elsif last_guess?(x, y, -1) then "\033[92m%2d\033[0m" % v # Green
            elsif block_origin?(x, y)   then "\033[94m%2d\033[0m" % v # Blue
            else  "%2d" % v
            end
          end
          s << vals.join(" ") << "\n"
        end
        s << "\n"
        for y in (0...board.height)
          vals = (0...board.width).map { |x| guess_by_xy(x, y) }.map do |guess|
            if   guess.nil? then "  "
            else
              v = guess.max_idx - guess.cur_idx
              if    v == 0             then "\033[92m 0\033[0m"      # Green
              elsif guess.cur_idx == 0 then "\033[91m%2d\033[0m" % v # Red
              else  "%2d" % v
              end
            end
          end
          s << vals.join(" ") << "\n"
        end
      end
    end

    def seed_block?(x, y)
      bx, by = board.block_origin(x, y)
      bx == by
    end

    def block_origin?(x, y) = [x, y] == board.block_origin(x, y)

    def last_guess?(x, y, offset) = guess_by_xy(x, y)&.valids&.[](offset) == board[x, y]

    def guess_by_xy(x, y)
      idx = (@guesses_idx ||= Array.new(board.width) { Array.new(board.height) })
      idx[x][y] ||= guesses.detect { |g| g.x == x && g.y == y }
    end
  end
end
end
