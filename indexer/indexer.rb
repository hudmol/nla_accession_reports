class CommonIndexer

  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook {|doc, record|
      if doc['primary_type'] == 'accession'
        ASUtils.wrap(record['record']['linked_events']).each{|linked_event|
          event = JSONModel::JSONModel(:event).find(JSONModel.parse_reference(linked_event['ref'])[:id])
          doc["event_#{event['event_type']}_u_sstr"] = event['outcome']
          doc["event_#{event['event_type']}_begin_u_sstr"] = event['date']['begin']
        }
      end
    }
  end

end
