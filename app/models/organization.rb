class Group
  include MongoMapper::Document

  before_save :generate_keywords

  one :location
  many :events
  many :links

  ensure_index :"location.lng_lat" => '2dsphere'
  
  RANGE_OPTIONS = [ 'local', 'regional', 'national', 'international' ]
  SIZE_OPTIONS = [ nil, "No Membership", "1-10", "11-25", "26-50", "51-100",
                        "101-250","250-500", "500-1000", "1000+" ]
  STATUS_OPTIONS = ['pending', 'avtive', 'deactive', 'disabled']

  timestamps!
  key :name, required: true, unique: true
  key :description
  key :status, default: 'pending', required: true, :in => STATUS_OPTIONS
  key :size, :in => SIZE_OPTIONS
  key :keywords, Array
  key :range, range: true, :in => RANGE_OPTIONS
  key :tags, Array

  def self.keywordize str
    str.downcase.split.uniq
  end
  
  def generate_keywords
    self.keywords = self.class.keywordize("#{name} #{description}")
  end

  def self.search params={}
    query = build_query(params)
    where(query).all
  end

  def self.build_query params

    query = {}

    query[:keywords] = { :$in => keywordize(params[:keywords]) } if params[:keywords]
    query[:size] = { :$in => params[:sizes] } if params[:sizes]
    query[:range] = { :$in => params[:ranges] } if params[:ranges]
    query[:"location.lng_lat"] = { :$near => { :$geometry => { type: 'Point', coordinates: [ params[:geo][0].to_f, params[:geo][1].to_f ] } }, :$maxDistance => (params[:geo][2].to_f / 6371) } if params[:geo]

    if params[:tags]
      tagsOn = params[:tags].select { |k, v| v == 'require' }.keys.map(&:to_s)
      tagsOff = params[:tags].select { |k, v| v == 'reject' }.keys.map(&:to_s)
      query[:tags] = {}
      query[:tags][:$in] = tagsOn unless tagsOn.empty?
      query[:tags][:$nin] = tagsOff unless tagsOff.empty?
    end

    if params[:keys]
      query.merge! params[:keys]
    end

    query
  end
end