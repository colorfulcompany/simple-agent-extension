require "fileutils"
require "tmpdir"

module Fixture
  module_function

  ROOT = File.expand_path("fixtures", __dir__)
  TMP_ROOT = File.expand_path("tmp", __dir__)

  class Workspace
    attr_reader :root

    def initialize
      FileUtils.mkdir_p(TMP_ROOT)
      @root = Dir.mktmpdir("sae-test-", TMP_ROOT)
    end

    def source_root
      File.join(root, "source")
    end

    def build_root
      File.join(root, "build")
    end

    def close
      FileUtils.rm_rf(root)
    end
  end

  # @yield [String] workspace containing `source/` and `build/`
  def valid_workspace
    if block_given?
      workspace do |dir|
        copy("valid-packages", to: source_root(dir))
        yield dir
      end
    else
      context = workspace
      copy("valid-packages", to: context.source_root)
      context
    end
  rescue
    context&.close
    raise
  end

  # @yield [String] workspace containing `source/` and `build/`
  def invalid_workspace
    if block_given?
      workspace do |dir|
        copy("invalid-packages", to: source_root(dir))
        yield dir
      end
    else
      context = workspace
      copy("invalid-packages", to: context.source_root)
      context
    end
  rescue
    context&.close
    raise
  end

  # @yield [String] workspace containing `source/` and `build/`
  def deploy_to_workspace
    if block_given?
      workspace do |dir|
        copy("deploy-to-packages", to: source_root(dir))
        yield dir
      end
    else
      context = workspace
      copy("deploy-to-packages", to: context.source_root)
      context
    end
  rescue
    context&.close
    raise
  end

  # @yield [String] workspace containing the selected `build/` tree
  def build_workspace(name)
    if block_given?
      workspace do |dir|
        copy(File.join("build-trees", name), to: build_root(dir))
        yield dir
      end
    else
      context = workspace
      copy(File.join("build-trees", name), to: context.build_root)
      context
    end
  rescue
    context&.close
    raise
  end

  def source_root(workspace)
    File.join(workspace, "source")
  end

  def build_root(workspace)
    File.join(workspace, "build")
  end

  def build_path(workspace, *parts)
    File.join(build_root(workspace), *parts.map(&:to_s))
  end

  def copy(name, to:)
    FileUtils.mkdir_p(to)
    FileUtils.cp_r(File.join(ROOT, name, "."), to)
  end

  def workspace
    context = Workspace.new
    return context unless block_given?

    yield context.root
  ensure
    context&.close if block_given?
  end
end
