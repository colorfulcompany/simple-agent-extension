require "spec_helper"
require "simple_agent_extension"
require "support/testing_metadata_translators"

module SimpleAgentExtension
  describe AgentProperty::MetadataTranslator do
    describe "#can_translate?" do
      before { @translator = TestingMetadataTranslatorReturnNil.new }
      after { @translator = nil }

      it "respondable" do
        assert {
          @translator.can_translate?(type: :agent, field: "name")
        }
      end

      it "wrong type is not respondable" do
        assert {
          !@translator.can_translate?(type: :skill, field: "name")
        }
      end

      it "not respondable" do
        assert {
          !@translator.can_translate?(type: :agent, field: "notexist")
        }
      end
    end

    describe TestingMetadataTranslatorOverrideValueOnly do
      before {
        @translator = TestingMetadataTranslatorOverrideValueOnly.new
        @result = @translator.translate(type: :agent, field: "model", value: "great-model")
      }
      after {
        @translator = nil
        @result = nil
      }

      it "same field" do
        assert {
          @result.keys.first == "model"
        }
      end

      it "different value" do
        assert {
          @result.values.first != "great-model"
        }
      end
    end

    describe TestingMetadataTranslatorOverrideFieldAndValue do
      before {
        @translator = TestingMetadataTranslatorOverrideFieldAndValue.new
        @result = @translator.translate(
          type: :agent,
          field: "permissions",
          value: {"read" => "allow", "search" => "ask"}
        )
      }

      it "different field" do
        assert {
          @result.keys.first != "permissions"
        }
      end

      it "different value" do
        assert {
          @result.values.first.is_a? Array
        }
      end

      it "only read ( specific logic )" do
        assert {
          @result.values.first == ["read"]
        }
      end
    end

    describe TestingMetadataTranslatorReturnNil do
      before { @translator = TestingMetadataTranslatorReturnNil.new }
      after { @translator = nil }

      it "return nil" do
        assert {
          @translator.translate(type: :agent, field: "name", value: "my-agent").nil?
        }
      end

      it "raises for an unknown type and field combination" do
        assert_raises(AgentProperty::MetadataTranslator::UnknownTypeAndFieldCombination) do
          @translator.translate(type: :skill, field: "name", value: "my-skill")
        end
      end
    end
  end
end
