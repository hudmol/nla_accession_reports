NLA Accession Reports plugin
============================

Introduces extra Accession reports, including:
 - Valuations Required
 - Valuations Completed
 - Workplan Development

And adds a 'Download as CSV' button to Accession browse and search screens.


## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'nla_accession_reports' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'nla_accession_reports']

And then clone the `nla_accession_reports` repository into your
ArchivesSpace plugins directory.  For example:

     cd /path/to/your/archivesspace/plugins
     git clone https://github.com/hudmol/nla_accession_reports.git nla_accession_reports

## Temporary Frontend template override

To fix a bug on the Report's listing page, this plugin overrides the `frontend/views/reports/index.html.erb` template to allow reports to define a single parameter and for it to be displayed correctly.  A patch has been delivered upstream via a pull request (https://github.com/archivesspace/archivesspace/pull/201).  Once that patch makes it into a future release, this particular template override may be removed.
