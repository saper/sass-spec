require 'minitest'

def run_spec_test(test_case, options = {})
  if options[:skip_todo] && test_case.todo?
    skip "Skipped todo"
  end

  assert File.exists?(test_case.input_path), "Input #{test_case.input_path} file does not exist"

  output, clean_output, error, status = test_case.output

  if options[:nuke]
    if status != 0
      File.open(test_case.status_path, "w+") do |f|
        f.write(status)
        f.close
      end
    end

    if error.length > 0
      File.open(test_case.error_path, "w+") do |f|
        f.write(error)
        f.close
      end
    end

    File.open(test_case.expected_path, "w+") do |f|
      f.write(output)
      f.close
    end
  end

  assert File.exists?(test_case.expected_path), "Expected #{test_case.expected_path} file does not exist"

  if status != 0 && !options[:unexpected_pass] && (options[:nuke] || !test_case.should_fail?)
    msg = "Command `#{options[:engine_adapter]}` did not complete:\n\n#{error}"

    raise msg
  end


  if options[:unexpected_pass] && test_case.todo? && (test_case.expected == clean_output)
    raise "#{test_case.input_path} passed a test we expected it to fail"
  end

  if test_case.todo? && options[:unexpected_pass]
    assert test_case.expected != clean_output, "Marked as todo and passed"
  elsif !test_case.todo? || !options[:skip_todo]
    if test_case.should_fail?
       # XXX Ruby returns 65 etc. SassC returns 1
       assert status > 0, "Expected did not match status"
    end
    assert_equal test_case.expected, clean_output, "Expected did not match output"
    if test_case.verify_stderr?
      # Compare only first line of error output (we can't compare stacktraces etc.)
      error_msg = error.each_line.next.rstrip
      expected_error_msg = test_case.expected_error.each_line.next.rstrip
      assert_equal expected_error_msg, error_msg, "Expected did not match error"
    end
  end
end


# Holder to put and run test cases
class SassSpec::Test < Minitest::Test
  def self.create_tests(test_cases, options = {})
    test_cases[0..options[:limit]].each do |test_case|
      define_method('test__' << test_case.output_style + "_" + test_case.name) do
        run_spec_test(test_case, options)
      end
    end
  end
end
