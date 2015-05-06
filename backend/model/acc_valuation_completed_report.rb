class AccValuationCompletedReport < AbstractAccValuationReport

  register_report({
                    :uri_suffix => "nla_valuation_completed",
                    :description => "Report on accessions where valuations are completed"
                  })

  def title
    "Accessions - Valuation Completed"
  end

  def headers
    super + ['Valuation Dates', 'Valuation Notes', 'Final Valuation Amount']
  end

  def processor
    super.merge({
      'Valuation Dates' => proc{|record| "TODO"},
      'Valuation Notes' => proc{|record| "TODO"},
      'Final Valuation Amount' => proc{|record| "TODO"}
    })
  end

  def query(db)
    dataset = super

    dataset.where(Sequel.qualify(:enumvals_valuation_status, :value) => 'completed')
  end
end