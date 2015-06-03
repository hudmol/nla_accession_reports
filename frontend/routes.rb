ArchivesSpace::Application.routes.draw do
  match('/plugins/download_accessions/download' => 'download_accessions#download', :via => [:post])
end
