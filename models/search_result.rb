class SearchResult
  attr_reader :subject, :url, :speaker_slug, :speaker_name, :sitting_type, :date, :highlight_text
  
  def initialize(subject, url, speaker_uid, sitting_type, date, text)
    @subject = subject
    @url = url
    
    if speaker_uid
      parts = speaker_uid.split("|")
      @speaker_name = parts[1]
      @speaker_slug = parts[0]
    end
    
    @sitting_type = sitting_type
    @date = Date.parse(date)
    @highlight_text = text
  end
end