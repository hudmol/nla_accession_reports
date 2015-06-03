class DownloadAccessionsController < ApplicationController

  set_access_control  "view_repository" => [:download]

  def download

    backend_resp = JSONModel::HTTP::post_form("/repositories/#{session[:repo_id]}/download_accessions",
                                              {
                                                'filter_term[]' => Array(params['filter_term']),
                                                'q' => params['q'],
                                                'aq' => params['aq'],
                                              })
    response.headers['Content-Disposition'] = backend_resp['Content-Disposition']
    response.headers['Content-Type'] = backend_resp['Content-Type']
    self.response_body = backend_resp.body
  end

end
