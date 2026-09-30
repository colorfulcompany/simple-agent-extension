# frozen_string_literal: true

require_relative "simple_agent_extension/version"

module SimpleAgentExtension
  class Error < StandardError; end
  class AmbiguousEntrypoint < Error; end # extensions/agent.rb
end

require_relative "simple_agent_extension/metadata"
require_relative "simple_agent_extension/frontmatter"
require_relative "simple_agent_extension/metadata_loader"
require_relative "simple_agent_extension/agent_property"
require_relative "simple_agent_extension/metadata_composer"
require_relative "simple_agent_extension/extensions"
require_relative "simple_agent_extension/collector"
require_relative "simple_agent_extension/agents"
require_relative "simple_agent_extension/agent_registry"
require_relative "simple_agent_extension/agent_directory_loader"
require_relative "simple_agent_extension/compiler"
require_relative "simple_agent_extension/deployer"
require_relative "simple_agent_extension/runner"
