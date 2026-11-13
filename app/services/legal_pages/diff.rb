# frozen_string_literal: true

module LegalPages
  # Simple line diff used by the admin version comparison screen. It returns
  # rows as [kind, text] where kind is :same, :added or :removed.
  class Diff
    def self.call(old_text, new_text)
      new(old_text, new_text).call
    end

    def initialize(old_text, new_text)
      @old_lines = old_text.to_s.lines.map(&:chomp)
      @new_lines = new_text.to_s.lines.map(&:chomp)
    end

    def call
      table = lcs_table
      rows = []
      i = 0
      j = 0
      while i < @old_lines.length && j < @new_lines.length
        if @old_lines[i] == @new_lines[j]
          rows << [ :same, @old_lines[i] ]
          i += 1
          j += 1
        elsif table[i + 1][j] >= table[i][j + 1]
          rows << [ :removed, @old_lines[i] ]
          i += 1
        else
          rows << [ :added, @new_lines[j] ]
          j += 1
        end
      end

      rows.concat(@old_lines[i..].to_a.map { |line| [ :removed, line ] })
      rows.concat(@new_lines[j..].to_a.map { |line| [ :added, line ] })
      rows
    end

    private

    # dp[i][j] = LCS length of old[i..] and new[j..].
    def lcs_table
      rows = @old_lines.length
      columns = @new_lines.length
      table = Array.new(rows + 1) { Array.new(columns + 1, 0) }

      (rows - 1).downto(0) do |i|
        (columns - 1).downto(0) do |j|
          table[i][j] = if @old_lines[i] == @new_lines[j]
            table[i + 1][j + 1] + 1
          else
            [ table[i + 1][j], table[i][j + 1] ].max
          end
        end
      end

      table
    end
  end
end
