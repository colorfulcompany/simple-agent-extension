require "spec_helper"
require "simple_agent_extension"
require "fixture"
require "support/testing_agent"

module SimpleAgentExtension
  describe Compiler do
    after { @workspace&.close }

    def testing_compiler
      Compiler.new(agent: TestingAgent.new, build_root: ".")
    end

    describe "#classify_artifact_scope" do
      before { @compiler = testing_compiler }

      describe "when a shareable skill retains its metadata" do
        before do
          @source_metadata = Metadata.from("description" => "source")
        end

        describe "without Agent-specific static metadata" do
          it "returns shared" do
            assert {
              @compiler.classify_artifact_scope(
                type: :skill,
                overlaid_adaptive: @source_metadata,
                adapted: @source_metadata,
                agent_static: Metadata.new
              ) == :shared
            }
          end
        end

        describe "with Agent-specific static metadata" do
          it "returns own" do
            assert {
              @compiler.classify_artifact_scope(
                type: :skill,
                overlaid_adaptive: @source_metadata,
                adapted: @source_metadata,
                agent_static: Metadata.from("mode" => "subagent")
              ) == :own
            }
          end
        end
      end

      describe "when Agent translation changes a skill's metadata" do
        it "returns own" do
          assert {
            @compiler.classify_artifact_scope(
              type: :skill,
              overlaid_adaptive: Metadata.from("description" => "source"),
              adapted: Metadata.from("description" => "adapted"),
              agent_static: Metadata.new
            ) == :own
          }
        end
      end

      describe "when the Agent does not support shared skills" do
        before do
          @compiler = Compiler.new(agent: TestingAgentWithoutSharedSkills.new, build_root: ".")
          @source_metadata = Metadata.from("description" => "source")
        end

        it "returns own" do
          assert {
            @compiler.classify_artifact_scope(
              type: :skill,
              overlaid_adaptive: @source_metadata,
              adapted: @source_metadata,
              agent_static: Metadata.new
            ) == :own
          }
        end
      end

      describe "when the extension is an agent" do
        before do
          @source_metadata = Metadata.from("description" => "source")
        end

        it "returns own" do
          assert {
            @compiler.classify_artifact_scope(
              type: :agent,
              overlaid_adaptive: @source_metadata,
              adapted: @source_metadata,
              agent_static: Metadata.new
            ) == :own
          }
        end
      end
    end

    describe "#fragment_transporter" do
      before do
        @compiler = testing_compiler
        @loader = MetadataLoader.new(Metadata.from(
          "adaptive" => {"permissions" => {"read" => "allow"}},
          "static" => {
            "common" => {"description" => "static description"},
            "agents" => {"testing" => {"mode" => "subagent"}}
          }
        ))
        @document = Extensions::EntrypointDocument.new(
          Metadata.from("description" => "frontmatter description", "retained" => "value"),
          "body\n"
        )
      end

      it "separates adaptive, common static, and Agent-specific static fragments" do
        fragments = @compiler.fragment_transporter(
          loader: @loader,
          document: @document,
          extension_name: "review"
        )

        assert {
          fragments.overlaid_adaptive == {"name" => "review", "permissions" => {"read" => "allow"}}
        }
        assert {
          fragments.common_static == {"description" => "static description", "retained" => "value"}
        }
        assert { fragments.agent_static == {"mode" => "subagent"} }
      end
    end

    describe "#translate_for_agent" do
      before do
        @compiler = testing_compiler
        @source_metadata = Metadata.from(
          "permissions" => {"read" => "allow", "edit" => "ask"},
          "unknown" => "value"
        )
      end

      it "translates known fields and retains fields without a rule" do
        translated = @compiler.translate_for_agent(type: :skill, overlaid_adaptive: @source_metadata)

        assert { translated == {"allowed-tools" => "read", "unknown" => "value"} }
      end
    end

    describe "#compile" do
      before { @agent = TestingAgent.new }

      describe "with the valid package fixture" do
        before do
          @workspace = Fixture.valid_workspace
          @compiler = Compiler.new(agent: @agent, build_root: @workspace.build_root)
        end

        describe "when a shareable skill is compiled" do
          before do
            @extension = Collector.source(root: @workspace.source_root)
              .extensions(package: "metadata-name-and-common-raw", type: "skill").fetch(0)
            @artifact = File.join(
              @workspace.build_root,
              "testing/shared/metadata-name-and-common-raw/skill/named-skill/SKILL.md"
            )
            @artifact_directory = File.join(
              @workspace.build_root,
              "testing/shared/metadata-name-and-common-raw/skill"
            )
          end

          it "materializes its core file in the shared layout" do
            compiled_directory = @compiler.compile(@extension)

            assert { compiled_directory == @artifact_directory }
            assert { File.file?(@artifact) }
          end
        end

        describe "when a skill has bundled files" do
          before do
            @extension = Collector.source(root: @workspace.source_root)
              .extensions(package: "bundled-skill", type: "skill").fetch(0)
            @bundled_artifact = File.join(
              @workspace.build_root,
              "testing/shared/bundled-skill/skill/bundled-skill/references/checklist.md"
            )
          end

          it "copies bundled files beside the artifact core file" do
            @compiler.compile(@extension)

            assert { File.read(@bundled_artifact) == "bundled\n" }
          end
        end
      end
    end
  end
end
