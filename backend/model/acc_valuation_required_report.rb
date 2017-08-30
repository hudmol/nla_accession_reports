class AccValuationRequiredReport < AbstractAccValuationReport

  register_report

  VALUATION_STATUS_REQUIRED = 'Valuation Required'


  def title
    "Accessions - Valuation Required"
  end

  def query
    dataset = super

    dataset.where(Sequel.qualify(:enumvals_valuation_status, :value) => VALUATION_STATUS_REQUIRED)
  end
end
