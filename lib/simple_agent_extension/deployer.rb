require "fileutils"

module SimpleAgentExtension
  # Maps `build/<agent>/<scope>/<pkg>/<type>/` to the directories an Agent
  # exposes, then copies it. The build scope is Compiler's recorded decision:
  #
  # - skill + shared -> Agent#shared_skill_dir
  # - skill + own    -> the Agent's config-dir skill location
  # - agent + own    -> the Agent's config-dir agent location
  #
  # `agent + shared` is not a valid build artifact. Deployer never examines
  # source metadata or recomputes scope.
  class Deployer
    # @return [Array<String>]
    SCOPES = %i[shared own].freeze

    # @param [AgentBase] agent supplies a deployment facet
    # @param [String] build_root forwarded to Collector.build
    def initialize(agent:, build_root:)
      @agent = agent
      @build_root = build_root
    end

    # @param [Boolean] force deploy even when the Agent product is not installed
    # @return [Array<Array(String, String)>] source and destination pairs
    def deploy(force: false)
      return skip_uninstalled_agent unless force || @agent.installed?

      SCOPES.flat_map { |scope|
        Collector.build(root: @build_root, agent: @agent, scope: scope).dirs.flat_map { |_pkg, type, dir|
          copy(dir, type, scope)
        }
      }
    end

    private

    def skip_uninstalled_agent
      warn "skipped deployment for uninstalled agent: #{@agent.name} (#{@agent.config_dir})"
      []
    end

    # @param [String] dir `<type>/` directory in the build tree
    # @param [String] type
    # @param [Symbol] scope
    # @return [Array<Array(String, String)>]
    def copy(dir, type, scope)
      Dir.children(dir).map { |entry|
        src = File.join(dir, entry)
        dest = File.join(@agent.deployment.destination(type, scope), entry)

        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.rm_rf(dest)
        FileUtils.cp_r(src, dest)

        [src, dest]
      }
    end
  end
end
