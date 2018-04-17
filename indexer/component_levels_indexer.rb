 require 'aspace_logger'
class IndexerCommon
  add_attribute_to_resolve('resource')
  add_indexer_initialize_hook do |indexer|
    #logger=Logger.new($stderr)
    indexer.add_document_prepare_hook {|doc, record|
    if record['record']['jsonmodel_type'] == 'archival_object'
      
      
      resource = record['record']['resource']['_resolved']
      
      ## removed since we will make it policy to restrict actual AOs, rather than relying on cascade information
      ## as this causes a *high* indexer overhead. This functionality will be enhanced via plugin to allow staff
      ## the ability to restrict all children of an AO.
      #resource_restrictions = resource['restrictions']
      #ao_restrictions = false
      #parent_uri = record['record']['parent'] ? record['record']['parent']['ref'] : ''

      ao_restrictions = record['record']['restrictions_apply']
      
      ## see note above
      #if resource_restrictions
      #  ao_restrictions = true
      #else
      #  unless ao_restrictions
      #    until parent_uri.nil? || parent_uri.empty?
      #      ao_restrictions = JSONModel::HTTP.get_json(parent_uri)['restrictions_apply']                
      #      break if ao_restrictions
      #      parent_uri = JSONModel::HTTP.get_json(parent_uri)['parent'] ? JSONModel::HTTP.get_json(parent_uri)['parent']['ref'] : ''
      #    end
      #  end
      #end

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
      old_json[:resource_title] = resource['title']
      
      # location facets
      # TODO: investigate why this fails to correctly index all records on initial index, but when edits are made and saved, *then* indexes the object correctly.
      # No errors observed on initial index, so prehaps this is some sort of race condition - though not sure how or why.
      #instances = old_json['instances']
      #
      #if instances.empty?
      #  if old_json['parent'] && old_json['parent']['ref']
      #    instances = parent_location(old_json['parent']['ref']) ? parent_location(old_json['parent']['ref']) : []
      #  end
      #end
      #
      #unless instances.empty?
      #  building_and_area(instances)
      #  unless @building.empty?
      #    doc['building_u_sstr'] = @building
      #  end
      #end
      
      old_json['resource']['_resolved'] = ''
      doc['json'] = old_json.to_json
      
      doc['resource_title_u_sstr'] = resource['title']
      doc['resource_identifier_u_sort'] = (0..3).map{|i| (resource["id_#{i}"] || "").to_s.rjust(25, '#')}.join
      doc['resource_identifier_w_title_u_sstr'] = call_number + ": " + resource['title']
    end
    }
    indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'resource'
        resource_restrictions = record['record']['restrictions']
        doc['total_restrictions_u_sstr'] = resource_restrictions
        
        call_number = (0..3).map{|i| record["record"]["id_#{i}"]}.compact.join(".")
        doc['resource_identifier_u_sstr'] = call_number
        doc['resource_identifier_u_sort'] = (0..3).map{|i| (record["record"]["id_#{i}"] || "").to_s.rjust(25, '#')}.join
        doc['resource_identifier_w_title_u_sstr'] = call_number + ": " + record['record']['title']

        if (record['record']['user_defined'] && record['record']['user_defined']['enum_1'])
          cat_loc = record['record']['user_defined']['enum_1']
          
          catalog_location_match(call_number,cat_loc)
          doc['resource_type_u_sstr'] = @type_string
          doc['resource_type_u_sort'] = @type_sort
        end
        
        #old_json = JSON.parse(doc['json'])
      
        # location facets
        #instances = old_json['instances']
        #unless instances.empty?
        #  building_and_area(instances)
        #  unless @building.empty?
        #    doc['building_u_sstr'] = @building
        #  end
        #end        
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
    manuscripts = [/wman/i,/wmst/i,/wmeb/i,/wmfr/i,/wmme/i,/wmnc/i,/wmwe/i,/wlan/i,/wmru/i,/wmebb/i,/wmmc/i,/waccc/i]
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
  
  # TODO: See above note about indexer and intial pass vs subsequent
  
  #def self.parent_location(uri)
  #  ao = JSONModel::HTTP.get_json(uri)
  #  
  #  if ao['instances'].empty?
  #    if ao['parent'] && ao['parent']['ref']
  #      parent_location(ao['parent']['ref'])
  #    end
  #  else
  #    return ao['instances']
  #  end
  #end
  #
  #def self.building_and_area(instances)
  #
  #  offsite = [/records/i, /maine/i ]
  #  regoffsite = Regexp.union(offsite)
  #  
  #  @building = 'No Location'
  #  
  #  instances.each do |instance|
  #
  #    if instance.dig('sub_container','top_container','_resolved','container_locations')
  #      #if instance['sub_container'] && instance['sub_container']['top_container'] && instance['sub_container']['top_container']['_resolved'] && instance['sub_container']['top_container']['_resolved']['container_locations']
  #      locations = instance['sub_container']['top_container']['_resolved']['container_locations']
  #      
  #    elsif instance.dig('sub_container','top_container','ref')
  #      tc = JSONModel::HTTP.get_json(instance['sub_container']['top_container']['ref'])
  #      locations = tc['container_locations']
  #    end
  #    
  #    unless locations.empty?
  #      location = locations.select { |cl| cl['status'] == 'current' }.first
  #    
  #      if location && location['ref']
  #        location_obj = JSONModel::HTTP.get_json(location['ref'])
  #        if location_obj && location_obj['building']
  #          if location_obj['building'].match(regoffsite)
  #            @building = 'Offsite'
  #          else
  #            @building = 'Onsite'
  #          end
  #        end
  #      end
  #    end
  #  end
  #  return @building
  #end
  
end