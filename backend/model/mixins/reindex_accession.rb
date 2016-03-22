module ReindexAccession

  # the delete case isn't handled by the core code
  # this is likely a bug and should be investigated

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

end
