module SimpleAgentExtension
  # Distributables. One `<pkg>/<type>/` directory is one extension.
  #
  # The class is the type; there is no separate attribute for it.
  # Extension::Something ( eg, Skill, Agent, .. )
  module Extensions
  end
end

require_relative "extensions/base"
require_relative "extensions/skill"
require_relative "extensions/agent"

module SimpleAgentExtension
  module Extensions
    # Raises a plain KeyError for an unknown type: the collector walks the
    # second level of `packages/` unconditionally, so a directory that is not
    # one of these is a layout mistake, not something to route around
    #
    # @param [String, Symbol] type
    # @return [Class] - subclass of Extensions::Base
    def self.for(type)
      constants.map { |const| const_get(const) }
        .select { |klass| klass.is_a?(Class) && klass < Base }
        .find { |klass| klass.name.split("::").last.downcase == type.to_s } ||
        raise(KeyError, "key not found: #{type.inspect}")
    end
  end
end
