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
  HREF = "href"
  SRC = "src"
  ALT = "alt"
  BORDER = "border"
  TABLE_SEPARATOR = " | "
  MARKDOWN_HR = "---\n"
  MARKDOWN_BR = "\\\n"
  MARKDOWN_FENCE = "```"
  MARKDOWN_QUOTE = "> "
  MARKDOWN_EMPTY_QUOTE = ">"
  MARKDOWN_BULLET = "- "
  MARKDOWN_TABLE_SEPARATOR_CELL = " --- |"

  # Helper instance method for converting HTML into plain text. This method simply calls HtmlToPlainText.plain_text.
  #
  # @param html [String] The HTML to convert into plain text.
  # @param show_links [Boolean] Whether to include link URLs and image sources in the output.
  # @param markdown [Boolean] Whether to format the output as Markdown.
  # @param all_tables [Boolean] Whether to format all tables as data tables regardless of their markup.
  # @return [String] The plain text approximation of the HTML.
  def plain_text(html, show_links: true, markdown: false, all_tables: false)
    HtmlToPlainText.plain_text(html, show_links: show_links, markdown: markdown, all_tables: all_tables)
  end

  # Helper instance method for converting HTML into Markdown. This method simply calls HtmlToPlainText.markdown.
  #
  # @param html [String] The HTML to convert into Markdown.
  # @param show_links [Boolean] Whether to include link URLs and image sources in the output.
  # @param all_tables [Boolean] Whether to format all tables as data tables regardless of their markup.
  # @return [String] The Markdown approximation of the HTML.
  def markdown(html, show_links: true, all_tables: false)
    HtmlToPlainText.markdown(html, show_links: show_links, all_tables: all_tables)
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
    # @return [String] The plain text approximation of the HTML.
    def plain_text(html, show_links: true, markdown: false, all_tables: false)
      return nil if html.nil?
      return html.gsub(CARRIAGE_RETURN_PATTERN, NEWLINE).strip unless HTML_PATTERN.match?(html)
      body = Nokogiri::HTML::Document.parse(html).xpath(BODY_TAG_XPATH).first
      return +"" unless body
      options = {show_links: show_links, markdown: markdown, all_tables: all_tables}
      convert_node_to_plain_text(body, "", options).strip.gsub(CARRIAGE_RETURN_PATTERN, NEWLINE)
    end

    # Convert some HTML into a Markdown approximation. This is the same as calling plain_text
    # with the markdown option set to true.
    #
    # @param html [String] The HTML to convert into Markdown.
    # @param show_links [Boolean] Whether to include link URLs and image sources in the output.
    # @param all_tables [Boolean] Whether to format all tables as data tables regardless of their markup.
    # @return [String] The Markdown approximation of the HTML.
    def markdown(html, show_links: true, all_tables: false)
      plain_text(html, show_links: show_links, markdown: true, all_tables: all_tables)
    end

    private

    # Convert an HTML node to plain text. This method is called recursively with the output and
    # formatting options for special tags.
    def convert_node_to_plain_text(parent, out, options = {})
      out = out.dup if out.frozen?
      markdown = options[:markdown] && !options[:pre]

      unless markdown && MARKDOWN_INLINE_TAGS.include?(parent.name)
        if PARAGRAPH_TAGS.include?(parent.name)
          append_paragraph_breaks(out)
          heading = (MARKDOWN_HEADING_TAGS[parent.name] if markdown)
          out << heading if heading
        elsif BLOCK_TAGS.include?(parent.name)
          append_block_breaks(out)
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
          end
          out << text
        elsif node.name == PLAINTEXT
          out << node.text
        elsif node.element? && !IGNORE_TAGS.include?(node.name)
          trim_trailing_blanks!(out) if markdown && (node.name == BLOCKQUOTE || node.name == PRE)
          pos = out.length
          convert_node_to_plain_text(node, out, child_options(node, options))

          if node.name == BR
            trim_trailing_blanks!(out)
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
            append_block_breaks(out)
            append_markdown_table_separator(out, node)
          elsif PARAGRAPH_TAGS.include?(node.name)
            append_paragraph_breaks(out)
          elsif BLOCK_TAGS.include?(node.name)
            append_block_breaks(out)
          end
        end
      end
      out
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
      else
        options
      end
    end

    # Append the URL for a link to the output. In markdown mode the link content is rewritten
    # using markdown link syntax instead.
    def format_link(out, pos, node, options)
      href = node[HREF]
      return unless href && href =~ LINK_URL_PATTERN

      if options[:markdown] && !options[:pre]
        content = out.slice!(pos..).to_s
        stripped = content.strip
        if stripped.empty? || stripped == href || stripped == href[NON_PROTOCOL_PATTERN, 1]
          out << content
        else
          out << content[LEADING_WHITESPACE_PATTERN] << "[" << stripped << "](" << href << ")" << content[TRAILING_WHITESPACE_PATTERN]
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
        out << content[LEADING_WHITESPACE_PATTERN] << marker << stripped << marker << content[TRAILING_WHITESPACE_PATTERN]
      end
    end

    # Append a markdown image for an img tag.
    def append_markdown_image(out, node)
      src = node[SRC].to_s
      return if src.empty? || LINE_BREAK_PATTERN.match?(src)
      alt = node[ALT].to_s.gsub(ALL_WHITESPACE_PATTERN, SPACE).strip
      out << "![" << alt << "](" << src << ")"
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
        append_block_breaks(out)
        out << MARKDOWN_FENCE << NEWLINE << stripped << NEWLINE << MARKDOWN_FENCE << NEWLINE
      end
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
    def append_paragraph_breaks(out)
      trim_trailing_blanks!(out)
      if out.end_with?(NEWLINE)
        out << NEWLINE unless out.end_with?("\n\n")
      else
        out << "\n\n"
      end
    end

    # Add a single line break between block elements. If a line break already exists,
    # none will be added.
    def append_block_breaks(out)
      trim_trailing_blanks!(out)
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
