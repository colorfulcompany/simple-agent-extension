require "spec_helper"
require "simple_agent_extension"

module SimpleAgentExtension::Agents
  describe Copilot do
    describe Copilot::MetadataTranslator do
      it "converts allowed agent permissions to tools" do
        assert {
          Copilot::MetadataTranslator.new.translate(
            type: :agent,
            field: "permissions",
            value: {"read" => "allow", "search" => "allow", "edit" => "ask"}
          ) == {"tools" => ["read", "search"]}
        }
      end
    end

    describe "#artifact_core_file" do
      it "uses Copilot's agent filename" do
        assert {
          Copilot.new.artifact_core_file(
            extension_type: :agent,
            extension_name: "review",
            source_file: "ignored.md"
          ) == "review.agent.md"
        }
      end
    end
  end
end
