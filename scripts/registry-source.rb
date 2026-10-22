# frozen_string_literal: true

require "pathname"

module RegistrySource
  RELATION_ROOTS = %w[registry/rels registry/relations].freeze

  def self.import_roots(source_root)
    source_root = Pathname(source_root)
    relation_roots = RELATION_ROOTS.select { |root| source_root.join(root).exist? }
    unless relation_roots.one?
      abort "Registry checkout must contain exactly one relation directory: registry/rels or registry/relations"
    end

    relation_root = relation_roots.first
    unless source_root.join("registry/profiles/README.md").file? &&
           source_root.join(relation_root, "README.md").file?
      abort "Registry checkout must contain registry/profiles/README.md and #{relation_root}/README.md"
    end

    { "registry/profiles" => "/profiles/", relation_root => "/rels/" }
  end
end
