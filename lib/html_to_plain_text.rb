# frozen_string_literal: true

require "nokogiri"

# The main method on this module +plain_text+ will convert a string of HTML to a plain text approximation.
module HtmlToPlainText
  IGNORE_TAGS = %w[script noscript style object applet iframe template svg math canvas audio video select option optgroup datalist textarea].each_with_object({}) { |t, h|
    h[t] = true
  }.freeze
  PARAGRAPH_TAGS = %w[p h1 h2 h3 h4 h5 h6 table ol ul menu dl dd blockquote dialog figure aside section].each_with_object({}) { |t, h|
    h[t] = true
  }.freeze
  BLOCK_TAGS = %w[div address li dt center del article header footer nav pre legend tr main figcaption caption summary details form fieldset hgroup].each_with_object({}) { |t, h|
    h[t] = true
  }.freeze
  NAV_TAGS = %w[header footer nav].each_with_object({}) { |t, h|
    h[t] = true
  }.freeze
  NAV_ROLES = %w[navigation banner contentinfo].each_with_object({}) { |t, h|
    h[t] = true
  }.freeze
  MARKDOWN_INLINE_TAGS = {
    "strong" => "**",
    "b" => "**",
    "em" => "*",
    "i" => "*",
    "del" => "~~",
    "s" => "~~",
    "strike" => "~~",
    "code" => "`"
  }.freeze
  MARKDOWN_HEADING_TAGS = {
    "h1" => "# ",
    "h2" => "## ",
    "h3" => "### ",
    "h4" => "#### ",
    "h5" => "##### ",
    "h6" => "###### "
  }.freeze
  WHITESPACE = [" ", "\n", "\r"].freeze
  PLAINTEXT = "plaintext"
  PRE = "pre"
  BR = "br"
  HR = "hr"
  TD = "td"
  TH = "th"
  TR = "tr"
  OL = "ol"
  UL = "ul"
  LI = "li"
  A = "a"
  IMG = "img"
  MENU = "menu"
  BLOCKQUOTE = "blockquote"
  TABLE = "table"
  THEAD = "thead"
  TBODY = "tbody"
  NUMBERS = ["1", "a"].freeze
  LINK_URL_PATTERN = /\A(?:[a-z][a-z0-9.+-]*:\/\/[a-z0-9]|mailto:|tel:)/i
  URI_SCHEME_PATTERN = /\A[a-z][a-z0-9.+-]*:/i
  BRACKET_PATTERN = /[\[\]]/
  BACKTICK_RUN_PATTERN = /`+/
  HTML_PATTERN = /[<&]/
  BODY_TAG_XPATH = "/html/body"
  FIRST_TR_XPATH = ".//tr"
  CARRIAGE_RETURN_PATTERN = /\r\n?/
  LINE_BREAK_PATTERN = /[\n\r]/
  NON_PROTOCOL_PATTERN = /:\/?\/?(.*)/
  ALL_WHITESPACE_PATTERN = /[[:space:]]+/
  NOT_WHITESPACE_PATTERN = /[^[:space:]]/
  LEADING_WHITESPACE_PATTERN = /\A[[:space:]]*/
  TRAILING_WHITESPACE_PATTERN = /[[:space:]]*\z/
  LEADING_LINE_BREAK_PATTERN = /\A[\r\n]+/
  SPACE = " "
  TAB = "\t"
  EMPTY = ""
  NEWLINE = "\n"
  PIPE = "|"
  ESCAPED_PIPE = "\\|"
  HREF = "href"
  SRC = "src"
  ALT = "alt"
  BORDER = "border"
  ROLE = "role"
  TABLE_SEPARATOR = " | "
  MARKDOWN_HR = "---\n"
  # Hard line breaks are emitted as a marker character so that ones that would produce
  # a stray backslash (before a blank line or at the end of the output) can be removed
  # when the output is finalized. The null character cannot appear in parsed HTML text.
  MARKDOWN_BR_MARKER = "\u0000"
  MARKDOWN_BR = "#{MARKDOWN_BR_MARKER}\n"
  MARKDOWN_HARD_BREAK = "\\"
  MARKDOWN_BR_BEFORE_BLANK_PATTERN = /#{MARKDOWN_BR_MARKER}(?=\n[>[[:space:]]]*\n)/
  MARKDOWN_FENCE = "```"
  MARKDOWN_QUOTE = "> "
  MARKDOWN_EMPTY_QUOTE = ">"
  MARKDOWN_BULLET = "- "
  BACKTICK = "`"
  MARKDOWN_TABLE_SEPARATOR_CELL = " --- |"

  # Helper instance method for converting HTML into plain text. This method simply calls HtmlToPlainText.plain_text.
  #
  # @param html [String] The HTML to convert into plain text.
  # @param show_links [Boolean] Whether to include link URLs and image sources in the output.
  # @param markdown [Boolean] Whether to format the output as Markdown.
  # @param all_tables [Boolean] Whether to format all tables as data tables regardless of their markup.
  # @param ignore_nav [Boolean] Whether to suppress navigational, header, and footer elements.
  # @param selector [String, nil] A CSS selector limiting the output to matching elements.
  # @return [String] The plain text approximation of the HTML.
  # @raise [ArgumentError] If the selector is not a valid CSS selector.
  def plain_text(html, show_links: true, markdown: false, all_tables: false, ignore_nav: false, selector: nil)
    HtmlToPlainText.plain_text(html, show_links: show_links, markdown: markdown, all_tables: all_tables, ignore_nav: ignore_nav, selector: selector)
  end

  # Helper instance method for converting HTML into Markdown. This method simply calls HtmlToPlainText.markdown.
  #
  # @param html [String] The HTML to convert into Markdown.
  # @param show_links [Boolean] Whether to include link URLs and image sources in the output.
  # @param all_tables [Boolean] Whether to format all tables as data tables regardless of their markup.
  # @param ignore_nav [Boolean] Whether to suppress navigational, header, and footer elements.
  # @param selector [String, nil] A CSS selector limiting the output to matching elements.
  # @return [String] The Markdown approximation of the HTML.
  # @raise [ArgumentError] If the selector is not a valid CSS selector.
  def markdown(html, show_links: true, all_tables: false, ignore_nav: false, selector: nil)
    HtmlToPlainText.markdown(html, show_links: show_links, all_tables: all_tables, ignore_nav: ignore_nav, selector: selector)
  end

  class << self
    # Convert some HTML into a plain text approximation.
    #
    # @param html [String] The HTML to convert into plain text.
    # @param show_links [Boolean] Whether to include link URLs and image sources in the output.
    # @param markdown [Boolean] Whether to format the output as Markdown.
    # @param all_tables [Boolean] Whether to format all tables as data tables regardless of their markup.
    #   By default only tables with a non-zero border attribute or a thead or tbody element are formatted
    #   as data tables; other tables are assumed to be for layout only.
    # @param ignore_nav [Boolean] Whether to suppress navigational, header, and footer elements. When true,
    #   header, footer, and nav tags are omitted from the output along with any elements that have a
    #   role attribute of navigation, banner, or contentinfo.
    # @param selector [String, nil] A CSS selector limiting the output to matching elements. Only the
    #   contents of elements matching the selector are included in the output. Only elements within
    #   the body of the document are matched.
    # @return [String] The plain text approximation of the HTML.
    # @raise [ArgumentError] If the selector is not a valid CSS selector.
    def plain_text(html, show_links: true, markdown: false, all_tables: false, ignore_nav: false, selector: nil)
      return nil if html.nil?
      unless selector || HTML_PATTERN.match?(html)
        return html.gsub(CARRIAGE_RETURN_PATTERN, NEWLINE).strip
      end
      document = Nokogiri::HTML::Document.parse(html)
      options = {show_links: show_links, markdown: markdown, all_tables: all_tables, ignore_nav: ignore_nav}
      out = +""
      body = document.xpath(BODY_TAG_XPATH).first
      return +"" unless body
      if selector
        begin
          elements = document.css(selector)
        rescue Nokogiri::CSS::SyntaxError => e
          raise ArgumentError, "Invalid CSS selector: #{e.message}"
        end
        elements.each do |element|
          ancestors = element.ancestors
          # Only elements within the body are included, and nested matches are
          # skipped since their content is already included by a matching ancestor.
          next unless element == body || ancestors.include?(body)
          next if ancestors.any? { |ancestor| elements.include?(ancestor) }
          append_block_breaks(out)
          convert_node_to_plain_text(element, out, options)
        end
      else
        convert_node_to_plain_text(body, out, options)
      end
      # String#strip removes null characters as well as whitespace, so a hard break
      # marker at the end of the output is removed here along with any trailing newline.
      out = out.strip
      if markdown
        # Hard break markers followed by a blank line would leave a stray backslash,
        # so they are removed; the rest become hard line break backslashes.
        out.gsub!(MARKDOWN_BR_BEFORE_BLANK_PATTERN, EMPTY)
        out.gsub!(MARKDOWN_BR_MARKER, MARKDOWN_HARD_BREAK)
      end
      out.gsub(CARRIAGE_RETURN_PATTERN, NEWLINE)
    end

    # Convert some HTML into a Markdown approximation. This is the same as calling plain_text
    # with the markdown option set to true.
    #
    # @param html [String] The HTML to convert into Markdown.
    # @param show_links [Boolean] Whether to include link URLs and image sources in the output.
    # @param all_tables [Boolean] Whether to format all tables as data tables regardless of their markup.
    # @param ignore_nav [Boolean] Whether to suppress navigational, header, and footer elements.
    # @param selector [String, nil] A CSS selector limiting the output to matching elements.
    # @return [String] The Markdown approximation of the HTML.
    # @raise [ArgumentError] If the selector is not a valid CSS selector.
    def markdown(html, show_links: true, all_tables: false, ignore_nav: false, selector: nil)
      plain_text(html, show_links: show_links, markdown: true, all_tables: all_tables, ignore_nav: ignore_nav, selector: selector)
    end

    private

    # Convert an HTML node to plain text. This method is called recursively with the output and
    # formatting options for special tags.
    def convert_node_to_plain_text(parent, out, options = {})
      out = out.dup if out.frozen?
      markdown = options[:markdown] && !options[:pre]

      unless markdown && MARKDOWN_INLINE_TAGS.include?(parent.name)
        # The buffer tail here was written before this node opened, so it is only
        # preformatted content when an ancestor (not this node itself) is a pre tag.
        trim = !options[:pre] || parent.name == PRE
        if PARAGRAPH_TAGS.include?(parent.name)
          append_paragraph_breaks(out, trim: trim)
          heading = (MARKDOWN_HEADING_TAGS[parent.name] if markdown)
          out << heading if heading
        elsif BLOCK_TAGS.include?(parent.name)
          append_block_breaks(out, trim: trim)
        end
      end

      format_list_item(out, options) if parent.name == LI
      out << "| " if parent.name == TR && data_table?(parent, options)

      parent.children.each do |node|
        if node.text? || node.cdata?
          text = node.text
          unless options[:pre]
            text.gsub!(ALL_WHITESPACE_PATTERN, SPACE)
            text.lstrip! if WHITESPACE.include?(out[-1, 1])
            # Pipes in data table cells would be mistaken for column delimiters.
            text.gsub!(PIPE, ESCAPED_PIPE) if markdown && options[:table_cell]
          end
          out << text
        elsif node.name == PLAINTEXT
          out << node.text
        elsif node.element? && !IGNORE_TAGS.include?(node.name)
          next if options[:ignore_nav] && ignore_nav_element?(node)
          trim_trailing_blanks!(out) if markdown && (node.name == BLOCKQUOTE || node.name == PRE)
          pos = out.length
          convert_node_to_plain_text(node, out, child_options(node, options))

          if node.name == BR
            trim_trailing_blanks!(out) unless options[:pre]
            out << if markdown && !out.empty? && !out.end_with?(NEWLINE)
              MARKDOWN_BR
            else
              NEWLINE
            end
          elsif node.name == HR
            if markdown
              append_paragraph_breaks(out)
              out << MARKDOWN_HR
            else
              trim_trailing_blanks!(out)
              out << NEWLINE unless out.end_with?(NEWLINE)
              out << "-------------------------------\n"
            end
          elsif node.name == TD || node.name == TH
            out << (data_table?(parent, options) ? TABLE_SEPARATOR : SPACE)
          elsif node.name == A && options[:show_links]
            format_link(out, pos, node, options)
          elsif markdown && MARKDOWN_INLINE_TAGS.include?(node.name)
            wrap_markdown_inline(out, pos, MARKDOWN_INLINE_TAGS[node.name])
          elsif markdown && node.name == IMG
            append_markdown_image(out, node) if options[:show_links]
          elsif markdown && node.name == BLOCKQUOTE
            format_markdown_blockquote(out, pos)
          elsif markdown && node.name == PRE
            format_markdown_code_block(out, pos)
          elsif markdown && node.name == TR && data_table?(node, options)
            flatten_markdown_table_row(out, pos)
            append_block_breaks(out)
            append_markdown_table_separator(out, node)
          elsif PARAGRAPH_TAGS.include?(node.name)
            append_paragraph_breaks(out, trim: !options[:pre])
          elsif BLOCK_TAGS.include?(node.name)
            # A closing pre tag leaves preformatted content at the buffer tail.
            append_block_breaks(out, trim: !options[:pre] && node.name != PRE)
          end
        end
      end
      out
    end

    # Determine if an element is a navigational element suppressed by the ignore_nav option.
    # The role attribute can contain a space delimited list of roles.
    def ignore_nav_element?(node)
      return true if NAV_TAGS.include?(node.name)
      role = node[ROLE]
      return false unless role
      role.downcase.split(ALL_WHITESPACE_PATTERN).any? { |value| NAV_ROLES.include?(value) }
    end

    # Set formatting options that will be passed to child elements for a tag.
    def child_options(node, options)
      if node.name == UL || node.name == MENU
        level = (options[:ul] || -1) + 1
        options.merge(list: :ul, ul: level, indent: options[:child_indent].to_s)
      elsif node.name == OL
        level = (options[:ol] || -1) + 1
        number = options[:markdown] ? NUMBERS[0] : NUMBERS[level % 2]
        options.merge(list: :ol, ol: level, number: number, indent: options[:child_indent].to_s)
      elsif node.name == PRE
        options.merge(pre: true)
      elsif options[:markdown] && (node.name == TD || node.name == TH) && data_table?(node, options)
        options.merge(table_cell: true)
      else
        options
      end
    end

    # Append the URL for a link to the output. In markdown mode the link content is rewritten
    # using markdown link syntax instead.
    def format_link(out, pos, node, options)
      href = node[HREF]
      return unless href && href =~ LINK_URL_PATTERN
      # A multiline href could smuggle a non-link protocol URL past the pattern check.
      return if LINE_BREAK_PATTERN.match?(href)

      if options[:markdown] && !options[:pre]
        content = out.slice!(pos..).to_s
        stripped = content.strip
        if stripped.empty? || stripped == href || stripped == href[NON_PROTOCOL_PATTERN, 1]
          out << content
        else
          out << content[LEADING_WHITESPACE_PATTERN] << "[" << escape_unbalanced_brackets(stripped) << "](" << href << ")" << content[TRAILING_WHITESPACE_PATTERN]
        end
      else
        text = node.text
        text.gsub!(ALL_WHITESPACE_PATTERN, SPACE)
        text.strip!
        if text.size > 0 &&
            text != href &&
            text != href[NON_PROTOCOL_PATTERN, 1] # use only text for <a href="mailto:a@b.com">a@b.com</a>
          out << " (#{href}) "
        end
      end
    end

    # Wrap the output generated by an inline formatting element in markdown markers,
    # keeping any surrounding whitespace outside of the markers.
    def wrap_markdown_inline(out, pos, marker)
      content = out.slice!(pos..).to_s
      stripped = content.strip
      if stripped.empty?
        out << content
      else
        if marker == BACKTICK && stripped.include?(BACKTICK)
          # A code span containing backticks needs a longer delimiter, padded with
          # spaces if the content starts or ends with a backtick.
          longest_run = stripped.scan(BACKTICK_RUN_PATTERN).max_by(&:length).length
          marker = BACKTICK * (longest_run + 1)
          stripped = "#{SPACE}#{stripped}#{SPACE}" if stripped.start_with?(BACKTICK) || stripped.end_with?(BACKTICK)
        end
        out << content[LEADING_WHITESPACE_PATTERN] << marker << stripped << marker << content[TRAILING_WHITESPACE_PATTERN]
      end
    end

    # Append a markdown image for an img tag. Sources with a URI scheme are limited
    # to the same protocols allowed for links.
    def append_markdown_image(out, node)
      src = node[SRC].to_s
      return if src.empty? || LINE_BREAK_PATTERN.match?(src)
      return if URI_SCHEME_PATTERN.match?(src) && !LINK_URL_PATTERN.match?(src)
      alt = node[ALT].to_s.gsub(ALL_WHITESPACE_PATTERN, SPACE).strip
      out << "![" << escape_unbalanced_brackets(alt) << "](" << src << ")"
    end

    # Escape square brackets that are not part of a balanced pair so that the text
    # is safe to use inside a markdown link or image label. Balanced pairs are left
    # alone since they are valid inside a label.
    def escape_unbalanced_brackets(text)
      return text unless BRACKET_PATTERN.match?(text)
      unmatched = []
      open_brackets = []
      text.each_char.with_index do |char, i|
        if char == "["
          open_brackets << i
        elsif char == "]"
          open_brackets.empty? ? unmatched << i : open_brackets.pop
        end
      end
      unmatched.concat(open_brackets)
      return text if unmatched.empty?
      escaped = text.dup
      unmatched.sort.reverse_each { |i| escaped.insert(i, "\\") }
      escaped
    end

    # Rewrite the output generated by a blockquote element with each line prefixed by "> ".
    def format_markdown_blockquote(out, pos)
      content = out.slice!(pos..).to_s
      stripped = content.strip
      if stripped.empty?
        out << content
      else
        append_paragraph_breaks(out)
        out << stripped.split(NEWLINE, -1).map { |line| line.empty? ? MARKDOWN_EMPTY_QUOTE : "#{MARKDOWN_QUOTE}#{line}" }.join(NEWLINE)
        append_paragraph_breaks(out)
      end
    end

    # Rewrite the output generated by a pre element as a fenced code block.
    def format_markdown_code_block(out, pos)
      content = out.slice!(pos..).to_s
      stripped = content.sub(LEADING_LINE_BREAK_PATTERN, EMPTY).sub(TRAILING_WHITESPACE_PATTERN, EMPTY)
      if stripped.empty?
        out << content
      else
        # A hard line break immediately before a code block would leave a stray backslash.
        out.slice!(-2, 1) if out.end_with?(MARKDOWN_BR)
        append_block_breaks(out)
        fence = markdown_code_fence(stripped)
        out << fence << NEWLINE << stripped << NEWLINE << fence << NEWLINE
      end
    end

    # Determine the fence needed to enclose code block content. The fence must be longer
    # than any run of backticks in the content so the content cannot close the fence early.
    def markdown_code_fence(content)
      return MARKDOWN_FENCE unless content.include?(MARKDOWN_FENCE)
      longest_run = content.scan(BACKTICK_RUN_PATTERN).max_by(&:length).length
      BACKTICK * (longest_run + 1)
    end

    # Rewrite the output generated by a data table row in markdown so that it stays on a
    # single line. Line breaks from br tags or block elements inside the cells would
    # otherwise break the table syntax.
    def flatten_markdown_table_row(out, pos)
      row = out.slice!(pos..).to_s
      row.gsub!(MARKDOWN_BR_MARKER, EMPTY)
      row.gsub!(ALL_WHITESPACE_PATTERN, SPACE)
      row.strip!
      append_block_breaks(out)
      out << row
    end

    # Append the markdown header separator row after the first row of a data table.
    def append_markdown_table_separator(out, tr)
      return unless first_table_row?(tr)
      cells = tr.elements.count { |cell| cell.name == TD || cell.name == TH }
      return if cells == 0
      out << "|"
      cells.times { out << MARKDOWN_TABLE_SEPARATOR_CELL }
      out << NEWLINE
    end

    # Add double line breaks between paragraph elements. If line breaks already exist,
    # new ones will only be added to get to two.
    def append_paragraph_breaks(out, trim: true)
      trim_trailing_blanks!(out) if trim
      if out.end_with?(NEWLINE)
        out << NEWLINE unless out.end_with?("\n\n")
      else
        out << "\n\n"
      end
    end

    # Add a single line break between block elements. If a line break already exists,
    # none will be added.
    def append_block_breaks(out, trim: true)
      trim_trailing_blanks!(out) if trim
      out << NEWLINE unless out.end_with?(NEWLINE)
    end

    # Remove spaces and tabs from the end of the output buffer.
    def trim_trailing_blanks!(out)
      out.slice!(-1) while out.end_with?(SPACE, TAB)
    end

    # Add an appropriate bullet or number to a list element.
    def format_list_item(out, options)
      if options[:markdown]
        indent = options[:indent].to_s
        if options[:list] == :ul
          out << indent << MARKDOWN_BULLET
          options[:child_indent] = "#{indent}  "
        elsif options[:list] == :ol
          number = options[:number]
          options[:number] = number.next
          marker = "#{number}. "
          out << indent << marker
          options[:child_indent] = indent + (SPACE * marker.length)
        end
      elsif options[:list] == :ul
        out << "#{"*" * (options[:ul] + 1)} "
      elsif options[:list] == :ol
        number = options[:number]
        options[:number] = number.next
        out << "#{number}. "
      end
    end

    # Determine if a table is a data table rather than one used only for layout. A table
    # is considered a data table if it has a non-zero border attribute or contains a
    # thead or tbody element, or if the all_tables option is set.
    def data_table?(tr, options)
      return true if options[:all_tables]
      table = containing_table(tr)
      return false unless table
      return true if table.attributes[BORDER].to_s.to_i > 0
      table.elements.any? { |child| child.name == THEAD || child.name == TBODY }
    end

    # Determine if a tr is the first row in its table.
    def first_table_row?(tr)
      table = containing_table(tr)
      return false unless table
      table.at_xpath(FIRST_TR_XPATH) == tr
    end

    # Find the table element containing a table row.
    def containing_table(tr)
      table = tr.parent
      table = table.parent while table && table.name != TABLE
      table
    end
  end
end
