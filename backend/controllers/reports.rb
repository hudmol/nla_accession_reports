class ArchivesSpaceService < Sinatra::Base

  include ReportHelper::ResponseHelpers

  Endpoint.get("/repositories/:repo_id/reports/nla_valuations_required")
  .description("Report on accessions where valuations are required")
  .params(ReportHelper.report_formats,
          ["repo_id", :repo_id])
  .permissions([])
  .returns([200, "report"]) \
      do
    report_response(ValuationsRequiredAccessionReport.new(params), params[:format])
  end

end