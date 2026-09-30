module SimpleAgentExtension
  module AgentProperty
    # The area several targets read, and the shared shape of a skill's
    # metadata.
    #
    # Skills live in the shared area until a target needs something of its
    # own lowered into them; at that point compile sends them to +own+.
    module Skill
      def skill_shared?
        true
      end

      def skill_destination(scope)
        case scope
        when :shared then shared_skill_dir
        when :own then File.join(config_dir, "skills")
        else raise KeyError, "skill has no #{scope} destination"
        end
      end

      # @param [String] extension_name
      # @param [String] source_file
      # @return [String] core file relative to the artifact type directory
      def skill_core_file(extension_name:, source_file:)
        File.join(extension_name, source_file)
      end
    end
  end
end
