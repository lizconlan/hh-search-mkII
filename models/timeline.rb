class Timeline
  attr_accessor :title, :start_link, :start_text, :end_link, :end_text, :blocks, :block_captions
  
  def initialize
    @blocks = []
    @block_captions = []
  end
end

class TimelineBlock
  attr_accessor :link, :bars
  
  def initialize(link)
    @link = link
    @bars = []
  end
end

class TimelineBar
  attr_accessor :height
  
  def initialize(height)
    @height = height
  end
end

class TimelineCaption
  attr_accessor :link, :text
  
  def initialize(text, link=nil)
    @text = text
    @link = link if link
  end
end