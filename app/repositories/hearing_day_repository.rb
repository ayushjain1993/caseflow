# Hearing Schedule Repository to help build and edit hearing
# master records in VACOLS for Video, TB and CO hearings.
class HearingDayRepository
  class << self
    def create_vacols_hearing!(hearing_hash)
      hearing_hash = HearingDayMapper.hearing_day_field_validations(hearing_hash)
      to_canonical_hash(VACOLS::CaseHearing.create_hearing!(hearing_hash)) if hearing_hash.present?
    end

    def update_vacols_hearing!(hearing, hearing_hash)
      hearing_hash = HearingDayMapper.hearing_day_field_validations(hearing_hash)
      hearing.update_hearing!(hearing_hash) if hearing_hash.present?
    end

    # Query Operations
    def find_hearing_day(hearing_type, hearing_key)
      if hearing_type.nil?
        VACOLS::CaseHearing.find_hearing_day(hearing_key)
      else
        tbyear, tbtrip, tbleg = hearing_key.split("-")
        VACOLS::TravelBoardSchedule.find_by(tbyear: tbyear, tbtrip: tbtrip, tbleg: tbleg)
      end
    end

    def load_days_for_range(start_date, end_date)
      video_and_co = VACOLS::CaseHearing.load_days_for_range(start_date, end_date)
        .each_with_object([]) do |hearing, result|
        result << to_canonical_hash(hearing)
      end
      travel_board = VACOLS::TravelBoardSchedule.load_days_for_range(start_date, end_date)
      [video_and_co.uniq { |hearing_day| [hearing_day[:hearing_date].to_date, hearing_day[:room_info]] }, travel_board]
    end

    def load_days_for_central_office(start_date, end_date)
      video_and_co = VACOLS::CaseHearing.load_days_for_central_office(start_date, end_date)
        .each_with_object([]) do |hearing, result|
        result << to_canonical_hash(hearing)
      end
      travel_board = []
      [video_and_co.uniq { |hearing_day| [hearing_day[:hearing_date].to_date, hearing_day[:room_info]] }, travel_board]
    end

    def fetch_days_with_open_hearings_slots(start_date, end_date)
      # replaces slots_based_on_type, HearingDay.filter_non_scheduled_hearings, and
      # HearingDay.load_days_with_open_hearing_slots logic

      # see HearingRepository.fetch_video_hearings_for_parent /
      # CaseHearing.video_hearings_for_master_record
      matches_by_key = "h.vdkey = hearsched.hearing_pkseq"
      # see HearingRepository.fetch_co_hearings_for_parent /
      # CaseHearing.co_hearings_for_master_record
      matches_by_date = "(
        h.hearing_type = 'C' AND
        h.folder_nr NOT LIKE '%VIDEO%' AND
        trunc(h.hearing_date) = trunc(hearsched.hearing_date)
      )"
      # see HearingDay.filter_non_scheduled_hearings
      is_scheduled = "(
        (h.hearing_type = 'C' AND h.folder_nr IS NOT NULL) OR
        (h.hearing_disp NOT IN ('P', 'C'))
      )"

      slotted_hearings = "(
         SELECT COUNT(*)
         FROM vacols.hearsched h
         WHERE (#{matches_by_key} OR #{matches_by_date}) AND #{is_scheduled}
      )"
      # fetch_hearing_day_slots + slots_based_on_type
      total_slots = "
        CASE WHEN hearing_type = 'C' THEN 11
             WHEN hearing_type = 'V' THEN s.stc4
             WHEN hearing_type = 'T' AND to_char(hearing_date, 'day') IN ('monday', 'friday') THEN s.stc2
             ELSE s.stc3
        END
      "

      days_for_range = "
        trunc(hearing_date) BETWEEN '#{VacolsHelper.day_only_str(start_date)}' AND '#{VacolsHelper.day_only_str(end_date)}'
      "

      days_for_central_office = "(
        hearing_type = 'C' AND
        folder_nr NOT LIKE '%VIDEO%' AND
        trunc(hearing_date) BETWEEN '#{VacolsHelper.day_only_str(start_date)}' AND '#{VacolsHelper.day_only_str(end_date)}'
      )"

      VACOLS::CaseHearing.select_schedule_days
        .select("#{slotted_hearings} AS slotted_hearings, #{total_slots} AS total_slots")
        .joins("left outer join vacols.staff s ON s.stafkey = folder_nr")
        .where("#{slotted_hearings} < (#{total_slots}) AND (#{days_for_central_office} OR #{days_for_range})")
    end

    def load_days_with_open_hearings_slots(start_date, end_date)
      hearing_days = fetch_days_with_open_hearings_slots(start_date, end_date)
      hearings_by_day = HearingRepository.fetch_hearings_for_parents(hearing_days).group_by { | h | h[:vacols_id] }
      hearing_days = hearing_days.each_with_object([]) do |_day, result|
        day = to_canonical_hash(_day)
        day[:hearings] = hearings_by_day[_day[:hearing_pkseq].to_s]
        result << day
      end

      hearing_days.uniq { | day | [day[:hearing_date].to_date, day[:room_info]] }
    end

    def load_days_for_regional_office(regional_office, start_date, end_date)
      video_and_co = VACOLS::CaseHearing.load_days_for_regional_office(regional_office, start_date, end_date)
        .each_with_object([]) do |hearing, result|
        result << to_canonical_hash(hearing)
      end
      travel_board = VACOLS::TravelBoardSchedule.load_days_for_regional_office(regional_office, start_date, end_date)
      [video_and_co, travel_board]
    end

    # STAFF.STC2 is the Travel Board limit for Mon and Fri
    # STAFF.STC3 is the Travel Board limit for Tue, Wed, Thur
    # STAFF.STC4 is the Video limit
    def slots_based_on_type(staff:, type:, date:)
      case type
      when HearingDay::HEARING_TYPES[:central]
        11
      when HearingDay::HEARING_TYPES[:video]
        staff.stc4
      when HearingDay::HEARING_TYPES[:travel]
        (date.monday? || date.friday?) ? staff.stc2 : staff.stc3
      end
    end

    def fetch_hearing_day_slots(hearing_day)
      # returns the total slots for the hearing day's regional office.
      ro_staff = VACOLS::Staff.where(stafkey: hearing_day[:regional_office])
      slots_from_vacols = slots_based_on_type(staff: ro_staff[0],
                                              type: hearing_day[:hearing_type],
                                              date: hearing_day[:hearing_date])
      slots_from_vacols || HearingDocket::SLOTS_BY_TIMEZONE[HearingMapper.timezone(hearing_day[:regional_office])]
    end

    def to_canonical_hash(hearing)
      hearing_hash = hearing.as_json.each_with_object({}) do |(k, v), result|
        result[HearingDayMapper::COLUMN_NAME_REVERSE_MAP[k.to_sym]] = v
      end
      hearing_hash.delete(nil)
      values_hash = hearing_hash.each_with_object({}) do |(k, v), result|
        result[k] = if k.to_s == "regional_office" && !v.nil?
                      v[6, v.length]
                    elsif k.to_s == "hearing_date"
                      VacolsHelper.normalize_vacols_datetime(v)
                    else
                      v
                    end
      end
      values_hash
    end
  end
end
