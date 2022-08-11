class Reports::ProgramOpsReportsController < ApplicationController
  around_action :set_timezone

  def room_signs
    authorize SessionAssignment, policy_class: Reports::ProgramOpsReportPolicy

    # Need by room and time
    sessions = SessionService
                 .published_sessions_unordered
                 # .order("rooms.name asc, start_time asc")

    # Room name, Day of week, sessions (title, start time, description, participant list with moderator marker).
    grouped_sessions = sessions.group_by {|s| s.room}
    moderator = SessionAssignmentRoleType.find_by(name: 'Moderator')
    participant = SessionAssignmentRoleType.find_by(name: 'Participant')

    workbook = FastExcel.open(constant_memory: true)
    worksheet = workbook.add_worksheet("Room Signs")
    date_time_style = workbook.number_format("d mmm yyyy h:mm")
    styles = [nil, nil, nil, date_time_style]

    worksheet.append_row(
      [
        'Room',
        'Day',
        'Session',
        'Time',
        'Description',
        'Moderators',
        'Participants'
      ]
    )

    grouped_sessions.each do |room, sessions|
      sessions.sort{|a,b| a.start_time <=> b.start_time}.each do |session|
        worksheet.append_row(
          [
            room.name,
            session.start_time.strftime('%A'),
            session.title,
            session.start_time ? FastExcel.date_num(session.start_time, session.start_time.in_time_zone.utc_offset) : nil,
            session.description,
            session.published_session_assignments.select{|a| a.session_assignment_role_type_id == moderator.id}.collect{|a| a.person.published_name}.join(";\n"),
            session.published_session_assignments.select{|a| a.session_assignment_role_type_id == participant.id}.collect{|a| a.person.published_name}.join(";\n"),
          ],
          styles
        )
      end
    end

    send_data workbook.read_string,
              filename: "RoomSigns#{Time.now.strftime('%m-%d-%Y')}.xlsx",
              disposition: 'attachment'
  end

  def back_of_badge
    authorize SessionAssignment, policy_class: Reports::ProgramOpsReportPolicy

    assignments = PublishedSessionAssignment
                    .includes(:person, :session_assignment_role_type, :published_session)
                    .order("people.published_name, published_sessions.start_time asc")


    workbook = FastExcel.open #(constant_memory: true)
    worksheet = workbook.add_worksheet("Back of Badge")
    date_time_style = workbook.number_format("d mmm yyyy h:mm")

    worksheet.append_row([]) # For the header

    group_assignments = assignments.group_by {|a| a.person}
    max_sessions = 0
    group_assignments.each do |person, grouped|
      row = [
        person.published_name
      ]
      styles = [nil]

      grouped.each do |assignment|
        row.concat [
          assignment.session.title,
          assignment.session.start_time ? FastExcel.date_num(assignment.session.start_time, assignment.session.start_time.in_time_zone.utc_offset) : nil,
          assignment.session.duration,
          assignment.session.room&.name,
        ]
        styles.concat [
          nil, date_time_style, nil, nil
        ]
      end
      max_sessions = grouped.size if grouped.size > max_sessions

      worksheet.append_row(row, styles)
    end

    header = ['Published Name']
    (0..max_sessions).each do |n|
      header.concat ["Title #{n+1}", "Start Time #{n+1}", "Duration #{n+1}", "Room #{n+1}"]
    end
    worksheet.write_row(0, header)

    send_data workbook.read_string,
              filename: "BackOfBadge-#{Time.now.strftime('%m-%d-%Y')}.xlsx",
              disposition: 'attachment'
  end
end
