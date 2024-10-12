# frozen_string_literal: true

module Dmis
module Sudoku
  class ValidCache
    attr_reader :invalid_keys, :lines

    def initialize
      @invalid_keys = Set[]
      @lines = {}
    end

    def set(key, &block)
      invalid_keys.delete(key)
      lines[key] = block.call
    end

    def fetch(key) = lines.fetch(key)

    def key?(key) = ! invalid_keys.member?(key) && lines.key?(key)

    def invalidate(key) = invalid_keys << key
  end
end
end
