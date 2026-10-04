# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "open3"
require "rbconfig"
require "stringio"
require "simple_agent_extension/cli"
require "fixture"

CLI_EXECUTABLE = File.expand_path("../exe/simple-agent-extension", __dir__)
CLI_PACKAGE_NAMES = %w[
  agent-raw-override
  bundled-skill
  entrypoint-frontmatter
  metadata-free
  metadata-name-and-common-raw
  translated-permissions
].freeze

describe "simple-agent-extension" do
  def invoke(workspace, *arguments)
    Open3.capture3(RbConfig.ruby, CLI_EXECUTABLE, *arguments, chdir: workspace)
  end

  def write_agent(directory, filename, source)
    FileUtils.mkdir_p(directory)
    File.write(File.join(directory, filename), source)
  end

  def agent_source(class_name:, name:, config_dir:)
    <<~RUBY
      module SimpleAgentExtension
        module Agents
          class #{class_name} < AgentBase
            NAME = #{name.inspect}.freeze

            def default_config_dir
              #{config_dir.inspect}
            end

            def agent_core_file(extension_name:, source_file:)
              extension_name + ".md"
            end
          end
        end
      end
    RUBY
  end

  it "lists packages from the CWD-relative default source root" do
    Fixture.valid_workspace do |workspace|
      packages_root = File.join(workspace, "packages")
      FileUtils.mkdir_p(packages_root)
      FileUtils.cp_r(File.join(workspace, "source", "."), packages_root)

      stdout, stderr, status = invoke(workspace, "packages")

      assert {
        status.success? && stderr.empty? && stdout.lines.map(&:chomp) == CLI_PACKAGE_NAMES
      }
    end
  end

  # An Agent that does not declare one deploys shared skills under
  # `~/.agents/skills`. A CLI test therefore selects a source root whose
  # packages carry agent extensions only, so deployment stays in the workspace.
  def agent_only_source_root(workspace, package)
    root = File.join(workspace, "agent-source")
    FileUtils.mkdir_p(root)
    FileUtils.cp_r(File.join(workspace, "source", package), root)
    root
  end

  it "builds fresh artifacts before it deploys them" do
    Fixture.valid_workspace do |workspace|
      agent_directory = File.join(workspace, "agents")
      config_dir = File.join(workspace, "external-config")
      FileUtils.mkdir_p(config_dir)
      write_agent(
        agent_directory,
        "external.rb",
        agent_source(class_name: "External", name: "external", config_dir: config_dir)
      )

      source_root = agent_only_source_root(workspace, "agent-raw-override")
      build_root = File.join(workspace, "artifacts")
      destination = File.join(config_dir, "agents", "agent-raw-override.md")
      stdout, stderr, status = invoke(
        workspace,
        "deploy",
        "--source-root", source_root,
        "--build-root", build_root,
        "--agent-dir", agent_directory,
        "--agent", "external"
      )

      assert {
        status.success? &&
          stderr.empty? &&
          File.exist?(File.join(build_root, "external", "own", "agent-raw-override", "agent")) &&
          File.exist?(destination) &&
          stdout.include?("external\n") &&
          stdout.include?("  agent-raw-override/agent -> ")
      }
    end
  end

  it "builds for every repeated --agent" do
    Fixture.valid_workspace do |workspace|
      agent_directory = File.join(workspace, "agents")
      ["first", "second", "third"].each do |name|
        write_agent(
          agent_directory,
          "#{name}.rb",
          agent_source(
            class_name: name.capitalize,
            name: name,
            config_dir: File.join(workspace, "#{name}-config")
          )
        )
      end

      source_root = agent_only_source_root(workspace, "agent-raw-override")
      build_root = File.join(workspace, "artifacts")
      _stdout, stderr, status = invoke(
        workspace,
        "build",
        "--source-root", source_root,
        "--build-root", build_root,
        "--agent-dir", agent_directory,
        "--agent", "first",
        "--agent", "second"
      )

      assert {
        status.success? &&
          stderr.empty? &&
          File.directory?(File.join(build_root, "first")) &&
          File.directory?(File.join(build_root, "second")) &&
          !File.exist?(File.join(build_root, "third"))
      }
    end
  end
end

module SimpleAgentExtension
  describe CLI do
    describe "#run" do
      describe "with --help" do
        it "shows the command vocabulary" do
          output = StringIO.new
          status = CLI.new(output: output, error: StringIO.new).run(["--help"])

          assert { status == 0 && output.string.include?("Commands:") }
        end
      end

      describe "when no command is given" do
        it "reports the mistake, then shows the command vocabulary" do
          error = StringIO.new
          status = CLI.new(output: StringIO.new, error: error).run([])

          assert {
            status == 1 &&
              error.string.start_with?("missing command\n") &&
              error.string.include?("Commands:")
          }
        end
      end

      describe "when the former install command is given" do
        it "reports it as unknown, then shows the command vocabulary" do
          error = StringIO.new
          status = CLI.new(output: StringIO.new, error: error).run(["install"])

          assert {
            status == 1 &&
              error.string.start_with?("unknown command: install\n") &&
              error.string.include?("Commands:")
          }
        end
      end

      describe "when arguments follow a known command" do
        it "reports them, then shows the command vocabulary" do
          error = StringIO.new
          status = CLI.new(output: StringIO.new, error: error).run(["build", "extra"])

          assert {
            status == 1 &&
              error.string.start_with?("unexpected arguments: extra\n") &&
              error.string.include?("Commands:")
          }
        end
      end

      describe "when an option is misspelled" do
        it "reports the mistake alone, because the command is already known" do
          error = StringIO.new
          status = CLI.new(output: StringIO.new, error: error).run(["build", "--nope"])

          assert { status == 1 && error.string == "invalid option: --nope\n" }
        end
      end

      describe "when --force is given outside deploy" do
        it "reports the mistake alone" do
          error = StringIO.new
          status = CLI.new(output: StringIO.new, error: error).run(["build", "--force"])

          assert { status == 1 && error.string == "--force is only valid for deploy\n" }
        end
      end
    end

    describe "#agent_lines" do
      before do
        @cli = CLI.new(output: StringIO.new, error: StringIO.new)
      end

      it "pads the name column to the longest name and joins the declared columns" do
        lines = @cli.agent_lines([
          {name: "x", description: "An example agent", homepage: "https://example.test"},
          {name: "opencode", description: "Another agent", homepage: nil}
        ])

        assert {
          lines == [
            "x         An example agent  https://example.test",
            "opencode  Another agent"
          ]
        }
      end

      it "leaves the name alone when an Agent declares neither" do
        lines = @cli.agent_lines([{name: "bare", description: nil, homepage: nil}])

        assert { lines == ["bare"] }
      end
    end
  end
end
