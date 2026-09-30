require "spec_helper"
require "simple_agent_extension"
require "fixture"

module SimpleAgentExtension
  describe Collector do
    def package_type_directories(root)
      Dir.glob("*/*/", base: root).sort.map { |relative|
        package, type = relative.delete_suffix("/").split("/")

        [package, type, File.join(root, package, type)]
      }
    end

    describe ".source" do
      it "uses the given source root" do
        collector = Collector.source(root: "source")

        assert { collector.root == "source" }
      end
    end

    describe ".build" do
      it "uses the Agent and scope build root" do
        collector = Collector.build(
          root: "build",
          agent: Agents::Copilot.new,
          scope: :shared
        )

        assert { collector.root == File.join("build", "copilot", "shared") }
      end
    end

    describe "#dir" do
      it "locates a package/type directory below the root" do
        collector = Collector.new(root: "source")

        assert {
          collector.dir(
            package: "review",
            type: "skill"
          ) == File.join("source", "review", "skill")
        }
      end
    end

    describe "#dirs" do
      describe "when the root contains package/type directories" do
        it "lists every package/type directory" do
          Fixture.valid_workspace do |workspace|
            root = Fixture.source_root(workspace)
            collector = Collector.source(root: root)

            assert { collector.dirs == package_type_directories(root) }
          end
        end
      end

      describe "when the root does not exist" do
        it "lists no directories" do
          Fixture.workspace do |workspace|
            root = Fixture.source_root(workspace)

            assert { Collector.source(root: root).dirs.empty? }
          end
        end
      end
    end

    describe "#extensions" do
      describe "without filters" do
        it "materializes every package/type directory" do
          Fixture.valid_workspace do |workspace|
            root = Fixture.source_root(workspace)
            extensions = Collector.source(root: root).extensions

            assert {
              extensions.map(&:dir) == package_type_directories(root).map(&:last)
            }
          end
        end
      end

      describe "with package and type filters" do
        it "materializes the selected directory and its distributable files" do
          Fixture.valid_workspace do |workspace|
            root = Fixture.source_root(workspace)
            extensions = Collector.source(root: root).extensions(package: "bundled-skill", type: "skill")

            assert {
              extensions.map { |ext| [ext.class, ext.package, ext.dir, ext.files] } == [
                [
                  Extensions::Skill,
                  "bundled-skill",
                  File.join(root, "bundled-skill", "skill"),
                  ["SKILL.md", "references/checklist.md"]
                ]
              ]
            }
          end
        end
      end

      describe "when a type directory is unknown" do
        it "raises KeyError" do
          Fixture.invalid_workspace do |workspace|
            assert_raises(KeyError) do
              Collector.source(root: Fixture.source_root(workspace)).extensions
            end
          end
        end
      end

      describe "when the root does not exist" do
        it "returns no extensions" do
          Fixture.workspace do |workspace|
            root = Fixture.source_root(workspace)

            assert { Collector.source(root: root).extensions.empty? }
          end
        end
      end
    end
  end
end
