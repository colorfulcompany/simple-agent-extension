module SimpleAgentExtension
  # Coordinates source collection, compilation, and deployment for one
  # source and build roots. Entry points configure these boundaries explicitly.
  class Runner
    # @param [String] source_root source package root
    # @param [String] build_root compiled artifact root
    # @param [AgentRegistry] agent_registry configured deployment targets
    def initialize(source_root:, build_root:, agent_registry: AgentRegistry.default)
      @source_root = source_root
      @build_root = build_root
      @agent_registry = agent_registry
    end

    # @return [Array<String>]
    def packages
      source_extensions.map(&:package).uniq
    end

    # @return [Array<Hash>] name, description, and homepage of every Agent
    #   configured for this run. Description and homepage are nil when the
    #   Agent does not declare them.
    def agents
      @agent_registry.all.map do |agent|
        {name: agent.name, description: agent.description, homepage: agent.homepage}
      end
    end

    # @param [Array<String>] agents target names; all targets when empty
    # @return [Array<String>] directories written to the build tree
    def build(agents: [])
      selected_agents(agents).flat_map { |agent|
        compiler = Compiler.new(agent: agent, build_root: @build_root)

        source_extensions.map { |extension| compiler.compile(extension) }
      }
    end

    # @param [Array<String>] agents target names; all targets when empty
    # @param [Boolean] force deploy to an Agent whose config directory is absent
    # Results stay grouped by Agent so callers never have to read an Agent
    # name back out of a path. A skipped Agent and an Agent with no artifact
    # both appear as an empty array.
    #
    # @return [Hash{String => Array<Array(String, String)>}] source and
    #   destination pairs per Agent name
    def deploy(agents: [], force: false)
      selected_agents(agents).to_h { |agent|
        [agent.name, Deployer.new(agent: agent, build_root: @build_root).deploy(force: force)]
      }
    end

    # @param [Array<String>] agents target names; all targets when empty
    # @param [Boolean] force deploy to an Agent whose config directory is absent
    # @return [Array<Array>] compiled directories and deployed pairs per Agent
    def install(agents: [], force: false)
      [build(agents: agents), deploy(agents: agents, force: force)]
    end

    private

    def source_extensions
      Collector.source(root: @source_root).extensions
    end

    # @param [Array<String>] agents requested names; all targets when empty
    # @return [Array<AgentBase>]
    # @raise [UnknownAgentName] when a requested name is not configured
    def selected_agents(agents)
      names = Array(agents).reject { |name| name.to_s.empty? }.map(&:to_s).uniq
      return @agent_registry.all if names.empty?

      names.map { |name| @agent_registry.fetch(name) }
    end
  end
end
