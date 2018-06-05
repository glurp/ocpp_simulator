require "json-schema"



Dir.glob("schema/*.json").each do |fn|
  content=File.read(fn)
  ok=JSON::Validator.validate(content, {})
  puts "%-30s : \n%s"  % [fn, content] unless ok
end