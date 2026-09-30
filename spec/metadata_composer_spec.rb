require "spec_helper"
require "simple_agent_extension"

module SimpleAgentExtension
  describe MetadataComposer do
    describe "#common_static_fragments" do
      it "overlay frontmatter with metadata static common fragment" do
        assert {
          MetadataComposer.new.common_static_fragments(
            frontmatter: Metadata.from("model" => "frontmatter", "description" => "frontmatter"),
            common_static: Metadata.from("description" => "common static")
          ) == {"model" => "frontmatter", "description" => "common static"} # description overriden
        }
      end
    end

    describe "#overlay_agent_specific" do
      it "common static < agent-specific adapted < agent-specific static " do
        assert {
          MetadataComposer.new.overlay_agent_specific(
            common: Metadata.from("description" => "kept", "tools" => ["common"], "mode" => "common"),
            adapted: Metadata.from("name" => "reviewer", "tools" => ["adapted"], "mode" => "adapted"),
            agent_static: Metadata.from("tools" => ["agent"])
          ) == {"tools" => ["agent"], "description" => "kept", "mode" => "adapted", "name" => "reviewer"}
        }
      end
    end
  end
end
