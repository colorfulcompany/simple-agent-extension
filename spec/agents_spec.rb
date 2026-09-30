require "spec_helper"
require "simple_agent_extension"

module SimpleAgentExtension
  describe Agents do
    it "contains only concrete product classes" do
      assert {
        Agents.constants(false).all? { |name|
          klass = Agents.const_get(name)
          klass.is_a?(Class) && klass < AgentBase
        }
      }
    end
  end
end
