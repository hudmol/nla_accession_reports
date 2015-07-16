class WorkPlanDevelopmentReport < AbstractReport

  register_report({
                    :uri_suffix => "nla_work_plan_development",
                    :description => "Work Plan Development Report",
                    :params => [
                      ["processing_status", String, "Processing Status", {
                        optional: false,
                        validation: [
                          "Must be one of #{BackendEnumSource.values_for("collection_management_processing_status").join(", ")}",
                          ->(v){ BackendEnumSource.valid?("collection_management_processing_status", v) }
                        ],
                        :enumeration => "collection_management_processing_status"
                      }]
                    ]
                  })

  def initialize(params)
    super
    @processing_status = params[:processing_status] != "" ? params[:processing_status] : nil
  end

  def title
    "Accessions - Work Plan Development"
  end

  def headers
    ['Accession No', 'Title', 'Arrival Date', 'Extent', "Container Summary", "Inventory", "Acq Method", "Processing Status", "Processing Plan", "Processing Notes", "Processors", "Accessioning Priority", "Valuation Status"]
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
      'Container Summary' => proc{|record| record[:extent_container_summary] || ""},
      'Inventory' => proc{|record| record[:inventory]},
      'Acq Method' => proc{|record|
        if record[:acquisition_type]
          I18n.t("enumerations.accession_acquisition_type.#{record[:acquisition_type]}", :default => record[:acquisition_type])
        else
          ""
        end
      },
      'Processing Status' => proc{|record| I18n.t("enumerations.collection_management_processing_status.#{@processing_status}", :default => @processing_status)},
      'Processing Plan' => proc{|record| record[:processing_plan]},
      'Processing Notes' => proc{|record| record[:processing_notes]},
      'Processors' => proc{|record| record[:processors]},
      'Accessioning Priority' => proc{|record|
        if record[:accessioning_priority]
          I18n.t("enumerations.collection_management_processing_priority.#{record[:accessioning_priority]}", :default => record[:accessioning_priority])
        else
          ""
        end
      },
      'Valuation Status' => proc{|record| record[:valuation_status]}
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
      join(:enumeration,
           {
             :name => 'collection_management_processing_status'
           },
           {
             :table_alias => :enum_processing_status
           }).
      join(:enumeration,
           {
             :name => 'collection_management_processing_priority'
           },
           {
             :table_alias => :enum_processing_priority
           }).
      join(:enumeration,
           {
             :name => 'user_defined_enum_1'
           },
           {
             :table_alias => :enum_valuation_status
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
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_processing_status, :enumeration_id) =>  Sequel.qualify(:enum_processing_status, :id),
                        Sequel.qualify(:collection_management, :processing_status_id) => Sequel.qualify(:enumvals_processing_status, :id),
                      },
                      {
                        :table_alias => :enumvals_processing_status
                      }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_processing_priority, :enumeration_id) =>  Sequel.qualify(:enum_processing_priority, :id),
                        Sequel.qualify(:collection_management, :processing_priority_id) => Sequel.qualify(:enumvals_processing_priority, :id),
                      },
                      {
                        :table_alias => :enumvals_processing_priority
                      }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_valuation_status, :enumeration_id) =>  Sequel.qualify(:enum_valuation_status, :id),
                        Sequel.qualify(:user_defined, :enum_1_id) => Sequel.qualify(:enumvals_valuation_status, :id),
                      },
                      {
                        :table_alias => :enumvals_valuation_status
                      }).
      select(
      Sequel.qualify(:accession, :id),
      Sequel.qualify(:accession, :identifier),
      Sequel.qualify(:accession, :title),
      Sequel.qualify(:accession, :content_description),
      Sequel.qualify(:accession, :inventory),
      Sequel.qualify(:accession, :accession_date),
      Sequel.qualify(:accession, :retention_rule).as(:processing_notes),
      Sequel.qualify(:enumvals_acquisition_type, :value).as(:acquisition_type),
      Sequel.qualify(:extent, :number).as(:extent_number),
      Sequel.qualify(:extent, :container_summary).as(:extent_container_summary),
      Sequel.qualify(:enumvals_extent_type, :value).as(:extent_type),
      Sequel.qualify(:collection_management, :processing_plan).as(:processing_plan),
      Sequel.qualify(:collection_management, :processors).as(:processors),
      Sequel.qualify(:enumvals_processing_status, :value).as(:processing_status),
      Sequel.qualify(:enumvals_processing_priority, :value).as(:accessioning_priority),
      Sequel.qualify(:enumvals_valuation_status, :value).as(:valuation_status),
    )

    dataset = dataset.where(Sequel.qualify(:accession, :repo_id) => @repo_id) if @repo_id
    dataset = dataset.where(Sequel.qualify(:enumvals_processing_status, :value) => @processing_status) if @processing_status

    dataset.distinct(:id).order_by(Sequel.asc(:identifier), Sequel.asc(:title))
  end

end
