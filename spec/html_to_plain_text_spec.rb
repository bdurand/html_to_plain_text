# encoding: UTF-8
require 'spec_helper'

RSpec.describe HtmlToPlainText do
  it "formats paragraph tags" do
    html = "<h1>Test</h1><h2>More Test</h2>\t \t<p>\n\tThis is a test\n</p>"
    expect(HtmlToPlainText.plain_text(html)).to eq "Test\n\nMore Test\n\nThis is a test"
  end

  it "formats block tags" do
    html = "<div>Test</div><div>More Test<div>\t This is a test\t </div></div>"
    expect(HtmlToPlainText.plain_text(html)).to eq "Test\nMore Test\nThis is a test"
  end

  it "formats <br> tags" do
    html = "<div>Test</div><br><div>More Test \t <br />This is a test"
    expect(HtmlToPlainText.plain_text(html)).to eq "Test\n\nMore Test\nThis is a test"
  end

  it "formats <hr> tags" do
    html = "<div>Test</div><hr><div>More Test \t <hr />This is a test"
    expect(HtmlToPlainText.plain_text(html)).to eq "Test\n-------------------------------\nMore Test\n-------------------------------\nThis is a test"
  end

  it "keeps text formatting in <pre> tag blocks" do
    html = "<div>This \n is a \ntest</div><pre>with\n  pre tags</pre>end"
    expect(HtmlToPlainText.plain_text(html)).to eq "This is a test\nwith\n  pre tags\nend"
  end

  it "removes inline formatting tags" do
    html = "This is <strong>so</strong> cool. I<em> mean <em>it."
    expect(HtmlToPlainText.plain_text(html)).to eq "This is so cool. I mean it."
  end

  it "removes script, style, object, applet, and iframe tags" do
    html = "script <script>do_something</script> style <style>css</style> object <object>config</object> applet <applet>config</applet> iframe <iframe>config</iframe>"
    expect(HtmlToPlainText.plain_text(html)).to eq "script style object applet iframe"
  end

  it "handles plaintext tags" do
    html = "<div>my\nhtml</div><plaintext>my\n text"
    expect(HtmlToPlainText.plain_text(html)).to eq "my html\nmy\n text"
  end

  it "does not add extraneous spaces or line breaks" do
    html = "this<p><p>  is   \n    \n pretty bad lo<em>oking htm</em>l!"
    expect(HtmlToPlainText.plain_text(html)).to eq "this\n\nis pretty bad looking html!"
  end

  it "formats bullet lists" do
    html = "List<ul><li>one</li><li>two<ul><li>a</li><li>b</li></ul></li><li>three</li></ul>"
    expect(HtmlToPlainText.plain_text(html)).to eq "List\n\n* one\n* two\n\n** a\n** b\n\n* three"
  end

  it "formats numbered lists" do
    html = "List<ol><li>one</li><li>two<ol><li>a</li><li>b</li></ol></li><li>three</li></ol>"
    expect(HtmlToPlainText.plain_text(html)).to eq "List\n\n1. one\n2. two\n\na. a\nb. b\n\n3. three"
  end

  it "formats a table" do
    html = "Table<table><tr><th>Col 1</th><th>Col 2</th></tr><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></table>"
    expect(HtmlToPlainText.plain_text(html)).to eq "Table\n\n| Col 1 | Col 2 |\n| 1 | 2 |\n| 3 | 4 |"
  end

  it "ignores inline tags without bodies" do
    html = "This is an <img src=\"/image\"> image"
    expect(HtmlToPlainText.plain_text(html)).to eq "This is an image"
  end

  it "ignores comments" do
    html = "This is <!-- html comment here --> html"
    expect(HtmlToPlainText.plain_text(html)).to eq "This is html"
  end

  it "unencodes entities" do
    html = "High &amp; Low"
    expect(HtmlToPlainText.plain_text(html)).to eq "High & Low"
  end

  it "normalizes the line breaks" do
    html = "<pre>These are\rreturn\r\nlines</pre>"
    expect(HtmlToPlainText.plain_text(html)).to eq "These are\nreturn\nlines"
  end

  it "includes absolute link URLs" do
    html = "<a name='links'>Links</a> <a href='/test'>partial</a> <a href='http://example.com/test'>full</a> test<a href='http://example.com/test2'> <img src='test'> </a>"
    expect(HtmlToPlainText.plain_text(html)).to eq "Links partial full (http://example.com/test) test"
  end

  it "unescapes entities" do
    html = "This &amp; th&#97;t"
    expect(HtmlToPlainText.plain_text(html)).to eq "This & that"
  end

  it "handles nil" do
    expect(HtmlToPlainText.plain_text(nil)).to eq nil
  end

  it "handles empty text" do
    expect(HtmlToPlainText.plain_text((""))).to eq ""
  end

  it "handles non-html text" do
    expect(HtmlToPlainText.plain_text(("test"))).to eq "test"
  end

  it "handles UTF-8 characters" do
    html = "<p>ümlaut</p>"
    expect(HtmlToPlainText.plain_text(html)).to eq "ümlaut"
  end
end
