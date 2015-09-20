# This represents a specific test case.
class SassSpec::TestCase
  def initialize(input_scss, expected_css, error_file, status_file, style, clean, options = {})
    @input_path = input_scss
    @expected_path = expected_css
    @error_path = error_file
    @status_path = status_file
    @output_style = style
    @clean_test = clean
    @options = options
  end

  def name
    @input_path.dirname.to_s.sub(Dir.pwd + "/", "")
  end

  def clean_test
    @clean_test
  end

  def output_style
    @output_style
  end

  def input_path
    @input_path
  end

  def expected_path
    @expected_path
  end

  def error_path
    @error_path
  end

  def verify_stderr?
    File.file?(@error_path)
  end

  def status_path
    @status_path
  end

  def should_fail?
    File.file?(@status_path)
  end

  def todo?
    @input_path.to_s.include? "todo"
  end

  def output
    if @output
      return @output
    end

    stdout, stderr, status = engine.compile(@input_path, @output_style)

    if @clean_test
      cleaned = _clean_output(stdout)
    else
      cleaned = _norm_output(stdout)
    end
    @output ||= [stdout, cleaned, stderr, status]
  end

  def expected
    output = File.read(@expected_path, :encoding => "utf-8")
    if @clean_test
      @expected ||= _clean_output(output)
    else
      @expected ||= _norm_output(output)
    end
  end

  def expected_error
    @expected_error = File.read(@error_path, :encoding => "utf-8")
  end

  def expected_status
    if should_fail?
      @expected_status = File.read(@status_path, :encoding => "utf-8").to_i
    else
      @expected_status = 0
    end
  end

  def engine
    @options[:engine_adapter]
  end

  def _norm_output(css)
    css = css.force_encoding('iso-8859-1').encode('utf-8')
    css.gsub(/(?:\r?\n)+/, "\n")
       .strip
  end

  def _clean_output(css)
    css = css.force_encoding('iso-8859-1').encode('utf-8')
    css.gsub(/\s+/, " ")
       .gsub(/ *\{/, " {\n")
       .gsub(/([;,]) */, "\\1\n")
       .gsub(/ *\} */, " }\n")
       .gsub(/;(?:\s*;)+/m, ";")
       .gsub(/;\r?\n }/m, " }")
       .strip
  end

end
