class CommonIndexer
  add_attribute_to_resolve('resource')
  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook {|doc, record|
    if record['record']['jsonmodel_type'] == 'archival_object'
      
      resource = record['record']['resource']['_resolved']
      
      ao_restrictions = record['record']['restrictions_apply']

      doc['total_restrictions_u_sstr'] = ao_restrictions

      call_number = (0..3).map{|i| resource["id_#{i}"]}.compact.join(".")
      
      doc['resource_identifier_u_sstr'] = call_number
      
      if resource['user_defined'] && resource['user_defined']['enum_1']
        catalog_location_match(call_number,resource['user_defined']['enum_1'])
        doc['resource_type_u_sstr'] = @type_string
        doc['resource_type_u_sort'] = @type_sort
        rauner_type = @type_string
      end
      
      # add in the call number and location type to json so that we can search for these and get everything in the resource
      # also remove the resolved resource data so that we don't get inflated result sets
      old_json = JSON.parse(doc['json'])
      old_json[:resource_identifier_u_sstr] = call_number
      old_json[:resource_type_u_sstr] = rauner_type
      old_json['resource']['_resolved'] = ''
      doc['json'] = old_json.to_json
      
      doc['resource_title_u_sstr'] = resource['title']
      doc['resource_identifier_u_sort'] = (0..3).map{|i| (resource["id_#{i}"] || "").to_s.rjust(25, '#')}.join

    end
    }
    indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'resource'
        resource_restrictions = record['record']['restrictions']
        doc['total_restrictions_u_sstr'] = resource_restrictions
        
        call_number = (0..3).map{|i| record["record"]["id_#{i}"]}.compact.join(".")
        doc['resource_identifier_u_sstr'] = call_number
        doc['resource_identifier_u_sort'] = (0..3).map{|i| (record["record"]["id_#{i}"] || "").to_s.rjust(25, '#')}.join
        
        if (record['record']['user_defined'] && record['record']['user_defined']['enum_1'])
          cat_loc = record['record']['user_defined']['enum_1']
          
          catalog_location_match(call_number,cat_loc)
          doc['resource_type_u_sstr'] = @type_string
          doc['resource_type_u_sort'] = @type_sort
        end
      end
    }
    indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'accession'
        accession_number = (0..3).map{|i| record["record"]["id_#{i}"]}.compact.join("-")
        unless record['record']['display_string'] == accession_number
            doc['title'] += "; #{accession_number}"
        end
      end
    }
  end
  
  def self.catalog_location_match (call_number,cat_loc)
    # regexes for various types    
    manuscripts = [/wman/i,/wmst/i,/wmeb/i,/wmfr/i,/wmme/i,/wmnc/i,/wmwe/i,/wlan/i,/wmru/i,/wmebb/i,/wmmc/i]
    regmss = Regexp.union(manuscripts)
    
    iconography = [/wraui/i]
    regicon = Regexp.union(iconography)
    
    realia = [/wraue/i]
    regrealia = Regexp.union(realia)
    
    av = [/wraur/i,/wrauc/i,/wrauu/i,/wraup/i,/wraua/i,/wrauk/i,/wrauv/i]
    regav = Regexp.union(av)
    
    if cat_loc.match(regmss)
      if call_number.start_with?('d','D')
        @type_string = 'Archives'
        @type_sort = 'archival'
      else
        @type_string = 'Manuscript'
        @type_sort = 'manuscript'
      end
    elsif cat_loc.match(regicon)
      @type_string = 'Iconography'
      @type_sort = 'iconography'
    elsif cat_loc.match(regrealia)
      @type_string = 'Realia'
      @type_sort = 'realia'
    elsif cat_loc.match(regav)
      @type_string = 'Audio/Visual'
      @type_sort = 'audiovisual'
    else
      @type_string = 'Printed Material'
      @type_sort = 'printed'
    end
    return @type_string, @type_sort
  end
end