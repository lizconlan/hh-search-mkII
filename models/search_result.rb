class SearchResult
  attr_reader :subject, :url, :speaker_slug, :speaker_name, :sitting_type, :date, :highlight_text
  
  def initialize(subject, url, speaker_name, speaker_url, sitting_type, date, text)
    @subject = subject
    @url = url
    @speaker_name = speaker_name
    @speaker_slug = speaker_url.split("/").pop if speaker_url
    @sitting_type = sitting_type
    @date = Date.parse(date)
    @highlight_text = text
  end
end