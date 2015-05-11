class AbstractAccValuationReport < AbstractReport

  def headers
    ['Identifier', 'Title', 'Arrival Date', 'Extent', "Description", "Inventory", "Acq Method", "Processing Notes", "Valuation Notes"]
  end

  def processor
    {
      'Identifier' => proc {|record| ASUtils.json_parse(record[:identifier] || "[]").compact.join("-")},
      'Title' => proc{|record| record[:title]},
      'Arrival Date' => proc{|record| record[:accession_date]},
      'Extent' => proc{|record|
        if record[:extent_number]
          "#{record[:extent_number]} #{I18n.t("enumerations.extent_extent_type.#{record[:extent_type]}", :default => record[:extent_type])}"
        else
          ""
        end
      },
      'Description' => proc{|record| record[:content_description]},
      'Inventory' => proc{|record| record[:inventory]},
      'Acq Method' => proc{|record| I18n.t("enumerations.accession_acquisition_type.#{record[:acquisition_type]}", :default => record[:acquisition_type])},
      'Processing Notes' => proc{|record| record[:processing_notes]},
      'Valuation Notes' => proc{|record| record[:valuation_notes]}
    }
  end

  def scope_by_repo_id(dataset)
    # repo scope is applied in the query below
    dataset
  end

  def query(db)
    dataset = db[:accession].
      left_outer_join(:user_defined, :accession_id =>  Sequel.qualify(:accession, :id)).
      left_outer_join(:collection_management, :accession_id => Sequel.qualify(:accession, :id)).
      left_outer_join(:extent, :accession_id => Sequel.qualify(:accession, :id)).
      join(:enumeration,
           {
             :name => 'user_defined_enum_1'
           },
           {
             :table_alias => :enum_valuation_status
           }).
      join(:enumeration,
           {
             :name => 'accession_acquisition_type'
           },
           {
             :table_alias => :enum_acquisition_type
           }).
      join(:enumeration,
           {
             :name => 'extent_extent_type'
           },
           {
             :table_alias => :enum_extent_type
           }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_valuation_status, :enumeration_id) =>  Sequel.qualify(:enum_valuation_status, :id),
                        Sequel.qualify(:user_defined, :enum_1_id) => Sequel.qualify(:enumvals_valuation_status, :id),
                      },
                      {
                        :table_alias => :enumvals_valuation_status
                      }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_acquisition_type, :enumeration_id) =>  Sequel.qualify(:enum_acquisition_type, :id),
                        Sequel.qualify(:accession, :acquisition_type_id) => Sequel.qualify(:enumvals_acquisition_type, :id),
                      },
                      {
                        :table_alias => :enumvals_acquisition_type
                      }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_extent_type, :enumeration_id) =>  Sequel.qualify(:enum_extent_type, :id),
                        Sequel.qualify(:extent, :extent_type_id) => Sequel.qualify(:enumvals_extent_type, :id),
                      },
                      {
                        :table_alias => :enumvals_extent_type
                      }).
      select(
        Sequel.qualify(:accession, :id),
        Sequel.qualify(:accession, :identifier),
        Sequel.qualify(:accession, :title),
        Sequel.qualify(:accession, :content_description),
        Sequel.qualify(:accession, :inventory),
        Sequel.qualify(:accession, :accession_date),
        Sequel.qualify(:accession, :retention_rule).as(:processing_notes),
        Sequel.qualify(:enumvals_valuation_status, :value).as(:valuation_status),
        Sequel.qualify(:enumvals_acquisition_type, :value).as(:acquisition_type),
        Sequel.qualify(:extent, :number).as(:extent_number),
        Sequel.qualify(:user_defined, :text_1).as(:valuation_notes),
        Sequel.qualify(:user_defined, :date_1).as(:valuation_completed_date),
        Sequel.qualify(:user_defined, :real_3).as(:valuation_final_amount),
        Sequel.qualify(:enumvals_extent_type, :value).as(:extent_type)
      )

    dataset = dataset.where(Sequel.qualify(:accession, :repo_id) => @repo_id) if @repo_id

    dataset.distinct(:id).order_by(Sequel.asc(:identifier), Sequel.asc(:title))
  end
end