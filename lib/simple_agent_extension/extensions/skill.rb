module SimpleAgentExtension
  module Extensions
    class Skill < Base
      # @return [String]
      def entrypoint
        "SKILL.md"
      end
    end
  end
end
