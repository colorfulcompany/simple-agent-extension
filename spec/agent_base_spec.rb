require "spec_helper"
require "simple_agent_extension"
require "support/testing_agent"

module SimpleAgentExtension
  describe AgentBase do
    it "reports no translation and rejects direct translation without a translator" do
      agent = Class.new(AgentBase).new

      assert {
        !agent.can_trans_meta?(type: :skill, field: "permissions")
      }

      assert_raises(AgentBase::MissingMetadataTranslator) do
        agent.trans_meta(type: :skill, field: "permissions", value: {"read" => "allow"})
      end
    end

    it "has no description or homepage unless the subclass declares them" do
      agent = TestingAgent.new

      assert { agent.description.nil? && agent.homepage.nil? }
    end

    it "exposes the description and homepage the subclass declares" do
      agent = TestingFullDescribedAgent.new

      assert {
        agent.description == "An example coding agent" && agent.homepage == "https://example.test"
      }
    end

    it "inherits the description and homepage of its superclass, as NAME does" do
      agent = TestingAgentInheritingDescription.new

      assert {
        agent.description == "An example coding agent" && agent.homepage == "https://example.test"
      }
    end
  end
end
