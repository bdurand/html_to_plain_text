# frozen_string_literal: true

require "spec_helper"

RSpec.describe HtmlToPlainText do
  def text(html)
    HtmlToPlainText.plain_text(html)
  end

  def markdown(html, **options)
    HtmlToPlainText.markdown(html, **options)
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

  it "removes inline formatting tags" do
    html = "This is <strong>so</strong> cool. I<em> mean <em>it."
    expect(text(html)).to eq "This is so cool. I mean it."
  end

  it "removes script, noscript, style, object, applet, and iframe tags" do
    html = "script <script>do_something</script> noscript <noscript>enable js</noscript> style <style>css</style> object <object>config</object> applet <applet>config</applet> iframe <iframe>config</iframe>"
    expect(text(html)).to eq "script noscript style object applet iframe"
  end

  it "removes template, svg, math, canvas, audio, and video tags" do
    html = "template <template><div>hidden</div></template>svg <svg><text>hidden</text></svg>math <math><mi>hidden</mi></math>canvas <canvas>hidden</canvas>audio <audio>hidden</audio>video <video>hidden</video>done"
    expect(text(html)).to eq "template svg math canvas audio video done"
  end

  it "removes form input tags" do
    html = "select <select><option>hidden</option></select>textarea <textarea>hidden</textarea>done"
    expect(text(html)).to eq "select textarea done"
  end

  it "formats semantic layout tags as blocks" do
    html = "<main>main</main><figcaption>figcaption</figcaption><summary>summary</summary><details>details</details><form>form</form><fieldset>fieldset</fieldset><hgroup>hgroup</hgroup>"
    expect(text(html)).to eq "main\nfigcaption\nsummary\ndetails\nform\nfieldset\nhgroup"
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

  it "formats menu tags as bullet lists" do
    html = "List<menu><li>one</li><li>two</li></menu>"
    expect(text(html)).to eq "List\n\n* one\n* two"
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

    it "detects a data table by the presence of a thead or tbody element" do
      html = "<table><thead><tr><th>Col 1</th></tr></thead><tbody><tr><td>1</td></tr></tbody></table>"
      expect(text(html)).to eq "| Col 1 |\n| 1 |"
    end

    it "does not add bars to a table without a border, thead, or tbody" do
      html = "<table><tr><td>1</td><td>2</td></tr></table>"
      expect(text(html)).to eq "1 2"
    end

    it "formats all tables as data tables with the all_tables option" do
      html = "<table><tr><td>1</td><td>2</td></tr></table>"
      expect(HtmlToPlainText.plain_text(html, all_tables: true)).to eq "| 1 | 2 |"
    end
  end

  describe "ignore_nav" do
    it "keeps header, footer, and nav tags by default" do
      html = "<header>head</header><nav>menu</nav><p>content</p><footer>foot</footer>"
      expect(text(html)).to eq "head\nmenu\n\ncontent\n\nfoot"
    end

    it "suppresses header, footer, and nav tags with the ignore_nav option" do
      html = "<header>head</header><nav>menu</nav><p>content</p><footer>foot</footer>"
      expect(HtmlToPlainText.plain_text(html, ignore_nav: true)).to eq "content"
    end

    it "keeps aside tags with the ignore_nav option" do
      html = "<p>content</p><aside>related</aside>"
      expect(HtmlToPlainText.plain_text(html, ignore_nav: true)).to eq "content\n\nrelated"
    end

    it "suppresses elements with navigation, banner, and contentinfo roles" do
      html = "<div role='banner'>head</div><div role='navigation'>menu</div><p>content</p><div role='contentinfo'>foot</div>"
      expect(HtmlToPlainText.plain_text(html, ignore_nav: true)).to eq "content"
    end

    it "suppresses elements with a navigational role in a list of roles" do
      html = "<div role='menu navigation'>menu</div><p>content</p>"
      expect(HtmlToPlainText.plain_text(html, ignore_nav: true)).to eq "content"
    end

    it "keeps elements with other roles" do
      html = "<div role='main'>content</div><div role='complementary'>related</div>"
      expect(HtmlToPlainText.plain_text(html, ignore_nav: true)).to eq "content\nrelated"
    end

    it "suppresses navigational elements in markdown mode" do
      html = "<nav>menu</nav><h1>Title</h1><footer>foot</footer>"
      expect(markdown(html, ignore_nav: true)).to eq "# Title"
    end
  end

  describe "selector" do
    it "only includes elements matching a CSS selector" do
      html = "<div>before</div><content>the content</content><div>after</div>"
      expect(HtmlToPlainText.plain_text(html, selector: "content")).to eq "the content"
    end

    it "includes all matching elements separated by line breaks" do
      html = "<content>one</content><div>skip</div><content>two</content>"
      expect(HtmlToPlainText.plain_text(html, selector: "content")).to eq "one\ntwo"
    end

    it "does not duplicate the contents of nested matching elements" do
      html = "<div><p>one</p><div><p>two</p></div></div>"
      expect(HtmlToPlainText.plain_text(html, selector: "div")).to eq "one\n\ntwo"
    end

    it "returns an empty string when no elements match" do
      expect(HtmlToPlainText.plain_text("<p>content</p>", selector: "article")).to eq ""
    end

    it "returns an empty string for non-html text" do
      expect(HtmlToPlainText.plain_text("just text", selector: "p")).to eq ""
    end

    it "suppresses navigational elements inside selected elements with the ignore_nav option" do
      html = "<article><nav>menu</nav><p>content</p></article><footer>foot</footer>"
      expect(HtmlToPlainText.plain_text(html, selector: "article", ignore_nav: true)).to eq "content"
    end

    it "formats selected elements in markdown mode" do
      html = "<div>before</div><article><h1>Title</h1><p><strong>bold</strong></p></article>"
      expect(markdown(html, selector: "article")).to eq "# Title\n\n**bold**"
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

  describe "markdown" do
    it "is the same as calling plain_text with the markdown option" do
      html = "<h1>Test</h1><p><strong>bold</strong></p>"
      expect(HtmlToPlainText.plain_text(html, markdown: true)).to eq "# Test\n\n**bold**"
      expect(markdown(html)).to eq "# Test\n\n**bold**"
    end

    it "formats headings" do
      html = "<h1>One</h1><h2>Two</h2><h3>Three</h3><h4>Four</h4><h5>Five</h5><h6>Six</h6>"
      expect(markdown(html)).to eq "# One\n\n## Two\n\n### Three\n\n#### Four\n\n##### Five\n\n###### Six"
    end

    it "formats bold tags" do
      expect(markdown("This is <strong>so</strong> <b>cool</b>")).to eq "This is **so** **cool**"
    end

    it "formats italic tags" do
      expect(markdown("This is <em>so</em> <i>cool</i>")).to eq "This is *so* *cool*"
    end

    it "formats strikethrough tags" do
      expect(markdown("a <del>b</del> <s>c</s> <strike>d</strike> e")).to eq "a ~~b~~ ~~c~~ ~~d~~ e"
    end

    it "formats inline code tags" do
      expect(markdown("run <code>ls -l</code> now")).to eq "run `ls -l` now"
    end

    it "keeps whitespace outside of inline markers" do
      expect(markdown("word <b>bold </b>after")).to eq "word **bold** after"
    end

    it "does not add markers for empty inline tags" do
      expect(markdown("empty <strong>  </strong>marks")).to eq "empty marks"
    end

    it "formats links" do
      html = "<a href='http://example.com/test'>full</a>"
      expect(markdown(html)).to eq "[full](http://example.com/test)"
    end

    it "uses a bare URL when the link text duplicates the href" do
      expect(markdown("<a href='http://example.com'>http://example.com</a>")).to eq "http://example.com"
      expect(markdown("<a href='http://example.com'>example.com</a>")).to eq "example.com"
      expect(markdown("<a href='mailto:john@example.com'>john@example.com</a>")).to eq "john@example.com"
    end

    it "discards paths and non-link protocols in links" do
      expect(markdown("<a href='/test'>Links</a>")).to eq "Links"
      expect(markdown("<a href='javascript:alert(1)'>click</a>")).to eq "click"
    end

    it "omits link URLs when the show_links option is false" do
      html = "<a href='http://example.com/test'>full</a>"
      expect(markdown(html, show_links: false)).to eq "full"
    end

    it "formats images" do
      expect(markdown("pic <img src='/image' alt='pic'> here")).to eq "pic ![pic](/image) here"
      expect(markdown("pic <img src='/image'> here")).to eq "pic ![](/image) here"
    end

    it "formats linked images" do
      html = "<a href='http://example.com/'><img src='/i.png' alt='pic'></a>"
      expect(markdown(html)).to eq "[![pic](/i.png)](http://example.com/)"
    end

    it "omits images when the show_links option is false" do
      expect(markdown("pic <img src='/image' alt='pic'> here", show_links: false)).to eq "pic here"
    end

    it "formats blockquote tags" do
      html = "intro<blockquote><p>one</p><p>two</p></blockquote>outro"
      expect(markdown(html)).to eq "intro\n\n> one\n>\n> two\n\noutro"
    end

    it "formats nested blockquote tags" do
      html = "<blockquote>outer<blockquote>inner</blockquote></blockquote>"
      expect(markdown(html)).to eq "> outer\n>\n> > inner"
    end

    it "formats pre tags as fenced code blocks" do
      html = "<div>before</div><pre>a\n  b</pre>after"
      expect(markdown(html)).to eq "before\n```\na\n  b\n```\nafter"
    end

    it "formats pre tags with nested code tags as fenced code blocks" do
      html = "<pre><code>x = 1\ny = 2</code></pre>"
      expect(markdown(html)).to eq "```\nx = 1\ny = 2\n```"
    end

    it "formats <hr> tags" do
      expect(markdown("Test<hr>More")).to eq "Test\n\n---\nMore"
    end

    it "formats <br> tags as hard line breaks" do
      expect(markdown("line1<br>line2")).to eq "line1\\\nline2"
    end

    it "formats bullet lists with nesting indented" do
      html = "List<ul><li>one</li><li>two<ul><li>a</li><li>b</li></ul></li><li>three</li></ul>"
      expect(markdown(html)).to eq "List\n\n- one\n- two\n\n  - a\n  - b\n\n- three"
    end

    it "formats numbered lists with nesting indented" do
      html = "List<ol><li>one</li><li>two<ol><li>a</li><li>b</li></ol></li><li>three</li></ol>"
      expect(markdown(html)).to eq "List\n\n1. one\n2. two\n\n   1. a\n   2. b\n\n3. three"
    end

    it "formats data tables with a header separator row" do
      html = "<table><thead><tr><th>Col 1</th><th>Col 2</th></tr></thead><tbody><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></tbody></table>"
      expect(markdown(html)).to eq "| Col 1 | Col 2 |\n| --- | --- |\n| 1 | 2 |\n| 3 | 4 |"
    end

    it "does not format layout tables" do
      expect(markdown("<table><tr><td>1</td><td>2</td></tr></table>")).to eq "1 2"
    end

    it "formats all tables with the all_tables option" do
      html = "<table><tr><td>1</td><td>2</td></tr></table>"
      expect(markdown(html, all_tables: true)).to eq "| 1 | 2 |\n| --- | --- |"
    end

    it "does not apply markdown formatting inside pre tags" do
      html = "<pre>keep <strong>tags</strong> plain</pre>"
      expect(markdown(html)).to eq "```\nkeep tags plain\n```"
    end
  end

  describe "helper instance methods" do
    let(:helper) { Class.new { include HtmlToPlainText }.new }

    it "provides a plain_text instance method" do
      expect(helper.plain_text("<h1>Test</h1>")).to eq "Test"
      expect(helper.plain_text("<h1>Test</h1>", markdown: true)).to eq "# Test"
    end

    it "provides a markdown instance method" do
      expect(helper.markdown("<h1>Test</h1>")).to eq "# Test"
    end
  end
end
