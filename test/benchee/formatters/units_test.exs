defmodule Benchee.Formatters.UnitsTest do
  use ExUnit.Case
  import Benchee.Units

  test ".format 123_456_789_012 scales to :billion" do
    assert scale_count(123_456_789_012) == {123.456789012, :billion}
  end

  test ".format 12_345_678_901 scales to :billion" do
    assert scale_count(12_345_678_901) == {12.345678901, :billion}
  end

  test ".format 1_234_567_890 scales to :billion" do
    assert scale_count(1_234_567_890) == {1.23456789, :billion}
  end

  test ".format 123_456_789 scales to :million" do
    assert scale_count(123_456_789) == {123.456789, :million}
  end

  test ".format 12_345_678 scales to :million" do
    assert scale_count(12_345_678) == {12.345678, :million}
  end

  test ".format 1_234_567 scales to :million" do
    assert scale_count(1_234_567) == {1.234567, :million}
  end

  test ".format 123_456.7 scales to :thousand" do
    assert scale_count(123_456.7) == {123.4567, :thousand}
  end

  test ".format 12_345.67 scales to :thousand" do
    assert scale_count(12_345.67) == {12.34567, :thousand}
  end

  test ".format 1_234.567 scales to :thousand" do
    assert scale_count(1_234.567) == {1.234567, :thousand}
  end

  test ".format 123.4567 scales to :one" do
    assert scale_count(123.4567) == {123.4567, :one}
  end

  test ".format 12.34567 scales to :one" do
    assert scale_count(12.34567) == {12.34567, :one}
  end

  test ".format 1.234567 scales to :one" do
    assert scale_count(1.234567) == {1.234567, :one}
  end

  test ".format 0.001234567 scales to :one" do
    assert scale_count(0.001234567) == {0.001234567, :one}
  end

  test ".format_count(1_000_000)" do
    assert format_count(1_000_000) == "1.00M"
  end

  test ".format_count(1_000.1234)" do
    assert format_count(1_000.1234) == "1.00K"
  end

  test ".format_count(123.4)" do
    assert format_count(123.4) == "123.40"
  end

  test ".format_count(1.234)" do
    assert format_count(1.234) == "1.23"
  end

  test ".format_duration(98.7654321)" do
    assert format_duration(98.7654321) == "98.77μs"
  end

  test ".format_duration(987.654321)" do
    assert format_duration(987.654321) == "987.65μs"
  end

  test ".format_duration(9_876.54321)" do
    assert format_duration(9_876.54321) == "9.88ms"
  end

  test ".format_duration(98_765.4321)" do
    assert format_duration(98_765.4321) == "98.77ms"
  end

  test ".format_duration(987_654.321)" do
    assert format_duration(987_654.321) == "987.65ms"
  end

  test ".format_duration(9_876_543.21)" do
    assert format_duration(9_876_543.21) == "9.88s"
  end

  test ".format_duration(98_765_432.19)" do
    assert format_duration(98_765_432.19) == "1.65m"
  end

  test ".format_duration(987_654_321.9876)" do
    assert format_duration(987_654_321.9876) == "16.46m"
  end

  test ".format_duration(9_876_543_219.8765)" do
    assert format_duration(9_876_543_219.8765) == "2.74h"
  end
end
