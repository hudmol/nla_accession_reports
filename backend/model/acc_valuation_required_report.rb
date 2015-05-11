class AccValuationRequiredReport < AbstractAccValuationReport

  register_report({
                    :uri_suffix => "nla_valuation_required",
                    :description => "Report on accessions where valuations are required"
                  })


  VALUATION_STATUS_REQUIRED = 'Valuation Required'


  def title
    "Accessions - Valuation Required"
  end

  def query(db)
    dataset = super

    dataset.where(Sequel.qualify(:enumvals_valuation_status, :value) => VALUATION_STATUS_REQUIRED)
  end
end