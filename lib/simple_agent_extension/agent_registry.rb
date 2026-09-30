module SimpleAgentExtension
  class DuplicatedAgentName < Error; end
  class DuplicatedAgentConfigurationName < Error; end
  class UnknownAgentName < Error; end

  # A configured set of deployment Agent instances for one run.
  #
  # Agents remains the namespace for product classes. This registry owns the
  # runtime concerns that need an instance collection: lookup by name,
  # membership, and duplicate-name rejection.
  class AgentRegistry
    # @return [AgentRegistry] all known Agents at their default destinations
    def self.default
      new(agent_classes.map(&:new))
    end

    # Applies destination overrides without modifying the default registry or
    # any other registry. Missing entries retain their Agent defaults; entries
    # do not select which Agents are present.
    #
    # @param [Hash{String, Symbol => Hash}] overrides per-Agent initializer options
    # @return [AgentRegistry]
    def self.configure(overrides = {})
      options = options_by_agent(overrides)
      defaults = default
      unknown = options.keys - defaults.all.map(&:name)
      raise UnknownAgentName, "unknown agent: #{unknown.first}" unless unknown.empty?

      new(defaults.all.map { |agent|
        agent.class.new(**options.fetch(agent.name, {}))
      })
    end

    # @return [Array<Class>] concrete Agent classes
    def self.agent_classes
      Agents.constants(false)
        .map { |const| Agents.const_get(const) }
        .select { |klass| klass.is_a?(Class) && klass < AgentBase }
        .sort_by(&:name)
    end

    # Converts Agent-name keys and Agent initializer option keys to their
    # canonical String and Symbol forms, as below.
    #
    # ```
    # name[String] => {
    #   key[Symbol] => val,
    #   key[Symbol] => val
    # }
    # ```
    #
    # @param [Hash{String, Symbol => Hash}] overrides per-Agent destination options
    # @return [Hash{String => Hash{Symbol => Object}}]
    # @raise [ArgumentError] when names are duplicated after normalization
    def self.options_by_agent(overrides)
      overrides.each_with_object({}) do |(name, agent_options), options|
        key = name.to_s
        raise DuplicatedAgentConfigurationName, "duplicate agent configuration: #{key}" if options.key?(key)

        options[key] = agent_options.transform_keys(&:to_sym)
      end
    end

    # @param [Array<AgentBase>] agents configured instances for one run
    # @raise [ArgumentError] when names are duplicated
    def initialize(agents)
      @agents = agents.dup.freeze
      @by_name = @agents.each_with_object({}) do |agent, index|
        raise DuplicatedAgentName, "duplicate agent: #{agent.name}" if index.key?(agent.name)

        index[agent.name] = agent
      end.freeze
    end

    # @yield [AgentBase]
    # @return [Enumerator]
    def each(&block)
      @agents.each(&block)
    end

    # @return [Array<AgentBase>]
    def all
      @agents
    end

    # @param [String, Symbol] name
    # @return [AgentBase]
    # @raise [KeyError] when no configured instance has this name
    def fetch(name)
      @by_name.fetch(name.to_s) { raise UnknownAgentName, "unknown agent: #{name}" }
    end

    # @param [String, Symbol] name
    # @return [Boolean]
    def include?(name)
      @by_name.key?(name.to_s)
    end
  end
end
