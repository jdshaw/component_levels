class SearchResultData

  alias old_facet_label_string facet_label_string

  def facet_label_string(facet_group, facet)

    if facet_group === "enum_1_enum_s"
      return I18n.t({:enumeration => 'user_defined_enum_1', :value => facet.to_s}, :default => facet)
    end
    old_facet_label_string(facet_group, facet)
  end
end