# HTML To Plain Text

[![Continuous Integration](https://github.com/bdurand/html_to_plain_text/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/html_to_plain_text/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)
[![Gem Version](https://badge.fury.io/rb/html_to_plain_text.svg)](https://badge.fury.io/rb/html_to_plain_text)

A simple gem that provide code to convert HTML into a plain text alternative. Line breaks from HTML block level elements will be maintained. Lists and tables will also maintain a little bit of formatting.

* Line breaks will be approximated using the generally established default margins for HTML tags (i.e. <p> tag generates two line breaks, <div> generates one)
* Lists items will be numbered or bulleted with an asterisk
* <br> tags will add line breaks
* <hr> tags will add a string of hyphens to serve as a horizontal rule
* <table> elements will enclosed in "|" delimiters
* <a> tags will have the href URL appended to the text in parentheses
* Formatting tags like <strong> or <b> will be stripped
* Formatting inside <pre> or <plaintext> elements will be honored
* Code-like tags like <script> or <style> will be stripped

## Usage

```ruby
require 'html_to_plain_text'

html = "<h1>Hello</h1><p>world!</p>"
HtmlToPlainText.plain_text(html) # => "Hello\n\nworld!"
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "html_to_plain_text"
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install html_to_plain_text
```

## Contributing

Open a pull request on GitHub.

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
