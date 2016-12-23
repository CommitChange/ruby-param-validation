require './lib/param_validation.rb'
require 'minitest/autorun'
require 'pry'

class ParamValidationTest < Minitest::Test

  def setup
  end

  def test_required
    begin; ParamValidation.new({}, {x: {required: true}})
    rescue ParamValidation::Error => e; e; end
    assert_equal :x, e.data[:key]
  end
  # If a key is not required, then don't run the tests on it
  def test_not_required_and_absent_then_tests_do_not_run
    ParamValidation.new({}, {x: {max: 100}})
    assert true
  end
  def test_not_blank_fail
    begin; ParamValidation.new({x: ''}, {x: {not_blank: true}})
    rescue ParamValidation::Error => e; e; end
    assert_equal :x, e.data[:key]
  end
  def test_not_blank_fail_nil
    begin; ParamValidation.new({x: nil}, {x: {not_blank: true, required: true}})
    rescue ParamValidation::Error => e; e; end
    assert_equal :x, e.data[:key]
  end
  def test_not_blank_succeed
    ParamValidation.new({x: 'x'}, {x: {not_blank: true}})
    assert true
  end
  def test_require_no_err
    begin; ParamValidation.new({x: 1}, {x: {required: true}})
    rescue ParamValidation::Error => e; end
    assert e.nil?
  end
  def test_absent
    begin; ParamValidation.new({x: 1}, {x: {absent: true}})
    rescue ParamValidation::Error => e; e; end
    assert_equal :x, e.data[:key]
  end
  def test_not_included_in
    begin; ParamValidation.new({x: 1}, {x: {not_included_in: [1]}})
    rescue ParamValidation::Error => e; e; end
    assert_equal :x, e.data[:key]
  end
  def test_included_in
    begin; ParamValidation.new({x: 1}, {x: {included_in: [2]}})
    rescue ParamValidation::Error => e; e; end
    assert_equal :x, e.data[:key]
  end
  def test_format
    begin; ParamValidation.new({x: 'x'}, {x: {format: /y/}})
    rescue ParamValidation::Error => e; e; end
    assert_equal :x, e.data[:key]
  end
  def test_is_integer
    begin; ParamValidation.new({x: 'x'}, {x: {is_integer: true}})
    rescue ParamValidation::Error => e; e; end
    assert_equal :x, e.data[:key]
  end
  def test_is_float
    begin; ParamValidation.new({x: 'x'}, {x: {is_float: true}})
    rescue ParamValidation::Error => e; e; end
    assert_equal :x, e.data[:key]
  end
  def test_min_length
    begin; ParamValidation.new({x: []}, {x: {min_length: 2}})
    rescue ParamValidation::Error => e; e; end
    assert_equal :x, e.data[:key]
  end
  def test_max_length
    begin; ParamValidation.new({x: [1,2,3]}, {x: {max_length: 2}})
    rescue ParamValidation::Error => e; e; end
    assert_equal e.data[:key], :x
  end
  def test_length_range
    begin; ParamValidation.new({x: [1,2,3,4]}, {x: {length_range: 1..3}})
    rescue ParamValidation::Error => e; e; end
    assert_equal e.data[:key], :x
  end
  def test_length_equals
    begin; ParamValidation.new({x: [1,2]}, {x: {length_equals: 1}})
    rescue ParamValidation::Error => e; e; end
    assert_equal e.data[:key], :x
  end
  def test_min
    begin; ParamValidation.new({x: 1}, {x: {min: 2}})
    rescue ParamValidation::Error => e; e; end
    assert_equal e.data[:key], :x
  end
  def test_max
    begin; ParamValidation.new({x: 4}, {x: {max: 2}})
    rescue ParamValidation::Error => e; e; end
    assert_equal e.data[:name], :max
  end
  def test_in_range
    begin; ParamValidation.new({x: 1}, {x: {in_range: 2..4}})
    rescue ParamValidation::Error => e; e; end
    assert_equal e.data[:val], 1
  end
  def test_equals
    begin; ParamValidation.new({x: 1}, {x: {equals: 2}})
    rescue ParamValidation::Error => e; e; end
    assert_equal "x should equal #{2}", e.to_s
  end
  def test_root_array_of_hashes
    begin; ParamValidation.new({x: 1}, {root: {array_of_hashes: {x: {required: true}}}})
    rescue ParamValidation::Error => e; e; end
    assert_equal "Please pass in an array of hashes", e.to_s
  end
  def test_root_array_of_hashes_with_nesting_ok
    v = ParamValidation.new([{'x' => 1}, {x: 1}], {root: {array_of_hashes: {x: {is_integer: true}}}})
    assert_equal v, v # test that it does not raise
  end
  def test_root_array_of_hashes_with_nesting
    begin; ParamValidation.new([{x: 1}, {x: 'hi'}], {root: {array_of_hashes: {x: {is_integer: true}}}})
    rescue ParamValidation::Error => e; e; end
    assert_equal "x should be an integer", e.to_s
  end

  def test_add_validator
    ParamValidation.add_validator(:dollars){|val, arg, data| val =~ /^\d+(\.\d\d)?$/}
    begin
      ParamValidation.new({x: 'hi'}, {x: {dollars: true}})
    rescue ParamValidation::Error => e
      e
    end
    assert_equal :dollars, e.data[:name]
  end
  def test_set_message
    ParamValidation.add_validator(:dollars){|val, arg, data| val =~ /^\d+(\.\d\d)?$/}
    ParamValidation.set_message(:dollars){|h| "#{h[:key]} must be a dollar amount"}
    begin
      ParamValidation.new({x: 'hi'}, {x: {dollars: true}})
    rescue ParamValidation::Error => e
      e
    end
    assert_equal "x must be a dollar amount", e.to_s
  end

  def test_custom_validator
  end
end
