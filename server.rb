require 'sinatra'
require 'haml'
require 'active_record'

WEBSOLR_URL = "http://127.0.0.1:8983/solr"
PARENT_URL = "http://hansard.millbanksystems.com"


helpers do
  def querystring_builder(option={})
    remove = ""
    page = params[:page]
    sort = params[:sort]
    speaker = params[:speaker]
    type = params[:type]
    
    #time options (mutually exclusive)
    decade = params[:decade]
    century = params[:century]
    year = params[:year]
    month = params[:month]
    day = params[:day]
    
    qs = []
    
    name = option.keys.first
    value = option[name]
    if value.nil?
      eval "#{name.to_s} = nil"
      page = 0
    else
      eval "#{name.to_s} = '#{value}'"
      page = 0 unless name.to_s == "page"
    end
    page = page.to_i
    
    if page and page > 1
      qs << "page=#{page}"
    end
    #time stuff here
    if day
      qs << "day=#{day}"
    elsif month
      qs << "month=#{month}"
    elsif year
      qs << "year=#{year}"
    elsif decade
      qs << "decade=#{decade}"
    elsif century
      qs << "century=#{century}"
    end
    if sort
      qs << "sort=#{sort}"
    end
    if speaker
      qs << "speaker=#{speaker}"
    end
    if type
      qs << "type=#{type}"
    end
    
    qstring = qs.join("&")
    qstring.empty? ? request.path_info : "?#{qstring}"
  end
end

#require './models/person'
require './models/search_result'
#require './models/hansard_reference'

require './models/timeline.rb'

require './lib/search'

before do
  #dbconfig = YAML::load(File.open 'config/database.yml')[ Sinatra::Application.environment.to_s ]
  #ActiveRecord::Base.establish_connection(dbconfig)
end

get "/test" do
  @fake_timeline = Timeline.new()
  @fake_timeline.title = "19th century"
  @fake_timeline.start_text = "18th century"
  @fake_timeline.end_link = "/sittings/C20"
  @fake_timeline.end_text = "20th century"
  block = TimelineBlock.new("/sittings/1800s")
  block.bars << TimelineBar.new(3)
  block.bars << TimelineBar.new(24)
  block.bars << TimelineBar.new(33)
  block.bars << TimelineBar.new(23)
  @fake_timeline.blocks << block
  @fake_timeline.block_captions << TimelineCaption.new("1800s", "/sittings/1800s")
  
  block = TimelineBlock.new("/sittings/1810s")
  block.bars << TimelineBar.new(13)
  block.bars << TimelineBar.new(17)
  block.bars << TimelineBar.new(15)
  block.bars << TimelineBar.new(10)
  block.bars << TimelineBar.new(20)
  @fake_timeline.blocks << block
  @fake_timeline.block_captions << TimelineCaption.new("1810s", "/sittings/1810s")
  
  block = TimelineBlock.new("/sittings/1820s")
  block.bars << TimelineBar.new(22)
  block.bars << TimelineBar.new(20)
  block.bars << TimelineBar.new(20)
  block.bars << TimelineBar.new(19)
  block.bars << TimelineBar.new(11)
  @fake_timeline.blocks << block
  @fake_timeline.block_captions << TimelineCaption.new("1820s", "/sittings/1820s")
  
  block = TimelineBlock.new("/sittings/1830s")
  block.bars << TimelineBar.new(39)
  block.bars << TimelineBar.new(40)
  block.bars << TimelineBar.new(37)
  block.bars << TimelineBar.new(38)
  block.bars << TimelineBar.new(33)
  @fake_timeline.blocks << block
  @fake_timeline.block_captions << TimelineCaption.new("1830s", "/sittings/1830s")
  
  block = TimelineBlock.new("/sittings/1840s")
  block.bars << TimelineBar.new(34)
  block.bars << TimelineBar.new(36)
  block.bars << TimelineBar.new(38)
  block.bars << TimelineBar.new(39)
  block.bars << TimelineBar.new(34)
  @fake_timeline.blocks << block
  @fake_timeline.block_captions << TimelineCaption.new("1840s", "/sittings/1840s")
  
  block = TimelineBlock.new("/sittings/1850s")
  block.bars << TimelineBar.new(31)
  block.bars << TimelineBar.new(35)
  block.bars << TimelineBar.new(37)
  block.bars << TimelineBar.new(33)
  block.bars << TimelineBar.new(30)
  @fake_timeline.blocks << block
  @fake_timeline.block_captions << TimelineCaption.new("1850s", "/sittings/1850s")
  
  block = TimelineBlock.new("/sittings/1860s")
  block.bars << TimelineBar.new(37)
  block.bars << TimelineBar.new(30)
  block.bars << TimelineBar.new(29)
  block.bars << TimelineBar.new(36)
  block.bars << TimelineBar.new(30)
  @fake_timeline.blocks << block
  @fake_timeline.block_captions << TimelineCaption.new("1860s", "/sittings/1860s")
  
  block = TimelineBlock.new("/sittings/1870s")
  block.bars << TimelineBar.new(34)
  block.bars << TimelineBar.new(32)
  block.bars << TimelineBar.new(30)
  block.bars << TimelineBar.new(33)
  block.bars << TimelineBar.new(36)
  @fake_timeline.blocks << block
  @fake_timeline.block_captions << TimelineCaption.new("1870s", "/sittings/1870s")
  
  block = TimelineBlock.new("/sittings/1880s")
  block.bars << TimelineBar.new(32)
  block.bars << TimelineBar.new(40)
  block.bars << TimelineBar.new(35)
  block.bars << TimelineBar.new(35)
  block.bars << TimelineBar.new(37)
  @fake_timeline.blocks << block
  @fake_timeline.block_captions << TimelineCaption.new("1880s", "/sittings/1880s")
  
  block = TimelineBlock.new("/sittings/1890s")
  block.bars << TimelineBar.new(33)
  block.bars << TimelineBar.new(38)
  block.bars << TimelineBar.new(28)
  block.bars << TimelineBar.new(32)
  block.bars << TimelineBar.new(33)
  @fake_timeline.blocks << block
  @fake_timeline.block_captions << TimelineCaption.new("1890s", "/sittings/1890s")
  
  haml(:timeline_test)
end

get "/" do
  haml(:"search_help")
end

post "/" do
  query = params[:query]
  redirect "/#{query}"
end

get "/:query" do
  do_search
  haml(:"search")
end

def do_search  
  query = params[:query]
  if query
    #reference = HansardReference.create_from(query)
    
    @page_title = "Search: #{query}"
    
    @search = Search.new()
    options = {}
    options[:type] = params[:type] if params[:type]
    options[:speaker] = params[:speaker] if params[:speaker]
    options[:sort] = params[:sort] if params[:sort]
    
    @search.search(query, params[:page], options)
    
    @filters = []
    if params[:speaker]
      @search.speaker_facets[0..5].each do |uuid|
        slug,speaker = uuid.first.split("|")
        if slug == params[:speaker]
          @filters << [speaker, "speaker"]
          break
        end
      end 
    end
    
    if params[:type]
      @filters << [params[:type], "type"]
    end
    if params[:day]
    elsif params[:month]
    elsif params[:year]
    elsif params[:decade]
    elsif params[:century]
    end
  end
end

def format_name(uid)
  parts = uid.split("|")
  name = parts[1]
end