require 'hpricot'

module PostloadGoogleAds
  PLACEHOLDER_CSSCLASS = "postload_google_ads-placeholder"
  ADSWRAPPER_CSSCLASS = "postload_google_ads-adswrapper"
  def postload_google_ads
    doc = Hpricot(response.body)
    # find all ads <script> and wrap in 2 layers of div (.placeholder > .adswrapper > script)
    (doc/self.class.google_ads_cssselector).wrap("<div class='#{PLACEHOLDER_CSSCLASS}'><div class='#{ADSWRAPPER_CSSCLASS}'></div></div>")
    # remove these <scripts> & .adswrapper from in the tree, leaving behind the outermost .placeholder
    scripts = (doc/"div.#{ADSWRAPPER_CSSCLASS}").remove
    # append them to the document body, together with a custom script that will reposition the ads back superficially
    (doc/"body").append(scripts.to_s)
    (doc/"body").append(<<-EOM
    <script>
      (function(csspath) {
        if (!window.jQuery) return;
        var placeholders = $('.#{PLACEHOLDER_CSSCLASS}').
          append('<div></div>').
          children('div'); // dummy child to correctly locate the top-left
        setInterval(function() {
          jQuery(csspath).each(function(index, ele) {
            var jplaceholder = $(placeholders[index]);
            var jele = $(ele);
            jplaceholder.css({ width: jele.width() + 'px', height: jele.height() + 'px' });
            var position = jplaceholder.position();
            jele.css({ top: position.top + 'px', left: position.left + 'px', position: 'absolute' });
          });
        }, 500);
      })('.#{ADSWRAPPER_CSSCLASS}');
    </script>
    EOM
    )
    response.body = doc.to_s
    response.headers['Content-Length'] = response.body.length
  end
end
