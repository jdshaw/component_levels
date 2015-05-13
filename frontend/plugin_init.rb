Rails.application.config.after_initialize do

  SearchResultData.class_eval do
    self.singleton_class.send(:alias_method, :BASE_FACETS_pre_component_report, :BASE_FACETS)
    def self.BASE_FACETS
      self.BASE_FACETS_pre_component_report << "level"
    end
  end


  ApplicationController.class_eval do
    include SearchHelper

    def add_level_column_to_results_listing
      add_column("Level",
                 proc {|record| I18n.t("enumerations.archival_record_level.#{record['level']}", :default => record['level'])},
                 {
                   :sortable => true,
                   :sort_by => 'level'
                 })
    end
  end


  SearchController.class_eval do
    alias_method :advanced_search_pre_component_levels, :advanced_search
    def advanced_search
      @component_levels_level_column_supported = true
      advanced_search_pre_component_levels
    end

    alias_method :do_search_pre_component_levels, :do_search
    def do_search
      @component_levels_level_column_supported = true
      do_search_pre_component_levels
    end

    private

    # We need to add the column in render to be sure
    # the column is added post initialising @search_data
    # and prior to rendering the template.
    def render(*args)
      add_level_column_to_results_listing if @component_levels_level_column_supported && show_level_column?
      super
    end


    def show_level_column?
      (ASUtils.wrap(@search_data.types).empty? ||
        @search_data.types.include?("archival_object")) &&
      (!@search_data.filtered_terms? ||
        @search_data[:criteria]["filter_term[]"].select{|filter| filter =~ /primary_type/ }.all?{|filter| filter =~ /archival_object/ })
    end
  end


  ResourcesController.class_eval do
    alias_method :index_pre_component_levels, :index
    def index
      index_pre_component_levels
      add_level_column_to_results_listing if show_level_column?
    end

    private

    def show_level_column?
      params[:include_components]==="true"
    end
  end
end