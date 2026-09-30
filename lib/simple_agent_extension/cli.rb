# frozen_string_literal: true

require "optparse"
require "simple_agent_extension"

module SimpleAgentExtension
  # Command-line adapter for public package compilation and deployment.
  class CLI
    COMMANDS = %w[packages build deploy].freeze

    def self.run(arguments, output: $stdout, error: $stderr)
      new(output: output, error: error).run(arguments)
    end

    def initialize(output:, error:)
      @output = output
      @error = error
    end

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
    rescue OptionParser::ParseError, Error, ArgumentError, KeyError => error
      @error.puts error.message
      1
    end

    private

    def default_options
      {
        source_root: File.expand_path("packages"),
        build_root: File.expand_path("build"),
        agent: nil,
        agent_directories: [],
        force: false,
        help: false
      }
    end

    def option_parser(options)
      OptionParser.new do |parser|
        parser.banner = "Usage: simple-agent-extension COMMAND [options]"

        parser.on("--source-root DIRECTORY", "Source package root (default: ./packages)") do |directory|
          options[:source_root] = File.expand_path(directory)
        end
        parser.on("--build-root DIRECTORY", "Build artifact root (default: ./build)") do |directory|
          options[:build_root] = File.expand_path(directory)
        end
        parser.on("--agent NAME", "Build or deploy only NAME") do |name|
          options[:agent] = name
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

    def display_help(parser)
      @output.puts parser
      0
    end

    def command(arguments)
      command = arguments.shift
      raise ArgumentError, "missing command" unless command
      raise ArgumentError, "unknown command: #{command}" unless COMMANDS.include?(command)
      raise ArgumentError, "unexpected arguments: #{arguments.join(" ")}" unless arguments.empty?

      command
    end

    def validate_options(command, options)
      return unless options[:force] && command != "deploy"

      raise ArgumentError, "--force is only valid for deploy"
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
      when "build"
        @output.puts runner.build(agent: options[:agent])
      when "deploy"
        @output.puts runner.build(agent: options[:agent])
        print_deployments(runner.deploy(agent: options[:agent], force: options[:force]))
      end
    end

    def print_deployments(deployments)
      deployments.each { |source, destination| @output.puts "#{source} -> #{destination}" }
    end
  end
end
