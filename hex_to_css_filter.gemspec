Gem::Specification.new do |s|
  s.name        = 'hex_to_css_filter'
  s.version     = '1.0.0'
  s.summary     = 'Easy way to generate colors from HEX to CSS Filters'
  s.description = 'CSS filter generator to convert from black to target hex color'
  s.authors     = ['Sujit Shakya']
  s.email       = 'sshakya.mail@gmail.com'
  s.files       = ['lib/hex_to_css_filter.rb', 'lib/matrices.rb']
  s.homepage    = 'https://github.com/BlackRabbitt/hex_to_css_filter'
  s.license     = 'MIT'

  s.metadata = {
    'source_code_uri' => 'https://github.com/BlackRabbitt/hex_to_css_filter',
    'bug_tracker_uri' => 'https://github.com/BlackRabbitt/hex_to_css_filter/issues',
    'changelog_uri' => 'https://github.com/BlackRabbitt/hex_to_css_filter/releases',
    'homepage_uri' => s.homepage
  }

  s.required_ruby_version = '>= 2.5.0'
end
