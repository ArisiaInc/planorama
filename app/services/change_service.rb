module ChangeService

  # What changed in date between from date and to date
  def self.session_changes(from:, to: nil)
    {
      sessions: self.sessions_changed(from: from, to: to),
      assignments: self.session_assignments_changed(from: from, to: to)
    }
  end

  # What changed in published date between from date and to date
  def self.published_changes(from:, to: nil)
    {
      sessions: self.published_sessions_changed(from: from, to: to),
      assignments: self.published_session_assignments_changed(from: from, to: to)
    }
  end

  def self.dropped_people(from:, to: nil)
    res = []
    changes = get_changes(clazz: Audit::PersonVersion, type: Person, from: from, to: to)
    changes.each do |id, change|
      if change[:changes]['con_state'] && ['declined', 'rejected'].include?(change[:changes]['con_state'][1] )
        # do not count a "dropped" state to another dropped state
        next if ['declined', 'rejected'].include?(change[:changes]['con_state'][0]

        res.append [change[:object].published_name]
      end
    end
    res.uniq
  end

  def self.sessions_changed(from:, to: nil)
    get_changes(clazz: Audit::SessionVersion, type: Session, from: from, to: to)
  end

  def self.published_sessions_changed(from:, to: nil)
    get_changes(clazz: Audit::PublishedSessionVersion, type: PublishedSession, from: from, to: to)
  end

  def self.session_assignments_changed(from:, to: nil)
    publishable_sessions = PublicationService.publishable_sessions
    get_changes(clazz: Audit::SessionVersion, type: SessionAssignment, from: from, to: to, publishable_session_ids: publishable_sessions.collect(&:id))
  end

  def self.published_session_assignments_changed(from:, to: nil)
    get_changes(clazz: Audit::PublishedSessionVersion, type: PublishedSessionAssignment, from: from, to: to)
  end

  # get the paper trail verions from: to:
  # we need the versions for each session that has been updated within the period
  # order by the session id and the time (oldest to newest)
  # for each session version get it's change set and "merge" as we go through the time line
  # so we have one final change set per session id which can be used for the report
  def self.get_changes(clazz:, type:, from:, to:, publishable_session_ids: nil)
    # Rails.logger.debug "**** GET #{type} from #{from}"
    changes = {}

    audits = clazz.where("item_type = ?", type.name).order("item_id, created_at asc")

    audits = audits.where("created_at >= ?", from) if from
    audits = audits.where("created_at <= ?", to) if to

    grouped_audits = audits.group_by {|a| a.item_id}

    grouped_audits.each do |key, item_audits|
      # Rails.logger.debug "**** AUDIT #{key} #{publishable_session_ids}"
      # just in case we sort by date
      item_audits.sort{|a,b| a.created_at <=> b.created_at}.each do |audit|
        # merge the change history
        if changes[key]
          changes[key][:changes] = self.merge_change_set(to: changes[key][:changes], from: audit.object_changes)
        else
          # Get the old version of the object
          obj = if audit.event == 'create'
                  type.find(audit.item_id) if type.exists?(audit.item_id)
                else
                  audit.reify
                end
          # obj = audit.reify
          if publishable_session_ids
            next unless publishable_session_ids.include?(obj.session_id)
          end
          changes[key] = {item_id: audit.item_id, item_type: audit.item_type, event: audit.event, object: obj, changes: audit.object_changes}
        end
      end
    end

    changes
  end

  def self.merge_change_set(to: , from:)
    res = to
    from.each do |key, change|
      res[key] = from[key] unless res[key]
      res[key][1] = from[key][1] if res[key]
    end
    res
  end
end
