require "spec_helper"
require "simple_agent_extension"

module SimpleAgentExtension::Agents
  describe OpenCode do
    describe OpenCode::MetadataTranslator do
      it "converts agent permissions" do
        assert {
          OpenCode::MetadataTranslator.new.translate(
            type: :agent,
            field: "permissions",
            value: {"read" => "allow", "edit" => "ask"}
          ) == {"permission" => {"read" => "allow", "edit" => "ask"}}
        }
      end
    end

    describe "#artifact_core_file" do
      it "uses OpenCode's agent filename" do
        assert {
          OpenCode.new.artifact_core_file(
            extension_type: :agent,
            extension_name: "review",
            source_file: "ignored.md"
          ) == "review.md"
        }
      end
    end

    describe "#config_dir" do
      it "uses the OpenCode configuration directory by default" do
        assert {
          OpenCode.new.config_dir == File.expand_path("~/.config/opencode")
        }
      end
    end
  end
end
