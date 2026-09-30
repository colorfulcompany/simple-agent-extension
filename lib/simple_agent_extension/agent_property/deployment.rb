module SimpleAgentExtension
  module AgentProperty
    # Target-specific destinations for already compiled build artifacts.
    class Deployment
      def initialize(agent)
        @agent = agent
      end

      # @param [String, Symbol] type
      # @return [Boolean]
      def shared?(type)
        @agent.public_send("#{type}_shared?")
      end

      # @param [String, Symbol] type
      # @param [Symbol] scope
      # @return [String]
      def destination(type, scope)
        @agent.public_send("#{type}_destination", scope)
      end
    end
  end
end
