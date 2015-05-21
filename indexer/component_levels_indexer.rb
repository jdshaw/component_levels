class CommonIndexer
  add_attribute_to_resolve('resource')

  add_indexer_initialize_hook do |indexer|
    indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'archival_object'
        resource = record['record']['resource']['_resolved']
        doc['resource_identifier_u_sstr'] = (0..3).map{|i| resource["id_#{i}"]}.compact.join(".")
        doc['resource_title_u_sstr'] = resource['title']
        doc['resource_identifier_u_sort'] = (0..3).map{|i| (resource["id_#{i}"] || "").to_s.rjust(25, '#')}.join
      end
    }
  end
end