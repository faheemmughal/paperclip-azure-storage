Gem::Specification.new do |s|
  s.name = 'paperclip-azure-storage'
  s.version = '0.1.5'
  s.licenses = ['MIT']
  s.summary = "Paperclip Adapter for Azure Storage"
  s.description = 'paperclip-azure-storage is a paperclip adapter for azure storage that use service principal authentication'
  s.authors = ["Irsyad Rizaldi"]
  s.email = 'irsyad.rizaldi97@gmail.com'
  s.homepage = 'https://github.com/dadangeuy/paperclip-azure-storage'
  s.metadata = { "source_code_uri" => "https://github.com/dadangeuy/paperclip-azure-storage" }

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_ruby_version = ">= 2.3.0"

  s.add_dependency 'azure-storage-blob', '>= 1.0.0', '< 3.0.0'
  s.add_dependency 'paperclip', '>= 5.1.0', '< 7.0.0'

  s.add_development_dependency 'activerecord', '~> 5.2.0'
  s.add_development_dependency 'rspec', '~> 3.10'
  s.add_development_dependency 'sqlite3', '~>1.4'
  s.add_development_dependency 'webmock', '~> 3.14'
end
