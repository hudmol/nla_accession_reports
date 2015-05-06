class WorkPlanDevelopmentReport < AbstractReport

  register_report({
                    :uri_suffix => "nla_work_plan_development",
                    :description => "Work Plan Development Report",

                  })

  def title
    "Accessions - Work Plan Development"
  end

  def headers
    ['Accession No', 'Title', 'Arrival Date', 'Extent', "Inventory", "Acq Method", "Processing Plan", "Accessioning Priority"]
  end

  def processor
    {
      'Accession No' => proc {|record| ASUtils.json_parse(record[:identifier] || "[]").compact.join("-")},
      'Title' => proc{|record| record[:title]},
      'Arrival Date' => proc{|record| record[:accession_date]},
      'Extent' => proc{|record|
        if record[:extent_number]
          "#{record[:extent_number]} #{I18n.t("enumerations.extent_extent_type.#{record[:extent_type]}", :default => record[:extent_type])}"
        else
          ""
        end
      },
      'Inventory' => proc{|record| record[:inventory]},
      'Acq Method' => proc{|record| I18n.t("enumerations.accession_acquisition_type.#{record[:acquisition_type]}", :default => record[:acquisition_type])},
      'Processing Plan' => proc{|record| record[:processing_plan]},
      'Accessioning Priority' => proc{|record| record[:accessioning_priority]},
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
      Sequel.qualify(:collection_management, :cataloged_note),
      Sequel.qualify(:enumvals_acquisition_type, :value).as(:acquisition_type),
      Sequel.qualify(:extent, :number).as(:extent_number),
      Sequel.qualify(:enumvals_extent_type, :value).as(:extent_type)
    )

    dataset = dataset.where(Sequel.qualify(:accession, :repo_id) => @repo_id) if @repo_id

    dataset.distinct(:id).order_by(Sequel.asc(:identifier), Sequel.asc(:title))
  end

end