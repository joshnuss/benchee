defmodule Benchee.Formatters.ConsoleTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import Benchee.Benchmark, only: [no_input: 0]
  doctest Benchee.Formatters.Console

  alias Benchee.Formatters.Console
  alias Benchee.{Suite, Statistics}

  @console_config %{comparison: true, unit_scaling: :best}
  @config %Benchee.Configuration{formatter_options: %{console: @console_config}}
  describe ".output" do
    test "formats and prints the results right to the console" do
      jobs = %{
        no_input() => %{
          "Second" => %Statistics{
            average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
          },
          "First"  => %Statistics{
            average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
          }
        }
      }

      output = capture_io fn ->
        Console.output %Suite{statistics: jobs, configuration: @config}
      end

      assert output =~ ~r/First/
      assert output =~ ~r/Second/
      assert output =~ ~r/200/
      assert output =~ ~r/5.00 K/
      assert output =~ ~r/10.00%/
      assert output =~ ~r/195.5/
    end
  end

  describe ".format_jobs" do
    test "sorts the the given stats fastest to slowest" do
      jobs = %{
        "Second" => %Statistics{
          average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
        },
        "Third"  => %Statistics{
          average: 400.0, ips: 2_500.0, std_dev_ratio: 0.1, median: 375.0
        },
        "First"  => %Statistics{
          average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
        }
      }

      [_header, result_1, result_2, result_3 | _dont_care ] =
        Console.format_jobs(jobs, @console_config)

      assert Regex.match?(~r/First/,  result_1)
      assert Regex.match?(~r/Second/, result_2)
      assert Regex.match?(~r/Third/,  result_3)
    end

    test "adjusts the label width to longest name" do
      jobs = %{
        "Second" => %Statistics{
          average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
        },
        "First"  => %Statistics{
          average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
        }
      }

      expected_width = String.length "Second"
      [header, result_1, result_2 | _dont_care ] =
        Console.format_jobs(jobs, @console_config)

      assert_column_width "Name", header, expected_width
      assert_column_width "First", result_1, expected_width
      assert_column_width "Second", result_2, expected_width

      third_name  = String.duplicate("a", 40)
      third_stats = %Statistics{
        average: 400.0, ips: 2_500.0, std_dev_ratio: 0.1, median: 375.0
      }
      longer_jobs = Map.put jobs, third_name, third_stats

      # Include extra long name, expect width of 40 characters
      expected_width_wide = String.length third_name
      [header, result_1, result_2, result_3 | _dont_care ] =
        Console.format_jobs(longer_jobs, @console_config)

      assert_column_width "Name", header, expected_width_wide
      assert_column_width "First", result_1, expected_width_wide
      assert_column_width "Second", result_2, expected_width_wide
      assert_column_width third_name, result_3, expected_width_wide
    end

    test "creates comparisons" do
      jobs = %{
        "Second" => %Statistics{
          average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
        },
        "First"  => %Statistics{
          average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
        }
      }

      [_, _, _, comp_header, reference, slower] =
        Console.format_jobs(jobs, @console_config)

      assert Regex.match? ~r/Comparison/, comp_header
      assert Regex.match? ~r/^First\s+10.00 K$/m, reference
      assert Regex.match? ~r/^Second\s+5.00 K\s+- 2.00x slower/, slower
    end

    test "can omit the comparisons" do
      jobs = %{
        "Second" => %Statistics{
          average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
        },
        "First"  => %Statistics{
          average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
        }
      }

      output =  Enum.join Console.format_jobs(
                  jobs,
                  %{
                    comparison:   false,
                    unit_scaling: :best
                  })

      refute Regex.match? ~r/Comparison/i, output
      refute Regex.match? ~r/^First\s+10.00 K$/m, output
      refute Regex.match? ~r/^Second\s+5.00 K\s+- 2.00x slower/, output
    end

    test "adjusts the label width to longest name for comparisons" do
      second_name = String.duplicate("a", 40)
      jobs = %{
        second_name => %Statistics{
          average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
        },
        "First"  => %Statistics{
          average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
        }
      }

      expected_width = String.length second_name
      [_, _, _, _comp_header, reference, slower] =
        Console.format_jobs(jobs, @console_config)

      assert_column_width "First", reference, expected_width
      assert_column_width second_name, slower, expected_width
    end

    test "doesn't create comparisons with only one benchmark run" do
      jobs  = %{
        "First" => %Statistics{
          average: 100.0,
          ips: 10_000.0,
          std_dev_ratio: 0.1,
          median: 90.0
        }
      }

      assert [header, result] = Console.format_jobs jobs, @console_config
      refute Regex.match? ~r/(Comparison|x slower)/, Enum.join([header, result])
    end

    test "formats small averages and medians more precisely" do
      fast = %{
        "First" => %Statistics{
          average: 0.15,
          ips: 10_000.0,
          std_dev_ratio: 0.1,
          median: 0.0125
        }
      }

      assert [_, result] = Console.format_jobs fast, @console_config
      assert Regex.match? ~r/0.150\s?μs/, result
      assert Regex.match? ~r/0.0125\s?μs/, result
    end

    test "doesn't output weird 'e' formats" do
      jobs = %{
        "Job" => %Statistics{
          average: 11000.0,
          ips: 12000.0,
          std_dev_ratio: 13000.0,
          median: 140000.0
        }
      }

      assert [_, result] = Console.format_jobs jobs, @console_config

      refute result =~ ~r/\de\d/
      assert result =~ "11.00 ms"
      assert result =~ "12.00 K"
      assert result =~ "13000"
      assert result =~ "140.00 ms"
    end
  end

  describe ".format" do
    @header_regex ~r/Name.+ips.+average.+deviation.+median.*/
    test "with multiple inputs and just one job" do
      statistics = %{
        "My Arg" => %{
          "Job" => %Statistics{
            average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
          }
        },
        "Other Arg" => %{
          "Job" => %Statistics{
            average: 400.0, ips: 2_500.0, std_dev_ratio: 0.15, median: 395.0
          }
        }
      }

      [my_arg, other_arg] =
        Console.format(%Suite{statistics: statistics, configuration: @config})

      [input_header, header, result] = my_arg
      assert input_header =~ "My Arg"
      assert header =~ @header_regex
      assert result =~ ~r/Job.+5.+200.+10\.00%.+195\.5/

      [input_header_2, header_2, result_2] = other_arg
      assert input_header_2 =~ "Other Arg"
      assert header_2 =~ @header_regex
      assert result_2 =~ ~r/Job.+2\.5.+400.+15\.00%.+395/

    end

    test "with multiple inputs and two jobs" do
      statistics = %{
        "My Arg" => %{
          "Job" => %Statistics{
            average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
          },
          "Other Job" => %Statistics{
            average: 100.0, ips: 10_000.0, std_dev_ratio: 0.3, median: 98.0
          }
        },
        "Other Arg" => %{
          "Job" => %Statistics{
            average: 400.0, ips: 2_500.0, std_dev_ratio: 0.15, median: 395.0
          },
          "Other Job" => %Statistics{
            average: 250.0, ips: 4_000.0, std_dev_ratio: 0.31, median: 225.5
          }
        }
      }

      [my_arg, other_arg] =
        Console.format(%Suite{statistics: statistics, configuration: @config})

      [input_header, _header, other_job, job, _comp, ref, slower] = my_arg
      assert input_header =~ "My Arg"
      assert other_job =~ ~r/Other Job.+10.+100.+30\.00%.+98\.0/
      assert job =~ ~r/Job.+5.+200.+10\.00%.+195\.5/
      ref =~ ~r/Other Job/
      slower =~ ~r/Job.+slower/

      [input_header_2, _, other_job_2, job_2, _, ref_2, slower_2] = other_arg
      assert input_header_2 =~ "Other Arg"
      assert other_job_2 =~ ~r/Other Job.+4.+250.+31\.00%.+225\.5/
      assert job_2 =~ ~r/Job.+2\.5.+400.+15\.00%.+395/
      ref_2 =~ ~r/Other Job/
      slower_2 =~ ~r/Job.+slower/
    end
  end

  defp assert_column_width(name, string, expected_width) do
    # add 13 characters for the ips column, and an extra space between the columns
    expected_width = expected_width + 14
    n = Regex.escape name
    regex = Regex.compile! "(#{n} +([0-9\.]+( [[:alpha:]]+)?|ips))( |$)"
    assert Regex.match? regex, string
    [column | _] = Regex.run(regex, string, capture: :all_but_first)
    column_width = String.length(column)

    assert expected_width == column_width, """
Expected column width of #{expected_width}, got #{column_width}
line:   #{inspect String.trim(string)}
column: #{inspect column}
"""
  end
end
