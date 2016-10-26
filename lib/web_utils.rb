# encoding: utf-8

require 'rack/utils'
require 'uri'

module WebUtils

  # Most methods are supposed to be as simple as possible
  # and just cover most cases.
  # I would rather override specific cases rather than making
  # complicated methods.

  extend Rack::Utils

  def blank? s
    s.to_s.strip==''
  end
  module_function :blank?

  def pluralize s
    s<<'e' if s[-1,1]=='x'
    s<<'s'
    s.sub(/([b-df-hj-np-tv-z])ys$/,'\1ies')
  end
  module_function :pluralize

  def singularize s
    case s
    when /xes$/
      s[0..-3]
    when /ies$/
      s.sub(/ies$/, 'y')
    when /s$/
      s[0..-2]
    else
      s
    end
  end
  module_function :singularize

  def dasherize_class_name s
    s.gsub(/([A-Z]|\d+)/){|str|"-#{str.downcase}"}[1..-1].gsub('::','-')
  end
  module_function :dasherize_class_name

  def undasherize_class_name s
    s.capitalize.gsub(/\-([a-z0-9])/){|str|$1.upcase}.gsub('-','::')
  end
  module_function :undasherize_class_name

  def resolve_class_name s, context=Kernel
    current, *payload = s.to_s.split('::')
    raise(NameError) if current.nil?
    const = context.const_get(current)
    if payload.empty?
      const
    else
      resolve_class_name(payload.join('::'),const)
    end
  end
  module_function :resolve_class_name

  def resolve_dasherized_class_name s
    resolve_class_name(undasherize_class_name(s.to_s)) 
  end
  module_function :resolve_dasherized_class_name

  def guess_related_class_name context, clue
    context.respond_to?(:name) ? context.name : context.to_s
    clue = clue.to_s
    return clue if clue=~/^[A-Z]/
    if clue=~/^[a-z]/
      clue = undasherize_class_name singularize(clue).gsub('_','-')
      clue = "::#{clue}"
    end
    "#{context}#{clue}"
  end
  module_function :guess_related_class_name

  def get_value raw, context=Kernel
    if raw.is_a? Proc
      raw.call
    elsif raw.is_a? Symbol
      context.__send__ raw
    else
      raw
    end
  end
  module_function :get_value

  def deep_copy original
    Marshal.load(Marshal.dump(original))
  end
  module_function :deep_copy

  def ensure_key! h, k, v
    h[k] = v unless h.key?(k)
    h[k]
  end
  module_function :ensure_key!

  def ensure_key h, k, v
    new_h = h.dup
    self.ensure_key! new_h, k, v
    new_h
  end
  module_function :ensure_key

  ACCENTS_FROM = 
    "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞ"
  ACCENTS_TO = 
    "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssT"
  def slugify s, force_lower=true
    s = s.to_s.tr(ACCENTS_FROM,ACCENTS_TO).tr(' .,;:?!/\'"()[]{}<>','-').gsub(/&/, 'and').gsub(/-+/,'-').gsub(/(^-|-$)/,'')
    s = s.downcase if force_lower
    escape(s)
  end
  module_function :slugify

  def label_for_field field_name
    field_name.to_s.scan(/[a-zA-Z0-9]+/).map(&:capitalize).join(' ')
  end
  module_function :label_for_field

  def each_stub obj, &block 
    raise TypeError, 'WebUtils.each_stub expects an object which respond to each_with_index' unless obj.respond_to?(:each_with_index)
    obj.each_with_index do |(k,v),i|
      value = v || k
      if value.is_a?(Hash) || value.is_a?(Array)
        each_stub(value,&block)
      else
        block.call(obj, (v.nil? ? i : k), value)
      end
    end
  end
  module_function :each_stub

  def automatic_typecast str, casted=[:bool,:nil,:int,:float] 
    return str unless str.is_a?(String)
    if casted.include?(:bool) and str=='true'
      true
    elsif casted.include?(:bool) and str=='false'
      false
    elsif casted.include?(:nil) and str==''
      nil
    elsif casted.include?(:int) and str=~/^-?\d+$/
      str.to_i
    elsif casted.include?(:float) and str=~/^-?\d*\.\d+$/
      str.to_f
    else
      str
    end
  end
  module_function :automatic_typecast

  ID_CHARS = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
  ID_SIZE = 16
  def generate_random_id size=ID_SIZE
    id = ''
    size.times{id << ID_CHARS[rand(ID_CHARS.size)]} 
    id
  end
  module_function :generate_random_id

  def nl2br s, br='<br>'
    s.to_s.gsub(/\n/,br)
  end
  module_function :nl2br

  def complete_link link
    if blank?(link) or link=~/^(\/|[a-z]*:)/
      link
    else
      "//#{link}"
    end
  end
  module_function :complete_link

  def external_link? link
    !!(link =~ /^[a-z]*:?\/\//)
  end
  module_function :external_link?

  def automatic_html s, br='<br>'
    replaced = s.to_s.
    gsub(/\b((https?:\/\/|ftps?:\/\/|www\.)([A-Za-z0-9\-_=%&@\?\.\/]+))\b/) do |str|
      url = complete_link $1
      "<a href='#{url}' target='_blank'>#{$1}</a>"
    end.
    gsub(/([^\s]+@[^\s]*[a-zA-Z])/) do |str|
      "<a href='mailto:#{$1.downcase}'>#{$1}</a>"
    end
    nl2br(replaced,br).gsub("@", "&#64;")
  end
  module_function :automatic_html

  def truncate s,c=320,ellipsis='...'
    s.to_s.gsub(/<[^>]*>/, '').gsub(/\n/, ' ').sub(/^(.{#{c}}\w*).*$/m, '\1'+ellipsis)
  end
  module_function :truncate

  def display_price int
    raise(TypeError, 'The price needs to be the price in cents/pence as an integer') unless int.is_a?(Integer)
    ("%.2f" % (int/100.0)).sub(/\.00/, '').reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
  module_function :display_price

  def parse_price string
    raise(TypeError, 'The price needs to be parsed from a String') unless string.is_a?(String)
    ("%.2f" % string.gsub(/[^\d\.\-]/, '')).gsub(/\./,'').to_i
  end
  module_function :parse_price

  def branded_filename path, brand='WebUtils'
    "#{File.dirname(path)}/#{brand}-#{File.basename(path)}".sub(/^\.\//,'')
  end
  module_function :branded_filename

  def filename_variation path, variation, ext
    old_ext = File.extname(path) 
    path.sub(/#{Regexp.escape old_ext}$/, ".#{variation}.#{ext}")
  end
  module_function :filename_variation

  def initial_request? request
    return true unless request.referer=~URI.regexp
    URI.parse(request.referer).host!=request.host
  end
  module_function :initial_request?

end

