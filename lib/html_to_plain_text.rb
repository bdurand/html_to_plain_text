require 'nokogiri'

# The main method on this module +plain_text+ will convert a string of HTML to a plain text approximation.
module HtmlToPlainText
  IGNORE_TAGS = %w(script style object applet iframe).inject({}){|h, t| h[t] = true; h}.freeze
  PARAGRAPH_TAGS = %w(p h1 h2 h3 h4 h5 h6 table ol ul dl dd blockquote dialog figure aside section).inject({}){|h, t| h[t] = true; h}.freeze
  BLOCK_TAGS = %w(div address li dt center del article header header footer nav pre legend tr).inject({}){|h, t| h[t] = true; h}.freeze
  WHITESPACE = [" ", "\n", "\r"].freeze
  PLAINTEXT = "plaintext".freeze
  PRE = "pre".freeze
  BR = "br".freeze
  HR = "hr".freeze
  TD = "td".freeze
  TH = "th".freeze
  TR = "tr".freeze
  OL = "ol".freeze
  UL = "ul".freeze
  LI = "li".freeze
  NUMBERS = ["1", "a"]
  ABSOLUTE_URL_PATTERN = /^[a-z]+:\/\/[a-z0-9]/i
  
  # Helper instance method for converting HTML into plain text. This method simply calls HtmlToPlainText.plain_text.
  def plain_text(html)
    HtmlToPlainText.plain_text(html)
  end
  
  class << self
    # Convert some HTML into a plain text approximation.
    def plain_text(html)
      return if html.nil? || html.empty?
      body = Nokogiri::HTML::Document.parse(html).css("body").first
      return unless body
      convert_node_to_plain_text(body).strip.gsub(/\r(\n?)/, "\n")
    end
    
    private
    
    # Convert an HTML node to plain text. This method is called recursively with the output and
    # formatting options for special tags.
    def convert_node_to_plain_text(parent, out = "", options = {})
      if PARAGRAPH_TAGS.include?(parent.name)
        append_paragraph_breaks(out)
      elsif BLOCK_TAGS.include?(parent.name)
        append_block_breaks(out)
      end
      
      format_list_item(out, options) if parent.name == LI
      out << "| " if parent.name == TR
      
      parent.children.each do |node|
        if node.text? || node.cdata?
          text = node.text
          unless options[:pre]
            text = node.text.gsub(/[\n\r]/, " ").squeeze(" ")
            text.lstrip! if WHITESPACE.include?(out[-1, 1])
          end
          out << text
        elsif node.name == PLAINTEXT
          out << node.text
        elsif node.element? && !IGNORE_TAGS.include?(node.name)
          convert_node_to_plain_text(node, out, child_options(node, options))
          
          if node.name == BR
            out << "\n"
          elsif node.name == HR
            out << "\n" unless out.end_with?("\n")
            out << "-------------------------------\n"
          elsif node.name == TD || node.name == TH
            out << " | "
          elsif node.name == "a"
            href = node["href"]
            if href && href.match(ABSOLUTE_URL_PATTERN) && node.text.match(/\S/)
              out << " (#{href}) "
            end
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
      if node.name == UL
        level = options[:ul] || -1
        level += 1
        options.merge(:list => :ul, :ul => level)
      elsif node.name == OL
        level = options[:ol] || -1
        level += 1
        options.merge(:list => :ol, :ol => level, :number => NUMBERS[level % 2])
      elsif node.name == PRE
        options.merge(:pre => true)
      else
        options
      end
    end
    
    # Add double line breaks between paragraph elements. If line breaks already exist,
    # new ones will only be added to get to two.
    def append_paragraph_breaks(out)
      out.chomp!(" ")
      if out.end_with?("\n")
        out << "\n" unless out.end_with?("\n\n")
      else
        out << "\n\n"
      end
    end
    
    # Add a single line break between block elements. If a line break already exists,
    # none will be added.
    def append_block_breaks(out)
      out.chomp!(" ")
      out << "\n" unless out.end_with?("\n")
    end
    
    # Add an appropriate bullet or number to a list element.
    def format_list_item(out, options)
      if options[:list] == :ul
        out << "#{'*' * (options[:ul] + 1)} "
      elsif options[:list] == :ol
        number = options[:number]
        options[:number] = number.next
        out << "#{number}. "
      end
    end
  end
end
