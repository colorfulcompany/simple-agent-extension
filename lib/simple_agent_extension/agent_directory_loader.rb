# frozen_string_literal: true

module SimpleAgentExtension
  class InvalidAgentDirectory < Error; end
  class MissingAgentRegistration < Error; end
  class UnloadableAgentRegistration < Error; end

  # Loads trusted, explicitly selected Agent registration files for one run.
  # Discovery is intentionally flat so a directory's registration surface is
  # visible without implicit recursive loading. Each file must be self-contained:
  # a registration cannot define an Agent that refers to an Agent defined in a
  # sibling file, because load order is an implementation detail rather than a
  # contract. Files are still sorted to keep a run reproducible.
  class AgentDirectoryLoader
    def initialize(directories)
      @directories = Array(directories)
    end

    def load
      directories.each do |directory|
        agent_files(directory).each { |file| load_file(file) }
      end
    end

    private

    def directories
      @directories.map { |directory| canonical_directory(directory) }.uniq
    end

    def canonical_directory(directory)
      path = File.expand_path(directory)
      raise InvalidAgentDirectory, "invalid agent directory: #{path}" unless File.directory?(path)

      path = File.realpath(path)
      raise InvalidAgentDirectory, "invalid agent directory: #{path}" unless File.readable?(path)

      path
    end

    def agent_files(directory)
      Dir.glob(File.join(directory, "*.rb")).sort.map { |file| File.realpath(file) }
    end

    def load_file(file)
      known_agent_classes = AgentRegistry.agent_classes
      require_registration(file)

      return unless (AgentRegistry.agent_classes - known_agent_classes).empty?

      raise MissingAgentRegistration, "#{file}: did not register an Agent"
    end

    def require_registration(file)
      require file
    rescue StandardError, ScriptError => error
      raise UnloadableAgentRegistration, "#{file}: #{error.class}: #{error.message}"
    end
  end
end
