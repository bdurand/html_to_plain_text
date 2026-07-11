# frozen_string_literal: true

require "spec_helper"

RSpec.describe HtmlToPlainText do
  def text(html)
    HtmlToPlainText.plain_text(html)
  end

  it "formats paragraph tags" do
    html = "<h1>Test</h1><h2>More Test</h2>\t \t<p>\n\tThis is a test\n</p>"
    expect(text(html)).to eq "Test\n\nMore Test\n\nThis is a test"
  end

  it "formats block tags" do
    html = "<div>Test</div><div>More Test<div>\t This is a test\t </div></div>"
    expect(text(html)).to eq "Test\nMore Test\nThis is a test"
  end

  it "formats <br> tags" do
    html = "<div>Test</div><br><div>More Test \t <br />This is a test"
    expect(text(html)).to eq "Test\n\nMore Test\nThis is a test"
  end

  it "formats <hr> tags" do
    html = "<div>Test</div><hr><div>More Test \t <hr />This is a test"
    expect(text(html)).to eq "Test\n-------------------------------\nMore Test\n-------------------------------\nThis is a test"
  end

  it "keeps text formatting in <pre> tag blocks" do
    html = "<div>This \n is a \ntest</div><pre>with\n  pre tags</pre>end"
    expect(text(html)).to eq "This is a test\nwith\n  pre tags\nend"
  end

  it "does not remove trailing blanks inside <pre> tag blocks" do
    html = "<pre>foo  \nbar</pre><br>after"
    expect(text(html)).to eq "foo  \nbar\n\nafter"
  end

  it "does not remove trailing blanks before a <br> tag inside <pre> tag blocks" do
    html = "<pre>foo  <br>bar</pre>"
    expect(text(html)).to eq "foo  \nbar"
  end

  it "does not remove trailing blanks from the last line of a <pre> tag block" do
    html = "<pre>foo  </pre><div>bar</div>"
    expect(text(html)).to eq "foo  \nbar"
  end

  it "removes inline formatting tags" do
    html = "This is <strong>so</strong> cool. I<em> mean <em>it."
    expect(text(html)).to eq "This is so cool. I mean it."
  end

  it "removes script, noscript, style, object, applet, and iframe tags" do
    html = "script <script>do_something</script> noscript <noscript>enable js</noscript> style <style>css</style> object <object>config</object> applet <applet>config</applet> iframe <iframe>config</iframe>"
    expect(text(html)).to eq "script noscript style object applet iframe"
  end

  it "collapses tabs and other whitespace to a single space" do
    html = "<p>this\tis\t\ta\ttest</p>"
    expect(text(html)).to eq "this is a test"
  end

  it "handles plaintext tags" do
    html = "<div>my\nhtml</div><plaintext>my\n text"
    expect(text(html)).to eq "my html\nmy\n text"
  end

  it "does not add extraneous spaces or line breaks" do
    html = "this<p><p>  is   \n    \n pretty bad lo<em>oking htm</em>l!"
    expect(text(html)).to eq "this\n\nis pretty bad looking html!"
  end

  it "formats bullet lists" do
    html = "List<ul><li>one</li><li>two<ul><li>a</li><li>b</li></ul></li><li>three</li></ul>"
    expect(text(html)).to eq "List\n\n* one\n* two\n\n** a\n** b\n\n* three"
  end

  it "formats numbered lists" do
    html = "List<ol><li>one</li><li>two<ol><li>a</li><li>b</li></ol></li><li>three</li></ol>"
    expect(text(html)).to eq "List\n\n1. one\n2. two\n\na. a\nb. b\n\n3. three"
  end

  describe "tables" do
    it "formats a simgple table" do
      html = "Table<table border='1'><tr><th>Col 1</th><th>Col 2</th></tr><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></table>"
      expect(text(html)).to eq "Table\n\n| Col 1 | Col 2 |\n| 1 | 2 |\n| 3 | 4 |"
    end

    it "does not add bars to a layout table" do
      html = "Table<table border='0'><tr><th>Col 1</th><th>Col 2</th></tr><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></table>"
      expect(text(html)).to eq "Table\n\nCol 1 Col 2\n1 2\n3 4"
    end

    it "formats a table with an explicit tbody" do
      html = "<table border='1'><tbody><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></tbody></table>"
      expect(text(html)).to eq "| 1 | 2 |\n| 3 | 4 |"
    end

    it "formats a table with a thead and tbody" do
      html = "<table border='1'><thead><tr><th>Col 1</th><th>Col 2</th></tr></thead><tbody><tr><td>1</td><td>2</td></tr></tbody></table>"
      expect(text(html)).to eq "| Col 1 | Col 2 |\n| 1 | 2 |"
    end
  end

  it "ignores inline tags without bodies" do
    html = "This is an <img src=\"/image\"> image"
    expect(text(html)).to eq "This is an image"
  end

  it "ignores comments" do
    html = "This is <!-- html comment here --> html"
    expect(text(html)).to eq "This is html"
  end

  it "unencodes entities" do
    html = "High &amp; Low"
    expect(text(html)).to eq "High & Low"
  end

  it "normalizes the line breaks" do
    html = "<pre>These are\rreturn\r\nlines</pre>"
    expect(text(html)).to eq "These are\nreturn\nlines"
  end

  describe "a" do
    it "discards missing href" do
      expect(text("<a name='links'>Links</a>")).to eq "Links"
    end

    it "discards paths" do
      expect(text("<a href='/test'>Links</a>")).to eq "Links"
    end

    it "includes absolute link URLs" do
      html = "<a href='http://example.com/test'>full</a>"
      expect(text(html)).to eq "full (http://example.com/test)"
    end

    it "only uses the name for exact duplicates" do
      html = "<a href='http://example.com'>http://example.com</a>"
      expect(text(html)).to eq "http://example.com"
    end

    it "only uses the name for close duplicates" do
      html = "<a href='http://example.com'>example.com</a>"
      expect(text(html)).to eq "example.com"
    end

    it "only uses the name for mailto" do
      html = "<a href='mailto:john@example.com'>john@example.com</a>"
      expect(text(html)).to eq "john@example.com"
    end

    it "includes mailto URLs when the text is different" do
      html = "<a href='mailto:john@example.com'>Contact John</a>"
      expect(text(html)).to eq "Contact John (mailto:john@example.com)"
    end

    it "includes tel URLs when the text is different" do
      html = "<a href='tel:+15555551234'>Call us</a>"
      expect(text(html)).to eq "Call us (tel:+15555551234)"
    end

    it "only uses the name for tel duplicates" do
      html = "<a href='tel:+15555551234'>+15555551234</a>"
      expect(text(html)).to eq "+15555551234"
    end

    it "discards javascript and other non-link protocols" do
      expect(text("<a href='javascript:alert(1)'>click</a>")).to eq "click"
      expect(text("<a href=\"javascript:x\nhttp://y\">click</a>")).to eq "click"
    end

    it "ignores empty" do
      expect(text("<a href='http://example.com/test2'> <img src='test'> </a>")).to eq ""
    end

    it "omits link URLs when the show_links option is false" do
      html = "<a href='http://example.com/test'>full</a>"
      expect(HtmlToPlainText.plain_text(html, show_links: false)).to eq "full"
    end

    it "includes link URLs when the show_links option is true" do
      html = "<a href='http://example.com/test'>full</a>"
      expect(HtmlToPlainText.plain_text(html, show_links: true)).to eq "full (http://example.com/test)"
    end
  end

  it "unescapes entities" do
    html = "This &amp; th&#97;t"
    expect(text(html)).to eq "This & that"
  end

  it "handles nil" do
    expect(text(nil)).to eq nil
  end

  it "handles empty text" do
    expect(text("")).to eq ""
  end

  it "handles non-html text" do
    expect(text("test")).to eq "test"
  end

  it "normalizes line breaks in non-html text" do
    expect(text("line1\r\nline2\rline3")).to eq "line1\nline2\nline3"
  end

  it "returns an empty string when there is no body" do
    expect(text("<!-- just a comment -->")).to eq ""
  end

  it "handles UTF-8 characters" do
    html = "<p>ümlaut</p>"
    expect(text(html)).to eq "ümlaut"
  end
end
