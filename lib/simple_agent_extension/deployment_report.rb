module SimpleAgentExtension
  # Renders `Runner#deploy` results for humans: an Agent heading, then one
  # line per deployed extension rather than per file.
  #
  #   opencode
  #     deep-review/agent -> ~/.config/opencode/agents
  #     deep-review/skill -> ~/.agents/skills
  #
  # The `<package>/<type>` label comes from the build tree, so the Agent
  # specific filename an extension was compiled into never shows up here.
  class DeploymentReport
    INDENT = "  "

    # @param [Hash{String => Array<Array(String, String)>}] deployments
    #   source and destination pairs per Agent name
    # @param [String] home replaced by `~` in displayed destinations
    def initialize(deployments, home: Dir.home)
      @deployments = deployments
      @home = home
    end

    # @return [Array<String>]
    def lines
      @deployments.flat_map { |agent_name, pairs| [agent_name, *extension_lines(pairs)] }
    end

    private

    def extension_lines(pairs)
      pairs.map { |source, destination|
        "#{INDENT}#{extension_label(source)} -> #{shorten(File.dirname(destination))}"
      }.uniq
    end

    # @param [String] source `.../<package>/<type>/<entry>` in the build tree
    # @return [String]
    def extension_label(source)
      File.split(File.dirname(source)).map { |part| File.basename(part) }.join("/")
    end

    # Destinations are directories under an Agent's config or shared skill
    # root, so home itself is never one of them.
    #
    # @param [String] path absolute destination directory
    # @return [String]
    def shorten(path)
      return path unless path.start_with?("#{@home}/")

      path.sub(@home, "~")
    end
  end
end
