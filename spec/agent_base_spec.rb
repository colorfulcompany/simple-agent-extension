require "spec_helper"
require "simple_agent_extension"

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
  end
end
