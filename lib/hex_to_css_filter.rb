# frozen_string_literal: true

require 'hex_to_css_filter/matrices'

class HexToCssFilter
  include Matrices

  class << self
    def convert(target_color)
      new.convert(target_color)
    end
  end

  def convert(target_color)
    rgb = hex_to_rgb(target_color)
    wide_solutions = explore(rgb)
    result = best_result_from(rgb, wide_solutions)

    # adjust hue-rotate output to degree
    result[:values][3] = (result[:values][3] * 3.6).round

    { css_filter: to_css(result[:values]), loss: result[:loss] }
  end

  def hex_to_rgb(input)
    rgb = /#(..?)(..?)(..?)/.match(input)[1..3]
    rgb.map! { |x| x + x } if input.size == 4
    rgb.map!(&:hex)

    rgb
  end

  private

  def to_css(values)
    "invert(#{values[0]}%) sepia(#{values[1]}%) saturate(#{values[2]}%) hue-rotate(#{values[3]}deg) brightness(#{values[4]}%) contrast(#{values[5]}%)"
  end

  def explore(rgb)
    a = 5
    c = 15
    arr = [60, 180, 18_000, 600, 1.2, 1.2]

    best = { loss: Float::INFINITY }
    i = 0
    while best[:loss] > 25 && i < 3
      initial = [50, 20, 3750, 50, 100, 100]
      result = spsa(rgb, a, arr, c, initial, 1000)
      best = result if result[:loss] < best[:loss]
      i += 1
    end

    best
  end

  def best_result_from(rgb, wide)
    a = wide[:loss]
    c = 2
    a1 = a + 1
    arr = [0.25 * a1, 0.25 * a1, a1, 0.25 * a1, 0.2 * a1, 0.2 * a1]
    spsa(rgb, a, arr, c, wide[:values], 500)
  end

  def rgb_to_hsl(input)
    r, g, b = input.map { |x| x / 255.0 }
    max = [r, g, b].max
    min = [r, g, b].min

    h = s = 0
    l = (max + min) / 2.to_f

    if max != min
      d = max - min
      s = l > 0.5 ? d / (2 - max - min).to_f : d / (max + min).to_f
      case max
      when r
        h = (g - b) / d.to_f + (g < b ? 6 : 0)
      when g
        h = (b - r) / d.to_f + 2
      when b
        h = (r - g) / d.to_f + 4
      end

      h /= 6.0
    end

    [h * 100, s * 100, l * 100]
  end

  def spsa(rgb, a, arr, c, values, iters)
    alpha = 1
    gamma = 0.16666666666666666

    best = nil
    best_loss = Float::INFINITY
    deltas = []
    high_args = []
    low_args = []

    (0...iters).each do |k|
      ck = c / ((k + 1)**gamma).to_f
      6.times do |i|
        deltas[i] = rand(0.0..1.0) > 0.5 ? 1 : -1
        high_args[i] = values[i] + ck * deltas[i]
        low_args[i] = values[i] - ck * deltas[i]
      end

      loss_diff = loss(target_color: rgb, filters: high_args) - loss(target_color: rgb, filters: low_args)
      6.times do |i|
        g = loss_diff / (2 * ck).to_f * deltas[i]
        ak = arr[i] / ((a + k + 1)**alpha).to_f
        values[i] = fix(values[i] - ak * g, i)
      end

      loss = loss(target_color: rgb, filters: values)
      if loss < best_loss
        best = values
        best_loss = loss
      end
    end

    { values: best, loss: best_loss }
  end

  def fix(value, idx)
    max = 100
    if idx == 2 # saturate
      max = 7500
    elsif [4, 5].include?(idx) # brightness || contrast
      max = 200
    end

    if idx == 3 # hue-rotate
      if value > max
        value = value % max
      elsif value.negative?
        value = max + value % max
      end
    elsif value.negative?
      value = 0
    elsif value > max
      value = max
    end
    value
  end

  def loss(target_color:, filters:, base_color: [0, 0, 0])
    base_color = invert(base_color, filters[0] / 100.0)
    base_color = sepia(base_color, filters[1] / 100.0)
    base_color = saturate(base_color, filters[2] / 100.0)
    base_color = hue_rotate(base_color, filters[3] * 3.6)
    base_color = brightness(base_color, filters[4] / 100.0)
    base_color = contrast(base_color, filters[5] / 100.0)

    hsl_base_color = rgb_to_hsl(base_color)
    hsl_target_color = rgb_to_hsl(target_color)

    loss = 0
    base_color.each_with_index { |c, i| loss += (c - target_color[i]).abs }
    hsl_base_color.each_with_index { |c, i| loss += (c - hsl_target_color[i]).abs }

    loss
  end

  def invert(rgb, value = 1)
    rgb.map! { |c| clamp((value + c / 255.0 * (1 - 2 * value)) * 255) }
  end

  def sepia(rgb, value = 1)
    multiply(rgb, sepia_matrix(value))
  end

  def saturate(rgb, value = 1)
    multiply(rgb, saturate_matrix(value))
  end

  def hue_rotate(rgb, angle = 0)
    multiply(rgb, hue_matrix(angle))
  end

  def brightness(rgb, value = 1)
    linear(rgb, value)
  end

  def contrast(rgb, value = 1)
    linear(rgb, value, -(0.5 * value) + 0.5)
  end

  def clamp(value)
    return 255 if value > 255
    return 0 if value.negative?

    value
  end

  def multiply(rgb, matrix)
    new_rgb = [0, 0, 0]
    new_rgb[0] = clamp(rgb[0] * matrix[0] + rgb[1] * matrix[1] + rgb[2] * matrix[2])
    new_rgb[1] = clamp(rgb[0] * matrix[3] + rgb[1] * matrix[4] + rgb[2] * matrix[5])
    new_rgb[2] = clamp(rgb[0] * matrix[6] + rgb[1] * matrix[7] + rgb[2] * matrix[8])

    new_rgb
  end

  def linear(rgb, slope = 1, intercept = 0)
    rgb.map! { |c| clamp(c * slope + intercept * 255) }
  end
end
