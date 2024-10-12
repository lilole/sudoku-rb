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
