class DownloadAccessionsController < ApplicationController

  set_access_control  "view_repository" => [:download]

  def download
    download_params = params_for_backend_search.merge('aq' => params['aq'])

    # things changed in v2.0.0
    build_filters(download_params) unless ASConstants.VERSION.start_with?('v1')

    queue = Queue.new

    Thread.new do
      begin
        JSONModel::HTTP::stream("/repositories/#{session[:repo_id]}/download_accessions",
                                download_params) do |backend_resp|

          response.headers['Content-Disposition'] = backend_resp['Content-Disposition']
          response.headers['Content-Type'] = backend_resp['Content-Type']
          queue << :ok
          backend_resp.read_body do |chunk|
            queue << chunk
          end
        end
      rescue
        queue << {:error => ASUtils.json_parse($!.message)}
      ensure
        queue << :EOF
      end
    end

    first_on_queue = queue.pop
    if first_on_queue.kind_of?(Hash)
      @error = first_on_queue[:error]
      response.headers['Content-Type'] = "text/plain; charset=UTF-8",
      response.headers['Content-Disposition'] = "attachment; filename=\"accessions_#{Time.now.iso8601}.txt\""
      self.response_body = @error.inspect
      return
    end

    self.response_body = Class.new do
      def self.queue=(queue)
        @queue = queue
      end
      def self.each(&block)
        while(true)
          elt = @queue.pop
          break if elt === :EOF
          block.call(elt)
        end
      end
    end

    self.response_body.queue = queue
  end


  def build_filters(criteria)
    queries = AdvancedQueryBuilder.new

    if criteria['filter_term[]']
      Array(criteria['filter_term[]']).each do |json_filter|
        filter = ASUtils.json_parse(json_filter)
        queries.and(filter.keys[0], filter.values[0])
      end

      new_filter = queries.build

      if criteria['filter']
        # Combine our new filter with any existing ones
        existing_filter = ASUtils.json_parse(criteria['filter'])

        new_filter['query'] = JSONModel(:boolean_query)
                                .from_hash({
                                             :jsonmodel_type => 'boolean_query',
                                             :op => 'AND',
                                             :subqueries => [existing_filter['query'], new_filter['query']]
                                           })

      end

      criteria['filter'] = new_filter.to_json
    end
    criteria['filter']
  end

end
