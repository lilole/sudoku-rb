# frozen_string_literal: true

module Dmis
module Sudoku
  module SolveStyles
    def self.xy_pairs_pattern(style, board)
      case style
      when "row_wise"         then style_row_wise(board)
      when "col_wise"         then style_col_wise(board)
      when "row_wise_reverse" then style_row_wise_rev(board)
      when "col_wise_reverse" then style_col_wise_rev(board)
      else raise "Style #{style.inspect} not supported"
      end
    end

    def self.style_row_wise(board)
      [].tap do |pairs|
        for y in (0...board.height)
          for x in (0...board.width)
            pairs << [x, y]
          end
        end
      end
    end

    def self.style_col_wise(board)
      [].tap do |pairs|
        for x in (0...board.width)
          for y in (0...board.height)
            pairs << [x, y]
          end
        end
      end
    end

    def self.style_row_wise_rev(board)
      [].tap do |pairs|
        for y in (0...board.height).to_a.reverse
          for x in (0...board.width)
            pairs << [x, y]
          end
        end
      end
    end

    def self.style_col_wise_rev(board)
      [].tap do |pairs|
        for x in (0...board.width).to_a.reverse
          for y in (0...board.height)
            pairs << [x, y]
          end
        end
      end
    end
  end
end
end
