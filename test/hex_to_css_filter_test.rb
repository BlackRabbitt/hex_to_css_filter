# frozen_string_literal: true

require 'minitest/autorun'
require './lib/hex_to_css_filter'

class HexToCssFilterTest < MiniTest::Test
  def setup
    @htf = HexToCssFilter.new
  end

  def test_hex_to_rgb
    assert_equal [255, 255, 255], @htf.send(:hex_to_rgb, '#ffffff')
    assert_equal [255, 255, 255], @htf.send(:hex_to_rgb, '#fff')
    assert_equal [74, 84, 85], @htf.send(:hex_to_rgb, '#4a5455')
    assert_equal [0, 0, 0], @htf.send(:hex_to_rgb, '#000000')
  end

  def test_rgb_to_hsl
    assert_equal [0, 0, 100], @htf.send(:rgb_to_hsl, [255, 255, 255])
    assert_equal [51.515151515151516, 6.918238993710685, 31.176470588235293], @htf.send(:rgb_to_hsl, [74, 84, 85])
    assert_equal [0, 0, 0], @htf.send(:rgb_to_hsl, [0, 0, 0])
    assert_equal [58.333333333333336, 56.25, 12.549019607843137], @htf.send(:rgb_to_hsl, [14, 32, 50])
  end

  def test_best_result_from
    best = @htf.send(:best_result_from, [14, 32, 50],
                     { values: [50.0, 20.0, 3750.0, 50.0, 100.0, 100.0], loss: 434.5391013816246 })
    assert_equal 6, best[:values].size
    assert best.key?(:loss)
  end

  def test_explore
    wide = @htf.send(:explore, [14, 32, 50])
    assert_equal 6, wide[:values].size
    assert wide.key?(:loss)
  end

  def test_spsa
    spsa_result = @htf.send(:spsa, [14, 32, 50], 5, [60, 180, 18_000, 600, 1.2, 1.2], 15, [50, 20, 3750, 50, 100, 100],
                            1000)
    assert_equal 6, spsa_result[:values].size
    assert spsa_result.key?(:loss)
  end

  def test_loss
    assert_equal 4.325000000000017,
                 @htf.send(:loss, target_color: [255, 255, 255], filters: [100, 0, 7488, 186, 101, 99])
    assert_equal 866.7093137254902, @htf.send(:loss, target_color: [14, 32, 50], filters: [100, 0, 7488, 186, 101, 99])
  end

  def test_multiply
    assert_equal [255, 255, 255], @htf.send(:multiply, [255, 255, 255], [1, 2, 3, 4, 5, 6, 7, 8, 9])
    assert_equal [14, 32, 50], @htf.send(:multiply, [1, 2, 3], [1, 2, 3, 4, 5, 6, 7, 8, 9])
    assert_equal [255, 255, 255], @htf.send(:multiply, [74, 84, 85], [1, 2, 3, 4, 5, 6, 7, 8, 9])
  end

  def test_invert
    assert_equal [0, 0, 0], @htf.send(:invert, [255, 255, 255])
    assert_equal [180.99999999999997, 171.00000000000003, 170.00000000000003], @htf.send(:invert, [74, 84, 85])
    assert_equal [255, 255, 255], @htf.send(:invert, [0, 0, 0])
  end

  def test_linear
    assert_equal [255, 255, 255], @htf.send(:linear, [201, 211, 107], 1, 1)
    assert_equal [129.5, 130.5, 132.5], @htf.send(:linear, [2, 3, 5], 1, 0.5)
  end
end
