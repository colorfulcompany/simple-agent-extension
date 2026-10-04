# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "fixture"
require "simple_agent_extension"

module SimpleAgentExtension
  module AgentDirectoryLoaderSpecSupport
    REGISTERED_AGENT_CONSTANTS = %i[
      LoaderSpecDuplicate
      LoaderSpecFirst
      LoaderSpecSecond
    ].freeze
  end

  describe AgentDirectoryLoader do
    after do
      AgentDirectoryLoaderSpecSupport::REGISTERED_AGENT_CONSTANTS.each do |constant|
        Agents.send(:remove_const, constant) if Agents.const_defined?(constant, false)
      end
    end

    def write_file(directory, filename, source)
      FileUtils.mkdir_p(directory)
      path = File.join(directory, filename)
      File.write(path, source)
      path
    end

    def agent_source(class_name:, name:)
      <<~RUBY
        module SimpleAgentExtension
          module Agents
            class #{class_name} < AgentBase
              NAME = #{name.inspect}.freeze
            end
          end
        end
      RUBY
    end

    describe "#load" do
      describe "with direct Ruby files in the directory" do
        it "loads every one" do
          Fixture.workspace do |workspace|
            directory = File.join(workspace, "agents")
            write_file(
              directory,
              "first.rb",
              agent_source(class_name: "LoaderSpecFirst", name: "loader-spec-first")
            )
            write_file(
              directory,
              "second.rb",
              agent_source(class_name: "LoaderSpecSecond", name: "loader-spec-second")
            )

            AgentDirectoryLoader.new(directory).load

            assert {
              Agents.const_defined?(:LoaderSpecFirst, false) &&
                Agents.const_defined?(:LoaderSpecSecond, false)
            }
          end
        end
      end

      describe "when two paths name the same directory" do
        it "loads its files once" do
          Fixture.workspace do |workspace|
            directory = File.join(workspace, "agents")
            write_file(
              directory,
              "agent.rb",
              agent_source(class_name: "LoaderSpecDuplicate", name: "loader-spec-duplicate")
            )

            AgentDirectoryLoader.new([directory, File.join(directory, ".")]).load

            assert {
              Agents.const_defined?(:LoaderSpecDuplicate, false)
            }
          end
        end
      end

      describe "when the directory does not exist" do
        it "rejects it before loading files" do
          Fixture.workspace do |workspace|
            directory = File.join(workspace, "missing")

            error = assert_raises(InvalidAgentDirectory) do
              AgentDirectoryLoader.new(directory).load
            end

            assert {
              error.message == "invalid agent directory: #{directory}"
            }
          end
        end
      end

      describe "when a direct Ruby file does not register an Agent" do
        it "rejects the file" do
          Fixture.workspace do |workspace|
            directory = File.join(workspace, "agents")
            file = write_file(directory, "ignored.rb", "module SimpleAgentExtension; end\n")

            error = assert_raises(MissingAgentRegistration) do
              AgentDirectoryLoader.new(directory).load
            end

            assert {
              error.message == "#{File.realpath(file)}: did not register an Agent"
            }
          end
        end
      end

      describe "when a registration file cannot load" do
        it "includes the source failure" do
          Fixture.workspace do |workspace|
            directory = File.join(workspace, "agents")
            file = write_file(directory, "broken.rb", "raise \"unavailable\"\n")

            error = assert_raises(UnloadableAgentRegistration) do
              AgentDirectoryLoader.new(directory).load
            end

            assert {
              error.message == "#{File.realpath(file)}: RuntimeError: unavailable"
            }
          end
        end
      end
    end
  end
end
