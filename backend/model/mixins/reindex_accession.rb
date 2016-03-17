module ReindexAccession

  # don't need to worry about create
  # because it is handled in the event link

  def delete
    accession = false
    self.related_records(:event_link).each do |linked_record|
      if linked_record.is_a? Accession
        accession = linked_record
      end
    end

    super

    accession.update(:system_mtime => Time.now) if accession
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    super

    self.related_records(:event_link).each do |linked_record|
      if linked_record.is_a? Accession
        linked_record.update(:system_mtime => Time.now)
      end
    end
  end

end
