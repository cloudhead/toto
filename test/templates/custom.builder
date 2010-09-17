xml.instruct!
xml.custom do
  xml.title @config[:title]
  xml.id @config[:url]

  xml.child do
    xml.name "Testing Baby"
  end
end

