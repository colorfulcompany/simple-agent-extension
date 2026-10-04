require "spec_helper"
require "simple_agent_extension"
require "tmpdir"

module SimpleAgentExtension
  describe MetadataLoader do
    describe ".load" do
      it "returns an empty reader when the file is absent" do
        Dir.mktmpdir do |dir|
          loader = MetadataLoader.load(dir)

          assert { loader.is_a?(MetadataLoader) }
          assert { loader.metadata.empty? }
        end
      end

      it "returns an empty reader for an empty metadata file" do
        Dir.mktmpdir do |dir|
          File.write(File.join(dir, MetadataLoader::FILENAME), "")

          loader = MetadataLoader.load(dir)

          assert { loader.metadata.empty? }
        end
      end

      describe "with a YAML syntax error" do
        it "raises InvalidMetadata" do
          File.stub(:exist?, true) do
            File.stub(:read, "name: [x\n") do
              assert_raises(MetadataLoader::InvalidMetadata) { MetadataLoader.load("/source/deep-review/skill") }
            end
          end
        end
      end
    end

    describe "with sections" do
      before {
        @loader = MetadataLoader.new(Metadata.from(
          "name" => "deep-design-reviewer",
          "adaptive" => {
            "tools" => ["bash"]
          },
          "static" => {
            "common" => {
              "description" => "Reviews designs."
            },
            "agents" => {
              "copilot" => {
                "mode" => "subagent"
              }
            }
          }
        ))
      }
      after { @loader = nil }

      it "returns the adaptive section" do
        assert { @loader.adaptive == {"tools" => ["bash"]} }
      end

      it "returns the common static section" do
        assert { @loader.common_static == {"description" => "Reviews designs."} }
      end

      it "returns the selected Agent's static section" do
        assert { @loader.agent_static("copilot") == {"mode" => "subagent"} }
      end

      it "names no distribution target" do
        assert { @loader.deploy_to.nil? }
      end
    end

    describe "with deploy_to" do
      it "returns the listed Agent names" do
        loader = MetadataLoader.new(Metadata.from("deploy_to" => ["opencode", "copilot"]))

        assert { loader.deploy_to == ["opencode", "copilot"] }
      end

      it "keeps deploy_to out of the adaptive and static sections" do
        loader = MetadataLoader.new(Metadata.from("deploy_to" => ["opencode"]))

        assert { loader.adaptive.empty? && loader.common_static.empty? }
      end
    end

    describe "without sections" do
      before { @loader = MetadataLoader.new(Metadata.from("name" => "review")) }
      after { @loader = nil }

      it "returns empty adaptive metadata" do
        assert { @loader.adaptive == Metadata.new }
      end

      it "returns empty common static metadata" do
        assert { @loader.common_static == Metadata.new }
      end

      it "returns empty Agent static metadata" do
        assert { @loader.agent_static("opencode") == Metadata.new }
      end
    end
  end
end
