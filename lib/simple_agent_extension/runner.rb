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

    # @param [String, nil] agent target name; all targets when omitted
    # @return [Array<String>] directories written to the build tree
    def build(agent: nil)
      selected_agents(agent).flat_map { |target|
        compiler = Compiler.new(agent: target, build_root: @build_root)

        source_extensions.map { |extension| compiler.compile(extension) }
      }
    end

    # @param [String, nil] agent target name; all targets when omitted
    # @param [Boolean] force deploy to an Agent whose config directory is absent
    # Results stay grouped by Agent so callers never have to read an Agent
    # name back out of a path. A skipped Agent and an Agent with no artifact
    # both appear as an empty array.
    #
    # @return [Hash{String => Array<Array(String, String)>}] source and
    #   destination pairs per Agent name
    def deploy(agent: nil, force: false)
      selected_agents(agent).to_h { |target|
        [target.name, Deployer.new(agent: target, build_root: @build_root).deploy(force: force)]
      }
    end

    # @param [String, nil] agent target name; all targets when omitted
    # @param [Boolean] force deploy to an Agent whose config directory is absent
    # @return [Array<Array>] compiled directories and deployed pairs per Agent
    def install(agent: nil, force: false)
      [build(agent: agent), deploy(agent: agent, force: force)]
    end

    private

    def source_extensions
      Collector.source(root: @source_root).extensions
    end

    def selected_agents(name)
      return @agent_registry.all if name.to_s.empty?

      [@agent_registry.fetch(name)]
    end
  end
end
