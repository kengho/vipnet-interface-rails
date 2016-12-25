module Themizer
  ARGUMENT_ERROR =
    "Themizer: argument error in 'init(args)': "\
    "args should be Hash, "\
    "args should contain ':themes' key, "\
    "args[:themes] should be Array of strings"

  def init(args)
    raise ARGUMENT_ERROR unless args.class == Hash
    raise ARGUMENT_ERROR unless args[:themes]
    raise ARGUMENT_ERROR unless args[:themes].class == Array
    raise ARGUMENT_ERROR unless args[:themes].map { |e| e.to_s } == args[:themes]
    @themes = args[:themes]
    @debug = args[:debug] || false
  end

  def themize(action = :expand, theme = "\"\"", &block)
    return unless block_given?
    src_erb = _extract_block(block)
    return unless src_erb
    _debug(src_erb, "processing block")
    src_sass = ERB.new(src_erb).result

    case action
    when :expand
      maps, selectors = _mapize(src_sass)
      src_sass_expanded = maps
      unless selectors.strip.empty?
        # if you add "\"\"" to @themes, sass won't compile
        # because it cannot iterate through list with empty strings in it
        # therefore, you have to process unthemed sass separately
        src_sass_expanded << _expand_tilda(selectors, "\"\"")

        # apply & sass operator
        #
        # ".form {
        #   ...
        # }"
        # =>
        # "@each $theme in theme1, theme2 {
        #   #{$theme} { &
        #     ...
        #   }
        # }"
        src_sass_expanded << "\n@each $theme in #{@themes.join(', ')} {"
        src_sass_expanded << ".\#{$theme} { & "
        src_sass_expanded << _expand_tilda(selectors)
        src_sass_expanded << "}}"
        @themes.each do |theme|
          src_sass_expanded.gsub!(".#{theme} body", "body.#{theme}")
        end
      end

    when :contract
      src_sass_expanded = _contract_tilda(src_sass, theme)
    end

    _debug(src_sass_expanded, "resulting sass")

    yield.gsub!(src_sass, src_sass_expanded)
  end

  def unthemize(theme = "\"\"", &block)
    themize(:contract, theme, &block)
  end

  # naive attempt to extract "themize do" block source
  # considering there are probably other "do ... end" blocks inside;
  def _extract_block(block)
    src_file_path = block.source_location[0]
    block_start_line_number = block.source_location[1]

    src_file_content = File.open(src_file_path).read
    lines_after_block_start = src_file_content.split("\n")[block_start_line_number..-1]

    # block already starts with one "do"
    do_counter = 1
    # assuming that "do themize" and  corresponding "end" placed on separate lines
    block_end_index = 1
    lines_after_block_start.each_with_index do |line, i|
      # http://stackoverflow.com/a/11899069/6376451
      do_counter += line.scan(/<%.*?do.*?%>/).size
      do_counter -= line.scan(/<%.*?end.*?%>/).size
      if line =~ /\s*<%\s*end\s*%>/ && do_counter == 0
        block_end_index = i
        break
      end
    end
    return nil if block_end_index == 0

    lines_after_block_start[0..block_end_index-1].join("\n")
  end

  SASS_VAR_TILDA_IMPORTANT = /(?<sass_var>\$[^\s:~;]*)~(?<important>[^;]*);/

  # expant tilda to if ... map-get
  #
  # "color: $form-color~;"
  # =>
  # "color: if(map-has-key($form-color, $theme), map-get($form-color, $theme), map-get($form-color, default));"
  def _expand_tilda(sass, theme = "$theme", ending = ";")
    # http://stackoverflow.com/a/28982676/6376451
    sass.gsub(
      SASS_VAR_TILDA_IMPORTANT,
      "if("\
        "map-has-key(\\k<sass_var>, #{theme}), "\
        "map-get(\\k<sass_var>, #{theme}), "\
        "map-get(\\k<sass_var>, \"\")"\
      ")\\k<important>#{ending}"
    )
  end

  # reduce tilda to single map-get
  #
  # color: $form-color~;
  # =>
  # color: map-get($form-color, "\"\"");
  def _contract_tilda(sass, theme)
    sass.gsub(
      SASS_VAR_TILDA_IMPORTANT,
      "map-get(\\k<sass_var>, #{theme})\\k<important>;"
    )
  end

  # expand sass vars denifitions with tildas into maps
  #
  # <% themize %>
  # $table-border: $table-border-thickness solid $white~;
  # .someclass { color: $table-border~; }
  # <% end %>
  # =>
  # [
  #   "$table-border: (
  #     default: $table-border-thickness solid map-get($white, default);
  #     dark: $table-border-thickness solid map-get($white, dark);
  #     contrast: $table-border-thickness solid map-get($white, contrast);
  #   );",
  #   ".someclass { color: $table-border~; }"
  # ]
  def _mapize(sass)
    maps = ""

    # http://stackoverflow.com/a/18089658/6376451
    expressions = sass.split(/(?<=[;])/).map { |e| e.strip }
    themes_expanded = ["\"\""] + @themes
    expressions.each_with_index do |expression, i|
      if expression =~ /^(?<map_name>\$.*):(?<map_value>.*;)/
        maps << "#{Regexp.last_match(:map_name)}: ("
        themes_expanded.each do |theme|
          maps << "#{theme}: #{_expand_tilda(Regexp.last_match(:map_value), theme, ',')}"
        end
        maps << ");"
        expressions[i].clear
      end
    end
    selectors = expressions
      .map { |e| e.strip }
      .reject { |e| e.empty? }
      .join("\n")

    [maps, selectors]
  end

  def _debug(message, description)
    if @debug
      puts "\n##########################################"
      puts "# begin Themizer #{description}"
      puts "\n\n#{message}\n\n"
      puts "# end Themizer #{description}"
      puts "##########################################\n"
    end
  end

  module_function :init, :themize, :unthemize,
                       :_mapize, :_expand_tilda, :_contract_tilda, :_extract_block, :_debug
  private_class_method :_mapize, :_expand_tilda, :_contract_tilda, :_extract_block, :_debug
end
