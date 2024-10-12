# frozen_string_literal: true

module Dmis
module Sudoku
  class ProgressInfo
    attr_accessor :hhmmss, :iter, :next_progress_time, :progress_text, :solver,
      :start_all, :start_iter, :throttle, :tries_all, :tries_iter

    def initialize(solver, throttle: 5.0)
      @solver   = solver
      @throttle = throttle

      @hhmmss = [0, 0, 0.0]
      reset_for_all
    end

    def reset_for_all
      @progress_text = "[not defined]"
      @info_formats = @info_statics = @srands_differ = nil
      @iter = @tries_all = 0
      @start_all = Time.now
      reset_for_loop
    end

    def reset_for_loop
      @tries_iter = 0
      @start_iter = Time.now
      set_next_progress_time(start_iter)
    end

    def disabled? = throttle < 0

    def need_show? = ! disabled? && Time.now >= next_progress_time

    def add_try(incr=1)
      @tries_iter += incr
      @tries_all  += incr
    end

    def add_iter(incr=1) = @iter += incr

    def show_progress
      return if disabled?
      ts = Time.now
      update_progress_text(ts).set_next_progress_time(ts).write
    end

    def write = $stderr.write(progress_text)

    def set_next_progress_time(ts=nil)
      disabled? or @next_progress_time = (ts || Time.now) + throttle
      self
    end

    def update_progress_text(ts=nil)
      ts ||= Time.now

      vals = [info_statics[0] + [tries_all]]
      et = set_hhmmss(start_all, ts)
      vals << [*hhmmss, tries_all / et]
      if solver.multi
        et = set_hhmmss(start_iter, ts)
        vals << [iter, solver.guesses[0].valids.size, tries_iter, *hhmmss, tries_iter / et]
      end

      info = info_formats[0, vals.size].zip(vals).map { |f, v| f % v }.join
      @progress_text = "\n#{solver}\n#{info}"
      self
    end

    def info_fields
      [
        %w[bsz=%d solve_style=%s board_srand=%d tries_all=%d].tap do |fields|
          fields.insert(3, "guess_srand=%d") if srands_differ?
        end,
        %w[et_all=%d:%02d:%05.2f try_rate_all=%3.1f/s],
        %w[iter=%d/%d tries_iter=%d et_iter=%d:%02d:%05.2f try_rate_iter=%3.1f/s]
      ]
    end

    def info_statics
      @info_statics ||= begin
        [
          [solver.board.block_size, solver.style, Board.rand_seed].tap do |vals|
            vals << Guesses.rand_seed if srands_differ?
          end
          # ...no statics after info line 0
        ]
      end
    end

    def info_formats
      @info_formats ||= info_fields.map { |fields| fields.join(" ") << "\n" }
    end

    def srands_differ?
      return false if @srands_differ == false
      @srands_differ ||= Board.rand_seed != Guesses.rand_seed
    end

    def set_hhmmss(start_ts, now_ts)
      et = now_ts - start_ts
      hhmmss[0] = (et / 3600.0).floor
      hhmmss[1] = (et % 3600.0 / 60.0).floor
      hhmmss[2] = (et % 60.0)
      et
    end
  end
end
end
