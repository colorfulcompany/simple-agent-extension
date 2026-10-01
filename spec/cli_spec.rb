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

  it "builds a selected externally registered Agent" do
    Fixture.valid_workspace do |workspace|
      agent_directory = File.join(workspace, "agents")
      config_dir = File.join(workspace, "external-config")
      write_agent(
        agent_directory,
        "external.rb",
        agent_source(class_name: "External", name: "external", config_dir: config_dir)
      )

      source_root = File.join(workspace, "source")
      build_root = File.join(workspace, "artifacts")
      stdout, stderr, status = invoke(
        workspace,
        "build",
        "--source-root", source_root,
        "--build-root", build_root,
        "--agent-dir", agent_directory,
        "--agent", "external"
      )

      assert {
        status.success? &&
          stderr.empty? &&
          !stdout.empty? &&
          File.directory?(File.join(build_root, "external", "shared", "metadata-free", "skill"))
      }
    end
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

      source_root = File.join(workspace, "source")
      build_root = File.join(workspace, "artifacts")
      destination = File.join(config_dir, "agents", "translated-permissions.md")
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
          File.exist?(File.join(build_root, "external", "own", "translated-permissions", "agent")) &&
          File.exist?(destination) &&
          stdout.include?(destination)
      }
    end
  end

  it "passes --force to deploy an uninstalled Agent" do
    Fixture.valid_workspace do |workspace|
      agent_directory = File.join(workspace, "agents")
      config_dir = File.join(workspace, "external-config")
      write_agent(
        agent_directory,
        "external.rb",
        agent_source(class_name: "External", name: "external", config_dir: config_dir)
      )

      _stdout, stderr, status = invoke(
        workspace,
        "deploy",
        "--source-root", File.join(workspace, "source"),
        "--build-root", File.join(workspace, "artifacts"),
        "--agent-dir", agent_directory,
        "--agent", "external",
        "--force"
      )

      assert {
        status.success? &&
          stderr.empty? &&
          File.exist?(File.join(config_dir, "agents", "translated-permissions.md"))
      }
    end
  end

  it "stops before building when an Agent directory is invalid" do
    Fixture.valid_workspace do |workspace|
      missing_directory = File.join(workspace, "missing-agents")
      build_root = File.join(workspace, "artifacts")
      stdout, stderr, status = invoke(
        workspace,
        "build",
        "--source-root", File.join(workspace, "source"),
        "--build-root", build_root,
        "--agent-dir", missing_directory
      )

      assert {
        !status.success? &&
          stdout.empty? &&
          stderr.lines.size == 1 &&
          stderr.include?(missing_directory) &&
          !File.exist?(build_root)
      }
    end
  end

  it "stops before building when a registration file fails to load" do
    Fixture.valid_workspace do |workspace|
      agent_directory = File.join(workspace, "agents")
      agent_file = File.join(agent_directory, "broken.rb")
      write_agent(agent_directory, "broken.rb", "raise \"unavailable\"\n")
      build_root = File.join(workspace, "artifacts")
      stdout, stderr, status = invoke(
        workspace,
        "build",
        "--source-root", File.join(workspace, "source"),
        "--build-root", build_root,
        "--agent-dir", agent_directory
      )

      assert {
        !status.success? &&
          stdout.empty? &&
          stderr.lines.size == 1 &&
          stderr.include?(agent_file) &&
          !File.exist?(build_root)
      }
    end
  end

  it "stops before building when an external Agent duplicates a built-in name" do
    Fixture.valid_workspace do |workspace|
      agent_directory = File.join(workspace, "agents")
      write_agent(
        agent_directory,
        "duplicate.rb",
        agent_source(
          class_name: "Duplicate",
          name: "copilot",
          config_dir: File.join(workspace, "duplicate-config")
        )
      )
      build_root = File.join(workspace, "artifacts")
      stdout, stderr, status = invoke(
        workspace,
        "build",
        "--source-root", File.join(workspace, "source"),
        "--build-root", build_root,
        "--agent-dir", agent_directory
      )

      assert {
        !status.success? &&
          stdout.empty? &&
          stderr == "duplicate agent: copilot\n" &&
          !File.exist?(build_root)
      }
    end
  end

  it "does not expose the former install command" do
    Fixture.valid_workspace do |workspace|
      stdout, stderr, status = invoke(workspace, "install")

      assert {
        !status.success? && stdout.empty? && stderr == "unknown command: install\n"
      }
    end
  end

  it "accepts --force only for deploy" do
    Fixture.valid_workspace do |workspace|
      stdout, stderr, status = invoke(workspace, "build", "--force")

      assert {
        !status.success? && stdout.empty? && stderr == "--force is only valid for deploy\n"
      }
    end
  end
end

module SimpleAgentExtension
  describe CLI do
    it "shows the command vocabulary in the help output" do
      output = StringIO.new
      status = CLI.new(output: output, error: StringIO.new).run(["--help"])

      assert { status == 0 && output.string.include?("Commands:") }
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
