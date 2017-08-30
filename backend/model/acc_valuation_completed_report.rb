class AccValuationCompletedReport < AbstractAccValuationReport

  register_report

  VALUATION_STATUS_COMPLETED = 'Valuation Complete'


  def title
    "Accessions - Valuation Complete"
  end

  def headers
    super.reject{|h| h == 'Processing Notes'} + ['Valuation Date', 'Final Valuation Amount']
  end

  def processor
    super.merge({
      'Valuation Date' => proc{|record| record[:valuation_completed_date]},
      'Final Valuation Amount' => proc{|record| record[:valuation_final_amount]}
    })
  end

  def query
    dataset = super


    dataset.where(Sequel.qualify(:enumvals_valuation_status, :value) => VALUATION_STATUS_COMPLETED)
  end
end
