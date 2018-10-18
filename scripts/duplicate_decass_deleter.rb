# bundle exec rails runner scripts/enable_features_dev.rb

def sql_fmt(o)
  if o.nil?
    return "is null"
  end
  if o.is_a? Date
    return "= to_date('#{o}', 'YYYY-MM-DD')"
  end
  if o.is_a? Numeric
    return "= #{o}"
  end
  if o.is_a? String
    return "= '#{o}'"
  end
  fail o.inspect
end

# rubocop:disable Metrics/AbcSize
def predicate_from_record(record, limit)
  <<EOS.strip_heredoc
    rownum <= #{limit} and
    defolder #{sql_fmt(record.defolder)} and
    deatty #{sql_fmt(record.deatty)} and
    deteam #{sql_fmt(record.deteam)} and
    depdiff #{sql_fmt(record.depdiff)} and
    defdiff #{sql_fmt(record.defdiff)} and
    deassign #{sql_fmt(record.deassign)} and
    dereceive #{sql_fmt(record.dereceive)} and
    dehours #{sql_fmt(record.dehours)} and
    deprod #{sql_fmt(record.deprod)} and
    detrem #{sql_fmt(record.detrem)} and
    dearem #{sql_fmt(record.dearem)} and
    deoq #{sql_fmt(record.deoq)} and
    deadusr #{sql_fmt(record.deadusr)} and
    deadtim #{sql_fmt(record.deadtim)} and
    deprogrev #{sql_fmt(record.deprogrev)} and
    deatcom #{sql_fmt(record.deatcom)} and
    debmcom #{sql_fmt(record.debmcom)} and
    demdusr #{sql_fmt(record.demdusr)} and
    demdtim #{sql_fmt(record.demdtim)} and
    delock #{sql_fmt(record.delock)} and
    dememid #{sql_fmt(record.dememid)} and
    decomp #{sql_fmt(record.decomp)} and
    dedeadline #{sql_fmt(record.dedeadline)} and
    deicr #{sql_fmt(record.deicr)} and
    defcr #{sql_fmt(record.defcr)} and
    deqr1 #{sql_fmt(record.deqr1)} and
    deqr2 #{sql_fmt(record.deqr2)} and
    deqr3 #{sql_fmt(record.deqr3)} and
    deqr4 #{sql_fmt(record.deqr4)} and
    deqr5 #{sql_fmt(record.deqr5)} and
    deqr6 #{sql_fmt(record.deqr6)} and
    deqr7 #{sql_fmt(record.deqr7)} and
    deqr8 #{sql_fmt(record.deqr8)} and
    deqr9 #{sql_fmt(record.deqr9)} and
    deqr10 #{sql_fmt(record.deqr10)} and
    deqr11 #{sql_fmt(record.deqr11)} and
    dedocid #{sql_fmt(record.dedocid)} and
    derecommend #{sql_fmt(record.derecommend)}
EOS
end
# rubocop:enable Metrics/AbcSize

def str_of(v)
  v.inspect
end

def json_of(r)
  r.as_json.transform_values { |v| str_of(v) }
end

def diff_decass_records(r1, r2)
  {
    added: (json_of(r1).to_a - json_of(r2).to_a).sort,
    removed: (json_of(r1).to_a - json_of(r2).to_a).sort
  }
end

DRY_RUN = !ARGV.include?("--nodry_run")
if !DRY_RUN
  puts "WARNING: This is NOT a dry run."
end

["deassign", "dereceive", "deadtim", "deprogrev", "foo", "demdtim", "decomp", "dedeadline"].each do |name_column|
  VACOLS::Decass.attribute_types["dedeadline"] = ActiveRecord::Type.lookup(:datetime)
end

defolders = VACOLS::Decass.select("defolder")
  .where("deadtim >= ?", Date.new(2018, 8, 16))
  .group("defolder").having("count(*) > 1").map(&:defolder)
puts "Found #{defolders.length} cases with too many Decass records"
num_deleted = 0
defolders.each do |defolder|
  puts "Processing case #{defolder}"
  VACOLS::Decass.transaction do
    records = VACOLS::Decass.where(defolder: defolder)
    record_first = records.take(1)[0]
    records.drop(1).each do |r|
      puts diff_decass_records(record_first, r).inspect
    end
    puts
  end
end
puts "Deleted #{num_deleted} duplicate records"
