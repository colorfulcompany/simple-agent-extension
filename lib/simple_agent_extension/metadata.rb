module SimpleAgentExtension
  # A metadata mapping that retains its type through Hash#merge.
  #
  # ```yaml
  # name: <- Top-Level Special FIELD
  #
  # adaptive: <- SECTION whose artifact representation is determined by Agent
  #   permissions: <- FIELD |
  #     read: allow           | <- FRAGMENT
  #     ...                   |
  #
  # static: <- SECTION used without Agent adaptation
  #   common: <- 2nd level SECTION
  #   agents:
  #     Agent A:
  #       ..
  #     Agent B:
  #       ..
  #
  # ```
  #
  class Metadata < Hash
    def self.from(hash)
      new.merge(hash)
    end
  end
end
