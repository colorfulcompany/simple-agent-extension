module SimpleAgentExtension
  # Concrete coding-agent product classes.
  module Agents
  end
end

require_relative "agent_property"
require_relative "agent_base"
require_relative "agents/claude_code"
require_relative "agents/copilot"
require_relative "agents/opencode"
