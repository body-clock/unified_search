require 'net/http'
require 'json'
require 'pry'

# initial variable setup
search_query = 'book of hours'
colenda_url = "https://colenda.library.upenn.edu/?utf8=%E2%9C%93&search_field=all_fields&format=json&q=#{search_query}"
finding_aids_url = "https://findingaids.library.upenn.edu/records?f[record_source][]=upenn&format=json&q=#{search_query}"

# turn colenda URL into URI and get response
colenda_uri = URI colenda_url
colenda_response = JSON.parse Net::HTTP.get(colenda_uri)

# turn finding aids URL into URI and get response
finding_aids_uri = URI finding_aids_url
finding_aids_response = JSON.parse Net::HTTP.get(finding_aids_uri)

# grab relevant search result data from colenda
colenda_response_items = colenda_response["response"]["docs"]

def extract_date date_string
  date_array = date_string.split(/[\s,-]/)
  date_int_array = []
  date_array.each do |d|
    date_int_array << d.to_i unless d.to_i < 100
  end
  date_int_array.min
end

# create empty hash, iterate through colenda search result data, and add extracted data into hash
colenda_constructed_hash = {}
colenda_response_items.each do |r|
  colenda_constructed_hash[r["id"]] = {
    title:    r["title_tesim"].nil? ? "" : r["title_tesim"], # keep it as an array, don't want to lose information and have different data types
    subjects: r["subject_tesim"].nil? ? "" : r["subject_tesim"],
    abstract: r["abstract_tesim"].nil? ? "" : r["abstract_tesim"], # some values are nil - we want to have only strings
    date:     r["date_tesim"].nil? ? "" : extract_date(r["date_tesim"].join ", "),
    link:     "https://colenda.library.upenn.edu/catalog/#{r["id"]}",
    source:   "Colenda"
  }
end

# grab relevant search result data from finding aids
finding_aids_response_items = finding_aids_response["data"]

# create empty hash, iterate through finding aids search result data, and add extracted data into hash
# these values must be converted to arrays in order to preserve the arrays in colenda data
finding_aids_constructed_hash = {}
finding_aids_response_items.each do |r|
  finding_aids_constructed_hash[r["id"]] = {
    title:    r["attributes"]["title_tsi"].nil? ? "" : [r["attributes"]["title_tsi"]["attributes"]["value"]],
    subjects: r["attributes"]["subjects_ssim"].nil? ? "" : [r["attributes"]["subjects_ssim"]["attributes"]["value"]],
    abstract: r["attributes"]["abstract_scope_contents_tsi"].nil? ? "" : [r["attributes"]["abstract_scope_contents_tsi"]["attributes"]["value"]],
    date:     r["attributes"]["display_date_ssim"].nil? ? "" : extract_date(r["attributes"]["display_date_ssim"]["attributes"]["value"]),
    link:     r["attributes"]["title_tsi"]["id"],
    source:   'Finding Aids'
  }
end

# return combined json data for consumption by front end app
puts JSON.pretty_generate colenda_constructed_hash.merge(finding_aids_constructed_hash)