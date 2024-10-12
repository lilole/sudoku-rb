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
  class Cli
    def self.usage(msg=nil, exit_code: 1)
      prog = File.basename($0)
      $stderr << <<~END

        #{msg || "Online help."}

        Description:
          Create random Sudoku puzzles of any size.

        Usage:
          #{prog} [-a|--all] [-h|-?|--help] [-S|--slow MILLISECS] \\
              [-s|--solve-style STYLE] [-T|--throttle SECS] [-w|--watch] \\
              [block_size [board_rand_seed [guess_rand_seed]]]

        Where:
          --all, -a => Try to find all possible solutions. Default is only first
              solution.

          --help, -?, -h => This text.

          --slow, -S => Slow down with given millisecs between guesses.
              Useful with --throttle of 0.

          --solve-style, -s => Use the given board pattern sequence for guesses when
              solving, for researching. Style names are:
                row_wise, col_wise, row_wise_reverse, col_wise_reverse
              Default is row_wise. See `solve_styles.rb` for full details.

          --throttle, -T => Specify seconds between progress updates. Default 3.
              0 shows every board change.

          --watch, -w => During puzzle creation, display progress of the board.
              TODO: Describe watch output.

          block_size => Size of one block of the puzzle. Minimum is 2. Default is 3,
              which makes the usual 9x9.

          board_rand_seed => For testing, allow using the same random seed for the
              board across runs. Default is a random 12 digit integer.
              Use --watch to display the seed value to use again.

          guess_rand_seed => For testing, allow using the same random seed for initial
              guesses across runs. Default is the same as board_rand_seed.
              Use --watch to display the seed value to use again.

        Sample params:
          bsz=5 solve_style=col_wise_reverse board_srand=473238364308 tries_all=2328128
          bsz=5 solve_style=col_wise_reverse board_srand=671801876774 tries_all=63830460
          bsz=5 solve_style=row_wise         board_srand=473238364308 tries_all=376975130
          bsz=5 solve_style=col_wise         board_srand=473238364308 tries_all=1217488955
          bsz=5 solve_style=col_wise_reverse board_srand=933262306056 tries_all=2515027231

      END
      exit(exit_code) if exit_code
    end

    attr_reader :args, :config

    def initialize(args)
      @args   = args
      @config = Config.new
    end

    def run
      parse_args
      $stdout << "\n" << Core.new(config).run.join("\n")
      true
    rescue => e
      $stderr << "#{e.class}: #{e.message}: #{e.backtrace[0,5].join("\n")}"
      false
    end

    def parse_args
      b_size = b_seed = g_seed = nil
      idx = -1
      while (arg = args[idx += 1])
        if arg[0] == "-"
          ok = 0
          arg =~ /^-[^-]*[h?]|^--help$/     && ok += 1 and Cli.usage
          arg =~ /^-[^-]*a|^--all$/         && ok += 1 and config.all = true
          arg =~ /^-[^-]*S|^--slow$/        && ok += 1 and config.slow = args[idx += 1].to_f / 1000
          arg =~ /^-[^-]*s|^--solve-style$/ && ok += 1 and config.solve_style = args[idx += 1]
          arg =~ /^-[^-]*T|^--throttle$/    && ok += 1 and config.throttle = args[idx += 1].to_f
          arg =~ /^-[^-]*w|^--watch$/       && ok += 1 and config.watch_board = true
          Cli.usage "Invalid option: #{arg.inspect}" if ok < 1
        else
          if    ! b_size then b_size = arg.to_i
          elsif ! b_seed then b_seed = arg.to_i
          elsif ! g_seed then g_seed = arg.to_i
          else  Cli.usage "Invalid args: #{args[idx..-1].inspect}"
          end
        end
      end

      config.block_size = b_size || 3
      Cli.usage "Arg 'block_size' invalid: #{config.block_size}" if config.block_size < 2

      config.solve_style ||= "row_wise"
      config.throttle ||= 3.0
      Board.set_rand_seed(b_seed)
      Guesses.set_rand_seed(g_seed || Board.rand_seed)
    end
  end
end
end
