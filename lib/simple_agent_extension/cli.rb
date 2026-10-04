# frozen_string_literal: true

require "optparse"
require "simple_agent_extension"

module SimpleAgentExtension
  # Command-line adapter for public package compilation and deployment.
  class CLI
    # The command line itself was written wrong. The message describes the
    # mistake in full, so where it was raised tells the caller nothing.
    class UsageError < Error; end

    # No command was resolved, so the caller still needs the vocabulary.
    class CommandError < UsageError; end

    COMMANDS = {
      "packages" => "List package names under the source root",
      "build" => "Compile artifacts into the build root",
      "deploy" => "Build artifacts, then deploy them to Agents",
      "agents" => "List Agent names that can be targeted"
    }.freeze

    def self.run(arguments, output: $stdout, error: $stderr)
      new(output: output, error: error).run(arguments)
    end

    def initialize(output:, error:)
      @output = output
      @error = error
    end

    # Only errors this CLI defines, and the one OptionParser raises for a
    # misspelled option, are reduced to a message. Everything else passes
    # through with its class, origin, and backtrace intact.
    #
    # CommandError has to be listed first: it is a UsageError, so the wider
    # clause would take it otherwise.
    def run(arguments)
      arguments = arguments.dup
      options = default_options
      parser = option_parser(options)
      parser.parse!(arguments)

      return display_help(parser) if options[:help]

      command = command(arguments)
      validate_options(command, options)
      AgentDirectoryLoader.new(options[:agent_directories]).load
      run_command(command, options)
      0
    rescue CommandError => error
      report_failure(error, usage: parser)
    rescue OptionParser::ParseError, UsageError => error
      report_failure(error)
    end

    # Aligns the name column alone. Columns an Agent does not declare are
    # dropped rather than padded, so no line carries trailing whitespace.
    #
    # @param [Array<Hash>] agents name, description, and homepage per Agent
    # @return [Array<String>]
    def agent_lines(agents)
      width = agents.map { |agent| agent[:name].length }.max.to_i

      agents.map do |agent|
        [agent[:name].ljust(width), agent[:description], agent[:homepage]].compact.join("  ").rstrip
      end
    end

    private

    # @param [Exception] error
    # @param [OptionParser, nil] usage printed when the caller still needs the
    #   command vocabulary
    # @return [Integer] exit status the run reports as a failure
    def report_failure(error, usage: nil)
      @error.puts error.message
      @error.puts usage if usage
      1
    end

    def default_options
      {
        source_root: File.expand_path("packages"),
        build_root: File.expand_path("build"),
        agents: [],
        agent_directories: [],
        force: false,
        help: false
      }
    end

    def option_parser(options)
      OptionParser.new do |parser|
        parser.banner = banner

        parser.on("--source-root DIRECTORY", "Source package root (default: ./packages)") do |directory|
          options[:source_root] = File.expand_path(directory)
        end
        parser.on("--build-root DIRECTORY", "Build artifact root (default: ./build)") do |directory|
          options[:build_root] = File.expand_path(directory)
        end
        parser.on("--agent NAME", "Build or deploy only NAME (repeatable)") do |name|
          options[:agents] << name
        end
        parser.on("--agent-dir DIRECTORY", "Load direct *.rb Agent registrations from DIRECTORY") do |directory|
          options[:agent_directories] << directory
        end
        parser.on("--force", "Deploy even if an Agent is not installed") do
          options[:force] = true
        end
        parser.on("-h", "--help", "Show this help") do
          options[:help] = true
        end
      end
    end

    def banner
      width = COMMANDS.keys.map(&:length).max
      commands = COMMANDS.map { |name, summary| "    #{name.ljust(width)}  #{summary}" }

      ["Usage: simple-agent-extension COMMAND [options]", "", "Commands:", *commands, "", "Options:"].join("\n")
    end

    def display_help(parser)
      @output.puts parser
      0
    end

    def command(arguments)
      command = arguments.shift
      raise CommandError, "missing command" unless command
      raise CommandError, "unknown command: #{command}" unless COMMANDS.key?(command)
      raise CommandError, "unexpected arguments: #{arguments.join(" ")}" unless arguments.empty?

      command
    end

    def validate_options(command, options)
      return unless options[:force] && command != "deploy"

      raise UsageError, "--force is only valid for deploy"
    end

    def run_command(command, options)
      runner = Runner.new(
        source_root: options[:source_root],
        build_root: options[:build_root],
        agent_registry: AgentRegistry.default
      )

      case command
      when "packages"
        @output.puts runner.packages
      when "agents"
        @output.puts agent_lines(runner.agents)
      when "build"
        @output.puts runner.build(agents: options[:agents])
      when "deploy"
        @output.puts runner.build(agents: options[:agents])
        print_deployments(runner.deploy(agents: options[:agents], force: options[:force]))
      end
    end

    def print_deployments(deployments)
      @output.puts DeploymentReport.new(deployments).lines
    end
  end
end
