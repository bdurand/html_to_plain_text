# encoding: UTF-8

require 'spec_helper'

describe HtmlToPlainText do
  it "should format paragraph tags" do
    html = "<h1>Test</h1><h2>More Test</h2>\t \t<p>\n\tThis is a test\n</p>"
    HtmlToPlainText.plain_text(html).should == "Test\n\nMore Test\n\nThis is a test"
  end
  
  it "should format block tags" do
    html = "<div>Test</div><div>More Test<div>\t This is a test\t </div></div>"
    HtmlToPlainText.plain_text(html).should == "Test\nMore Test\nThis is a test"
  end
  
  it "should format <br> tags" do
    html = "<div>Test</div><br><div>More Test \t <br />This is a test"
    HtmlToPlainText.plain_text(html).should == "Test\n\nMore Test\nThis is a test"
  end
  
  it "should format <hr> tags" do
    html = "<div>Test</div><hr><div>More Test \t <hr />This is a test"
    HtmlToPlainText.plain_text(html).should == "Test\n-------------------------------\nMore Test\n-------------------------------\nThis is a test"
  end
  
  it "should keep text formatting in <pre> tag blocks" do
    html = "<div>This \n is a \ntest</div><pre>with\n  pre tags</pre>end"
    HtmlToPlainText.plain_text(html).should == "This is a test\nwith\n  pre tags\nend"
  end
  
  it "should remove inline formatting tags" do
    html = "This is <strong>so</strong> cool. I<em> mean <em>it."
    HtmlToPlainText.plain_text(html).should == "This is so cool. I mean it."
  end
  
  it "should remove script, style, object, applet, and iframe tags" do
    html = "script <script>do_something</script> style <style>css</style> object <object>config</object> applet <applet>config</applet> iframe <iframe>config</iframe>"
    HtmlToPlainText.plain_text(html).should == "script style object applet iframe"
  end
  
  it "should handle plaintext tags" do
    html = "<div>my\nhtml</div><plaintext>my\n text"
    HtmlToPlainText.plain_text(html).should == "my html\nmy\n text"
  end
  
  it "should not add extraneous spaces or line breaks" do
    html = "this<p><p>  is   \n    \n pretty bad lo<em>oking htm</em>l!"
    HtmlToPlainText.plain_text(html).should == "this\n\nis pretty bad looking html!"
  end
  
  it "should format bullet lists" do
    html = "List<ul><li>one</li><li>two<ul><li>a</li><li>b</li></ul></li><li>three</li></ul>"
    HtmlToPlainText.plain_text(html).should == "List\n\n* one\n* two\n\n** a\n** b\n\n* three"
  end
  
  it "should format numbered lists" do
    html = "List<ol><li>one</li><li>two<ol><li>a</li><li>b</li></ol></li><li>three</li></ol>"
    HtmlToPlainText.plain_text(html).should == "List\n\n1. one\n2. two\n\na. a\nb. b\n\n3. three"
  end
  
  it "should format a table" do
    html = "Table<table><tr><th>Col 1</th><th>Col 2</th></tr><tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr></table>"
    HtmlToPlainText.plain_text(html).should == "Table\n\n| Col 1 | Col 2 |\n| 1 | 2 |\n| 3 | 4 |"
  end
  
  it "should ignore inline tags without bodies" do
    html = "This is an <img src=\"/image\"> image"
    HtmlToPlainText.plain_text(html).should == "This is an image"
  end
  
  it "should ignore comments" do
    html = "This is <!-- html comment here --> html"
    HtmlToPlainText.plain_text(html).should == "This is html"
  end
  
  it "should unencode entities" do
    html = "High &amp; Low"
    HtmlToPlainText.plain_text(html).should == "High & Low"
  end
  
  it "should normalize the line breaks" do
    html = "<pre>These are\rreturn\r\nlines</pre>"
    HtmlToPlainText.plain_text(html).should == "These are\nreturn\nlines"
  end
  
  it "should include absolute link URLs" do
    html = "<a name='links'>Links</a> <a href='/test'>partial</a> <a href='http://example.com/test'>full</a> test<a href='http://example.com/test2'> <img src='test'> </a>"
    HtmlToPlainText.plain_text(html).should == "Links partial full (http://example.com/test) test"
  end
  
  it "should unescape entities" do
    html = "This &amp; th&#97;t"
    HtmlToPlainText.plain_text(html).should == "This & that"
  end
  
  it "should handle nil" do
    HtmlToPlainText.plain_text(nil).should == nil
  end
  
  it "should handle empty text" do
    HtmlToPlainText.plain_text("").should == ""
  end
  
  it "should handle non-html text" do
    HtmlToPlainText.plain_text("test").should == "test"
  end
  
  it "should handle UTF-8 characters" do
    html = "<p>ümlaut</p>"
    HtmlToPlainText.plain_text(html).should == "ümlaut"
  end
end
