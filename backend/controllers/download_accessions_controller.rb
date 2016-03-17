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
    params[:filter_term] << {'primary_type' => 'accession'}.to_json
    params[:page] = 1
    params[:page_size] = 100

    CSV.generate do |csv|
      csv << column_headings

      while true
        resp = Search.search(params, params[:repo_id])

        resp['results'].each do |r|
          j = ASUtils.json_parse(r['json'])
          ud = j['user_defined'] || {}
          cm = j['collection_management'] || {}
          extent = j['extents'].first || {}
          csv << [
                  r['title'],
                  r['identifier'],
                  r['accession_date'],
                  j['content_description'],
                  j['inventory'],
                  j['retention_rule'],
                  j['access_restrictions_note'],
                  j['disposition'],
                  j['acquisition_type'],
                  format_dates(j['dates']),
                  extent['number'],
                  extent['extent_type'],
                  extent['container_summary'],
                  extent['physical_details'],
                  extent['Dimensions'],
                  format_subjects(r['subjects']),
                  ud['text_2'],
                  ud['text_3'],
                  ud['text_4'],
                  ud['enum_2'],
                  ud['integer_1'],
                  ud['boolean_1'],
                  ud['boolean_2'],
                  ud['integer_2'],
                  ud['string_2'],
                  cm['processing_status'],
                  cm['processing_priority'],
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
     'Title', 'Identifier', 'Accession Date', 'Content Description',
     'Inventory', 'Processing Note', 'Access Restrictions Note',
     'Disposition', 'Acquisition Type',
     'Dates', 'Extent Number', 'Extent Type', 'Extent Container Summary',
     'Physical Details', 'Dimensions',
     'Subjects', 'Preservation Notes', 'Volunteers Projects',
     'Special Format Notes', 'Preservation Status',
     'Processing (A&D) Priority',
     'New Collection?', 'Purchase Order / Holding?',
     'Voyager Bib ID', 'RefTracker No.',
     'Processing Status', 'Processing Priority',
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

