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
    ['Accession No', 'Title', 'Arrival Date', 'Extent', "Container Summary", "Inventory", "Acq Method", 'Disposition',
     "Processing Status", "Processing Plan", "Processing Notes", "Processors",
     "Accessioning Priority", "Valuation Status", 'New Collection?', 'PO/Holdings Record', 'RefTracker No.',
     'Digitisation Notes', 'Preservation Status',
     'Processed Event Outcome', 'Catalogued Event Outcome', 'Accession Event Outcome', 'Registration Event Outcome',
     'Acknowledgement Sent Event Outcome', 'Agreement Sent Event Outcome', 'Agreement Signed Event Outcome', 
     'Publication Event Outcome', 'Ingestion Event Outcome']
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
      'Disposition' => proc{|record| record[:disposition]},
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
      'Valuation Status' => proc{|record| record[:valuation_status]},
      'New Collection?' => proc{|record| record[:new_collection] == 1 ? 'Yes' : 'No'},
      'PO/Holdings Record' => proc{|record| record[:po_holdings_record] == 1 ? 'Yes' : 'No'},
      'RefTracker No.' => proc{|record| record[:reftracker_no]},
      'Digitisation Notes' => proc{|record| record[:digitisation_notes]},
      'Preservation Status' => proc{|record| record[:preservation_status]},
      'Processed Event Outcome' => proc{|record| record[:processed_outcome]},
      'Catalogued Event Outcome' => proc{|record| record[:cataloged_outcome]},
      'Accession Event Outcome' => proc{|record| record[:accession_outcome]},
      'Registration Event Outcome' => proc{|record| record[:registration_outcome]},
      'Acknowledgement Sent Event Outcome' => proc{|record| record[:acknowledgement_sent_outcome]},
      'Agreement Sent Event Outcome' => proc{|record| record[:agreement_sent_outcome]},
      'Agreement Signed Event Outcome' => proc{|record| record[:agreement_signed_outcome]},
      'Publication Event Outcome' => proc{|record| record[:publication_outcome]},
      'Ingestion Event Outcome' => proc{|record| record[:ingestion_outcome]},
    }
  end

  def scope_by_repo_id(dataset)
    # repo scope is applied in the query below
    dataset
  end

  def query(db)

    # save a bunch of joins by caching the ids for event_types
    event_types = {}
    db[:enumeration_value].
      join(:enumeration,
           {
             :id => Sequel.qualify(:enumeration_value, :enumeration_id),
             :name => "event_event_type"
           }).
      select(
             Sequel.qualify(:enumeration_value, :id),
             Sequel.qualify(:enumeration_value, :value)).
      all{|row| event_types[row[:value]] = row[:id]}

    dataset = db[:accession].
      left_outer_join(:user_defined, :accession_id =>  Sequel.qualify(:accession, :id)).
      left_outer_join(:collection_management, :accession_id => Sequel.qualify(:accession, :id)).
      left_outer_join(:extent, :accession_id => Sequel.qualify(:accession, :id)).

      left_outer_join(:event,
           {
             :id => (db[:event_link_rlshp].where(:accession_id => Sequel.qualify(:accession,:id)).select(:event_id)),
             :event_type_id => event_types['processed']
           },
           {
             :table_alias => :event_processed
           }).
      left_outer_join(:event,
           {
             :id => (db[:event_link_rlshp].where(:accession_id => Sequel.qualify(:accession, :id)).select(:event_id)),
             :event_type_id => event_types['cataloged']
           },
           {
             :table_alias => :event_cataloged
           }).
      left_outer_join(:event,
           {
             :id => (db[:event_link_rlshp].where(:accession_id => Sequel.qualify(:accession, :id)).select(:event_id)),
             :event_type_id => event_types['accession']
           },
           {
             :table_alias => :event_accession
           }).
      left_outer_join(:event,
           {
             :id => (db[:event_link_rlshp].where(:accession_id => Sequel.qualify(:accession, :id)).select(:event_id)),
             :event_type_id => event_types['registration']
           },
           {
             :table_alias => :event_registration
           }).
      left_outer_join(:event,
           {
             :id => (db[:event_link_rlshp].where(:accession_id => Sequel.qualify(:accession, :id)).select(:event_id)),
             :event_type_id => event_types['acknowledgement_sent']
           },
           {
             :table_alias => :event_acknowledgement_sent
           }).
      left_outer_join(:event,
           {
             :id => (db[:event_link_rlshp].where(:accession_id => Sequel.qualify(:accession, :id)).select(:event_id)),
             :event_type_id => event_types['agreement_sent']
           },
           {
             :table_alias => :event_agreement_sent
           }).
      left_outer_join(:event,
           {
             :id => (db[:event_link_rlshp].where(:accession_id => Sequel.qualify(:accession, :id)).select(:event_id)),
             :event_type_id => event_types['agreement_signed']
           },
           {
             :table_alias => :event_agreement_signed
           }).
      left_outer_join(:event,
           {
             :id => (db[:event_link_rlshp].where(:accession_id => Sequel.qualify(:accession, :id)).select(:event_id)),
             :event_type_id => event_types['publication']
           },
           {
             :table_alias => :event_publication
           }).
      left_outer_join(:event,
           {
             :id => (db[:event_link_rlshp].where(:accession_id => Sequel.qualify(:accession, :id)).select(:event_id)),
             :event_type_id => event_types['ingestion']
           },
           {
             :table_alias => :event_ingestion
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
      join(:enumeration,
           {
             :name => 'user_defined_enum_2'
           },
           {
             :table_alias => :enum_preservation_status
           }).
      join(:enumeration,
           {
             :name => 'event_outcome'
           },
           {
             :table_alias => :enum_event_outcome
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
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_preservation_status, :enumeration_id) =>  Sequel.qualify(:enum_preservation_status, :id),
                        Sequel.qualify(:user_defined, :enum_2_id) => Sequel.qualify(:enumvals_preservation_status, :id),
                      },
                      {
                        :table_alias => :enumvals_preservation_status
                      }).

      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_event_processed_outcome, :enumeration_id) =>  Sequel.qualify(:enum_event_outcome, :id),
                        Sequel.qualify(:event_processed, :outcome_id) => Sequel.qualify(:enumvals_event_processed_outcome, :id),
                      },
                      {
                        :table_alias => :enumvals_event_processed_outcome
                      }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_event_cataloged_outcome, :enumeration_id) =>  Sequel.qualify(:enum_event_outcome, :id),
                        Sequel.qualify(:event_cataloged, :outcome_id) => Sequel.qualify(:enumvals_event_cataloged_outcome, :id),
                      },
                      {
                        :table_alias => :enumvals_event_cataloged_outcome
                      }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_event_accession_outcome, :enumeration_id) =>  Sequel.qualify(:enum_event_outcome, :id),
                        Sequel.qualify(:event_accession, :outcome_id) => Sequel.qualify(:enumvals_event_accession_outcome, :id),
                      },
                      {
                        :table_alias => :enumvals_event_accession_outcome
                      }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_event_registration_outcome, :enumeration_id) =>  Sequel.qualify(:enum_event_outcome, :id),
                        Sequel.qualify(:event_registration, :outcome_id) => Sequel.qualify(:enumvals_event_registration_outcome, :id),
                      },
                      {
                        :table_alias => :enumvals_event_registration_outcome
                      }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_event_acknowledgement_sent_outcome, :enumeration_id) =>  Sequel.qualify(:enum_event_outcome, :id),
                        Sequel.qualify(:event_acknowledgement_sent, :outcome_id) => Sequel.qualify(:enumvals_event_acknowledgement_sent_outcome, :id),
                      },
                      {
                        :table_alias => :enumvals_event_acknowledgement_sent_outcome
                      }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_event_agreement_sent_outcome, :enumeration_id) =>  Sequel.qualify(:enum_event_outcome, :id),
                        Sequel.qualify(:event_agreement_sent, :outcome_id) => Sequel.qualify(:enumvals_event_agreement_sent_outcome, :id),
                      },
                      {
                        :table_alias => :enumvals_event_agreement_sent_outcome
                      }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_event_agreement_signed_outcome, :enumeration_id) =>  Sequel.qualify(:enum_event_outcome, :id),
                        Sequel.qualify(:event_agreement_signed, :outcome_id) => Sequel.qualify(:enumvals_event_agreement_signed_outcome, :id),
                      },
                      {
                        :table_alias => :enumvals_event_agreement_signed_outcome
                      }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_event_publication_outcome, :enumeration_id) =>  Sequel.qualify(:enum_event_outcome, :id),
                        Sequel.qualify(:event_publication, :outcome_id) => Sequel.qualify(:enumvals_event_publication_outcome, :id),
                      },
                      {
                        :table_alias => :enumvals_event_publication_outcome
                      }).
      left_outer_join(:enumeration_value,
                      {
                        Sequel.qualify(:enumvals_event_ingestion_outcome, :enumeration_id) =>  Sequel.qualify(:enum_event_outcome, :id),
                        Sequel.qualify(:event_ingestion, :outcome_id) => Sequel.qualify(:enumvals_event_ingestion_outcome, :id),
                      },
                      {
                        :table_alias => :enumvals_event_ingestion_outcome
                      }).

      select(
      Sequel.qualify(:accession, :id),
      Sequel.qualify(:accession, :identifier),
      Sequel.qualify(:accession, :title),
      Sequel.qualify(:accession, :content_description),
      Sequel.qualify(:accession, :inventory),
      Sequel.qualify(:accession, :accession_date),
      Sequel.qualify(:accession, :disposition),
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
      Sequel.qualify(:user_defined, :boolean_1).as(:new_collection),
      Sequel.qualify(:user_defined, :boolean_2).as(:po_holdings_record),
      Sequel.qualify(:user_defined, :string_2).as(:reftracker_no),
      Sequel.qualify(:user_defined, :text_5).as(:digitisation_notes),
      Sequel.qualify(:enumvals_preservation_status, :value).as(:preservation_status),
      Sequel.qualify(:enumvals_event_processed_outcome, :value).as(:processed_outcome),
      Sequel.qualify(:enumvals_event_cataloged_outcome, :value).as(:cataloged_outcome),
      Sequel.qualify(:enumvals_event_accession_outcome, :value).as(:accession_outcome),
      Sequel.qualify(:enumvals_event_registration_outcome, :value).as(:registration_outcome),
      Sequel.qualify(:enumvals_event_acknowledgement_sent_outcome, :value).as(:acknowledgement_sent_outcome),
      Sequel.qualify(:enumvals_event_agreement_sent_outcome, :value).as(:agreement_sent_outcome),
      Sequel.qualify(:enumvals_event_agreement_signed_outcome, :value).as(:agreement_signed_outcome),
      Sequel.qualify(:enumvals_event_publication_outcome, :value).as(:publication_outcome),
      Sequel.qualify(:enumvals_event_ingestion_outcome, :value).as(:ingestion_outcome),
    )

    dataset = dataset.where(Sequel.qualify(:accession, :repo_id) => @repo_id) if @repo_id
    dataset = dataset.where(Sequel.qualify(:enumvals_processing_status, :value) => @processing_status) if @processing_status

    dataset.distinct(:id).order_by(Sequel.asc(:identifier), Sequel.asc(:title))
  end

end
