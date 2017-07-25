# frozen_string_literal: true
module RangeUtils
  class << self
    # Inverses given ranges within given boundaries
    # e.g.
    # [ [2016-01-01 09:00:00, 2016-01-01 17:00:00] ], 2016-01-01 00:00:00, 2016-01-01 24:00:00
    # becomes
    # [ [2016-01-01 00:00:00, 2016-01-01 09:00:00], [2016-01-01 17:00:00, 2016-01-01 24:00:00] ]
    def inverse_within_boundaries(ranges, left_boundary, right_boundary)
      return [[left_boundary, right_boundary]] if ranges.empty?

      sorted = select_unique_ranges(ranges.sort).flatten!

      if left_boundary > sorted.min || right_boundary < sorted.max
        raise(ArgumentError, "Bounding range [#{left_boundary}, #{right_boundary}] should include #{ranges}")
      end

      bound_ranges!(sorted, left_boundary, right_boundary).each_slice(2).select { |pair| pair.first < pair.last }
    end

    def select_unique_ranges(ranges, index = 0)
      return ranges if (index + 1) == ranges.size

      range = ranges[index]

      dupes = ranges.reduce([]) do |acc, other|
        # Don't compare with self
        next(acc) if range.object_id == other.object_id

        case compare_ranges(range, other)
        when 1
          acc + [other]
        when -1
          [range]
        else
          acc
        end
      end

      # Only increment index if we didn't remove any dupes
      select_unique_ranges(ranges - dupes, dupes.empty? ? index + 1 : index)
    end

    private

    def bound_ranges!(ranges, left, right)
      ranges.unshift(left)
      ranges.push(right)

      ranges
    end

    def compare_ranges(left, right)
      l_start, l_finish = left
      r_start, r_finish = right

      if l_start <= r_start && l_finish >= r_finish
        1
      elsif l_start >= r_start && l_finish <= r_finish
        -1
      else
        0
      end
    end
  end
end
