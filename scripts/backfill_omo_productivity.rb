DRY_RUN = !ARGV.include?("--no_dryrun")
reviews = JudgeCaseReview.where(location: :omo_office)
puts "Found #{reviews.length} judge case reviews"
decass_records = reviews.map{|r| VACOLS::Decass.find_by(defolder: r.vacols_id, deadtim: r.created_in_vacols_date)}
decass_records.each do |r|
  puts r.inspect
end