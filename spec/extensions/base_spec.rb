require "spec_helper"
require "simple_agent_extension"
require "minitest/mock"
require "support/testing_base_extensions"

module SimpleAgentExtension
  describe Extensions::Base do
    describe "#type" do
      it "derives the type from the concrete class name" do
        extension = TestingBase::Skill.new(package: "deep-review", dir: ".", files: ["SKILL.md"])

        assert { extension.type == "skill" }
      end
    end

    describe "#entrypoint" do
      it "requires a concrete extension type to define it" do
        extension = Extensions::Base.new(package: "deep-review", dir: ".", files: [])

        assert_raises(NotImplementedError) { extension.entrypoint }
      end
    end

    describe "MetadataLoader.load" do
      it "receives the extension directory" do
        dir = "/source/deep-review/skill"
        metadata = Metadata.from("name" => "test-name")
        loader = MetadataLoader.new(metadata)
        load = Minitest::Mock.new
        load.expect(:call, loader, [dir])

        MetadataLoader.stub(:load, load) do
          extension = Extensions::Base.new(package: "deep-review", dir: dir, files: [])

          extension.metadata
        end

        assert { load.verify } # arguments == [dir]
      end
    end

    describe "#deploy_to" do
      it "returns the Agent names the extension declares" do
        extension = TestingBase::WithDeployTo.new(package: "deep-review", dir: ".", files: [])

        assert { extension.deploy_to == ["copilot", "opencode"] }
      end

      it "returns nil when the extension declares none" do
        extension = TestingBase::WithoutDeployTo.new(package: "deep-review", dir: ".", files: [])

        assert { extension.deploy_to.nil? }
      end
    end

    describe "#deployable_to?" do
      it "accepts an Agent the extension names" do
        extension = TestingBase::WithDeployTo.new(package: "deep-review", dir: ".", files: [])

        assert { extension.deployable_to?("copilot") }
      end

      it "rejects an Agent the extension does not name" do
        extension = TestingBase::WithDeployTo.new(package: "deep-review", dir: ".", files: [])

        assert { !extension.deployable_to?("claude") }
      end

      it "accepts every Agent when the extension names none" do
        extension = TestingBase::WithoutDeployTo.new(package: "deep-review", dir: ".", files: [])

        assert { extension.deployable_to?("claude") }
      end
    end

    describe "#entrypoint_path" do
      it "joins the extension directory and entrypoint" do
        extension = TestingBase::Skill.new(
          package: "deep-review",
          dir: "/source/deep-review/skill",
          files: ["SKILL.md"]
        )

        assert { extension.entrypoint_path == "/source/deep-review/skill/SKILL.md" }
      end
    end

    describe "#entrypoint_document" do
      it "returns an empty document for an empty entrypoint" do
        extension = TestingBase::Skill.new(
          package: "deep-review",
          dir: "/source/deep-review/skill",
          files: ["SKILL.md"]
        )

        File.stub(:read, "") do
          assert { extension.entrypoint_document.is_a? Extensions::EntrypointDocument }
        end
      end
    end

    describe "#name" do
      describe TestingBase::WithBothMetadataAndFrontmatterName do
        it "prefers metadata over frontmatter and package" do
          extension = TestingBase::WithBothMetadataAndFrontmatterName.new(package: "package-name", dir: ".", files: [])

          assert { extension.name == "metadata-name" }
        end
      end

      describe TestingBase::WithMetadataNameOnly do
        it "uses the metadata name" do
          extension = TestingBase::WithMetadataNameOnly.new(package: "package-name", dir: ".", files: [])

          assert {
            extension.name == "metadata-name"
          }
        end
      end

      describe TestingBase::WithFrontmatterNameOnly do
        it "prefers frontmatter over package" do
          extension = TestingBase::WithFrontmatterNameOnly.new(package: "package-name", dir: ".", files: [])

          assert { extension.name == "frontmatter-name" }
        end
      end

      describe TestingBase::NoMetadataNoFrontmatter do
        it "falls back to the package" do
          extension = TestingBase::NoMetadataNoFrontmatter.new(package: "package-name", dir: ".", files: [])

          assert { extension.name == "package-name" }
        end
      end
    end
  end
end
