require 'csv'

class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/download_accessions')
    .description("Download Accessions as CSV")
    .params(*BASE_SEARCH_PARAMS,
            ["repo_id", :repo_id])
    .permissions([])
    .returns([200, ""]) \
  do

    [200, some_headers, content]

  end


  def some_headers
    {
      "Content-Type" => "text/csv; charset=UTF-8",
      "Content-Disposition" => "attachment; filename=\"accessions_#{Time.now.iso8601}.csv\""
    }
  end


  def content
    params[:filter_term] ||= []
    #params[:filter_term] << {'primary_type' => 'accession'}.to_json
    params[:type] = 'accession'
    params[:page] = 1
    params[:page_size] = 100

    CSV.generate do |csv|
      csv << column_headings

      while true
        resp = Search.search(params, params[:repo_id])
        resp['results'].each do |r|
          j = ASUtils.json_parse(r['json'])
          #puts "j: "
          #puts j
          ud = j['user_defined'] || {}
          las = j['linked_agents'] || {}
          la1 = las.select{ |x| x["role"] == "source" }[0] #.find{|i| !i.nil?}
          la2 = las.select{ |x| x["role"] == "source" }[1] #.find{|i| !i.nil?}
          la3 = las.select{ |x| x["role"] == "creator"}.find{|i| !i.nil?}
          sourcename1 = la1.nil? ? "" : la1["_resolved"]["display_name"]["sort_name"]
          sourcerelator1 = la1.nil? ? nil : la1["relator"]
          sourcerelator1 = sourcerelator1.nil? ? "" : I18n.t("enumerations.linked_agent_archival_record_relators.#{sourcerelator1}")
          sourcename2 = la2.nil? ? "" : la2["_resolved"]["display_name"]["sort_name"]
          sourcerelator2 = la2.nil? ? nil : la2["relator"]
          sourcerelator2 = sourcerelator2.nil? ? "" : I18n.t("enumerations.linked_agent_archival_record_relators.#{sourcerelator2}")
          creator = la3.nil? ? "" : la3["_resolved"]["display_name"]["sort_name"]
          cm = j['collection_management'] || {}
          j['extents'] = {} unless j['extents']
          extent1 = j['extents'][0] || {}
          extent2 = j['extents'][1] || {}
          csv << [
                  r['title'],
                  r['identifier'],
                  r['resource_type'],
                  r['accession_date'],
                  j['acquisition_type'],
                  format_dates(j['dates'] || {}),
                  extent1['number'],
                  extent1['extent_type'],
                  extent1['container_summary'],
                  extent1['physical_details'],
                  extent1['dimensions'],
                  extent2['number'],
                  extent2['extent_type'],
                  extent2['container_summary'],
                  extent2['physical_details'],
                  extent2['dimensions'],
                  ud['boolean_1'],
                  sourcerelator1,
                  sourcename1,
                  sourcerelator2,
                  sourcename2,
                  creator,
                  cm['processing_status']
                 ]
        end

        if params[:page] < resp['last_page']
          params[:page] += 1
        else
          break
        end
      end
    end
  end


  def column_headings
    [
     'Title', 'Identifier','Resource Type', 'Accession Date','Acquisition Type', 'Dates',
     'Extent 1 Number', 'Extent 1 Type', 'Extent 1 Container Summary',
     'Extent 1 Physical Details', 'Extent 1 Dimensions',
     'Extent 2 Number', 'Extent 2 Type', 'Extent 2 Container Summary',
     'Extent 2 Physical Details', 'Extent 2 Dimensions',
     'Addendum/Accrual', 'Relator 1', 'Source 1', 'Relator 2', 'Source 2', 'Creator', 'Processing Status'
    ]
  end


  def format_dates(dates)
    return if dates.empty?
    dates.map do |d|
      be = [d['begin'], d['end']].compact.join(' to ')
      bee = [be, d['expression']].compact.join(' - ')
      "#{d['label']}: #{bee}"
    end.join("; ")
  end


  def format_subjects(subjects)
    return unless subjects
    subjects.join('; ')
  end

end
