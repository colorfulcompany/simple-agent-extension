# frozen_string_literal: true

require "geminabox"

Geminabox.data = ENV.fetch("GEMINABOX_DATA") do
  File.expand_path("../tmp/geminabox", __dir__)
end

run Geminabox::Server
