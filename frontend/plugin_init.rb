Rails.application.config.after_initialize do

  SearchResultData.class_eval do
    self.singleton_class.send(:alias_method, :BASE_FACETS_pre_component_report, :BASE_FACETS)
    def self.BASE_FACETS
      self.BASE_FACETS_pre_component_report << "level"
    end
  end

end