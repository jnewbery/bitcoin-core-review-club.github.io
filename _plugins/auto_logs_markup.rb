# frozen_string_literal: true

require 'uri'

# URI schemes to accept for extraction.
URI_SCHEMES = %w(http https).freeze

# Trailing chars to remove from URIs.
TRAILING = /[[:punct:]]+$/

# Regex to select lines starting with "HH:MM " time.
HH_MM = /^([0-1][0-9]|[2][0-3]):[0-5][0-9] .*/

# Regex to select IRC <nick>.
IRC_NICK = /<.+?>/

# Regex to select "<" and ">" chars.
LT_GT = /[<>]/

# Maximum digits to display for log lines.
LINE_DIGITS = 3

# Length of timestamp string being used.
TIME_SIZE = 'HH:MM'.size
TIME_SIZE_PLUS_1 = TIME_SIZE + 1 # Micro-perf optimization

NON_BREAKING_SPACE = '&nbsp;'

COLORS = %w(aqua aquamarine blue blueviolet brown cadetblue chartreuse chocolate
coral cornflowerblue crimson cyan darkblue darkcyan firebrick forestgreen
fuchsia gold goldenrod green grey hotpink indianred indigo khaki lawngreen
magenta maroon mediumblue mediumpurple mediumseagreen navy olive orange orchid
papayawhip peru pink plum purple rebeccapurple red rosybrown royalblue salmon
seagreen sienna silver skyblue slateblue springgreen steelblue tan teal thistle
tomato turquoise violet wheat yellow yellowgreen).freeze

# Convert logs from plain text to HTML with line number links.
#
Jekyll::Hooks.register :documents, :pre_render do |post|
  # Reset color data for each post.
  colors, color_index, name_colors = COLORS.shuffle, -1, {}

  # Loop through each line of the meeting logs.
  post.content.gsub!(HH_MM).with_index(1) do |line, index|

    # Separate the log line into useful parts.
    lineno  = "#{NON_BREAKING_SPACE * (LINE_DIGITS - index.to_s.size)}#{index}"
    time    = line[0..TIME_SIZE]
    name    = IRC_NICK.match(line).to_s
    nick    = name.gsub(LT_GT, '').strip
    color   = name_colors[nick] || (name_colors[nick] = colors[color_index += 1])
    message = CGI.escapeHTML(line[TIME_SIZE_PLUS_1 + name.size..-1])

    # Extract URIs from the message and convert them to HTML links.
    URI.extract(message, schemes = URI_SCHEMES).each do |uri|
      link = uri.sub(TRAILING, '') # Strip unwanted trailing punctuation
      message.sub!(link, "<a href='#{link}' target='blank'>#{link}</a>")
    end

    # Return the log line as HTML markup.
    "<table class='log-line' id='l-#{index}'>" \
      "<tr class='log-row'>" \
        "<td class='log-lineno'><a href='#l-#{index}'>#{lineno}</a></td>" \
        "<td class='log-time'>#{time}</td>" \
        "<td>" \
          "<span class='log-nick' style='color:#{color}'>&lt;#{nick}&gt;</span>" \
          "<span class='log-msg'>#{message}</span>" \
        "</td>" \
      "</tr>" \
    "</table>"
  end
end
