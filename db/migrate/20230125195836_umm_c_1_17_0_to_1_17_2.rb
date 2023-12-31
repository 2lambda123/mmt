class UmmC1170To1172 < ActiveRecord::Migration[5.2]
  def up
    metadata_specification = {
      'URL' => "https://cdn.earthdata.nasa.gov/umm/collection/v1.17.2",
      'Name' => "UMM-C",
      'Version' => "1.17.2"
    }
    collection_drafts = CollectionDraft.where.not(draft: {})
    proposals = CollectionDraftProposal.where.not(draft: {})
    templates = CollectionTemplate.where.not(draft: {})
    records = collection_drafts + proposals + templates

    records.each do |record|
      draft = record.draft
      if draft['MetadataSpecification'].present?
        draft['MetadataSpecification'] = metadata_specification
        record.save
      end
    end

  end

  def down
    metadata_specification = {
      'URL' => "https://cdn.earthdata.nasa.gov/umm/collection/v1.17.0",
      'Name' => "UMM-C",
      'Version' => "1.17.0"
    }
    collection_drafts = CollectionDraft.where.not(draft: {})
    proposals = CollectionDraftProposal.where.not(draft: {})
    templates = CollectionTemplate.where.not(draft: {})
    records = collection_drafts + proposals + templates

    records.each do |record|
      draft = record.draft

      # Rollback MetadataSpecification Version
      draft['MetadataSpecification'] = metadata_specification

      # Removes EULA Identifier
      if draft['UseConstraints'].present?
        unless draft['UseConstraints']['EulaIdentifiers'].nil?
          draft['UseConstraints'].delete('EulaIdentifiers')
        end
      end

      # Removes TilingIdentificationSystems if there is a Military Grid Reference System enum present
      if draft['TilingIdentificationSystems'].present?
        draft['TilingIdentificationSystems'].delete_if { |system| system['TilingIdentificationSystemName'] == 'Military Grid Reference System' }
      end
      record.save
      puts(record.draft)
    end
  end
end
