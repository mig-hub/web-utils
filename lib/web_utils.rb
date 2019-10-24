# encoding: utf-8

require 'rack/utils'
require 'uri'

module WebUtils

  VERSION = '0.1.4'.freeze

  # Most methods are supposed to be as simple as possible
  # and just cover most cases.
  # I would rather override specific cases than making
  # complicated methods.

  extend Rack::Utils

  # Global string constants
  EMPTY_STRING = ''.freeze
  IES_STRING = 'ies'.freeze
  E_STRING = 'e'.freeze
  S_STRING = 's'.freeze
  Y_STRING = 'y'.freeze
  X_STRING = 'x'.freeze
  XES_STRING = 'xes'.freeze
  SPACE = ' '.freeze
  DASH = '-'.freeze
  UNDERSCORE = '_'.freeze
  AMPERSAND = '&'.freeze
  PERCENT = '%'.freeze
  PIPE = '|'
  DOT = '.'.freeze
  COMMA = ','.freeze
  CONST_SEP = '::'.freeze
  ELLIPSIS = '...'
  AND_STRING = 'and'.freeze
  SPACE_PERCENT_STRING = ' percent'.freeze
  TRUE_STRING = 'true'.freeze
  FALSE_STRING = 'false'.freeze
  BR_TAG = '<br>'.freeze
  ARG1_SUB = '\1'.freeze

  # From then on, constants preceed the methods they are
  # used on.

  BLANK_RE = /\A[[:space:]]*\z/.freeze

  def blank? s
    return true if s.nil?
    # Not much difference with strip on benchmarks
    # return (s.empty? or BLANK_RE.match?(s)) if s.is_a?(String)
    return (s.strip.empty?) if s.is_a?(String)
    return s.empty? if s.respond_to?(:empty?)
    return true if s==false
    false
  end
  module_function :blank?

  PLURAL_RE = /([b-df-hj-np-tv-z])ys\z/.freeze
  PLURAL_SUB = '\1ies'.freeze

  def pluralize s
    s = s.dup
    s<<E_STRING if s[-1,1]==X_STRING
    s<<S_STRING
    s.sub PLURAL_RE, PLURAL_SUB
  end
  module_function :pluralize

  SINGULAR_RE = /ies\z/.freeze

  def singularize s
    if s.end_with? XES_STRING
      s[0..-3]
    elsif s.end_with? IES_STRING
      s.sub(SINGULAR_RE, Y_STRING)
    elsif s.end_with? S_STRING
      s[0..-2]
    else
      s.dup
    end
  end
  module_function :singularize

  UPPER_OR_NUM_RE = /([A-Z]|\d+)/.freeze

  def dasherize_class_name s
    s.gsub(UPPER_OR_NUM_RE) {|str| "-#{str.downcase}" }[1..-1].gsub(CONST_SEP, DASH)
  end
  module_function :dasherize_class_name

  DASH_LOWER_OR_NUM_RE = /\-([a-z0-9])/.freeze

  def undasherize_class_name s
    s.capitalize.gsub(DASH_LOWER_OR_NUM_RE) {|str| $1.upcase }.gsub(DASH, CONST_SEP)
  end
  module_function :undasherize_class_name

  def resolve_class_name s, context=Kernel
    current, *payload = s.to_s.split(CONST_SEP)
    raise(NameError) if current.nil?
    const = context.const_get(current)
    if payload.empty?
      const
    else
      resolve_class_name(payload.join(CONST_SEP),const)
    end
  end
  module_function :resolve_class_name

  def resolve_dasherized_class_name s
    resolve_class_name(undasherize_class_name(s.to_s)) 
  end
  module_function :resolve_dasherized_class_name

  START_UPPER_RE = /^[A-Z]/.freeze
  START_LOWER_RE = /^[a-z]/.freeze

  def guess_related_class_name context, clue
    context.respond_to?(:name) ? context.name : context.to_s
    clue = clue.to_s
    return clue if clue =~ START_UPPER_RE
    if clue =~ START_LOWER_RE
      clue = undasherize_class_name singularize(clue).gsub(UNDERSCORE, DASH)
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
    h.fetch(k) {|k| h.store(k, v) }
  end
  module_function :ensure_key!

  def ensure_key h, k, v
    {k=>v}.merge h
  end
  module_function :ensure_key

  ACCENTS = "ÀÁÂÃÄÅàáâãäåĀāĂăĄąÇçĆćĈĉĊċČčÐðĎďĐđÈÉÊËèéêëĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħÌÍÎÏìíîïĨĩĪīĬĭĮįİıĴĵĶķĸĹĺĻļĽľĿŀŁłÑñŃńŅņŇňŉŊŋÒÓÔÕÖØòóôõöøŌōŎŏŐőŔŕŖŗŘřŚśŜŝŞşŠšſŢţŤťŦŧÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲųŴŵÝýÿŶŷŸŹźŻżŽž".freeze
  WITHOUT_ACCENTS = "AAAAAAaaaaaaAaAaAaCcCcCcCcCcDdDdDdEEEEeeeeEeEeEeEeEeGgGgGgGgHhHhIIIIiiiiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnNnnNnOOOOOOooooooOoOoOoRrRrRrSsSsSsSssTtTtTtUUUUuuuuUuUuUuUuUuUuWwYyyYyYZzZzZz".freeze
  DASHIFY_RE = /(\-|[^0-9a-zA-Z])+/.freeze
  EDGE_DASH_RE = /(\A-|-\z)/.freeze

  def slugify s, force_lower=true
    s = s.to_s
      .tr(ACCENTS, WITHOUT_ACCENTS)
      .gsub(AMPERSAND, AND_STRING)
      .gsub(PERCENT, SPACE_PERCENT_STRING)
      .gsub(DASHIFY_RE, DASH)
      .gsub(EDGE_DASH_RE, EMPTY_STRING)
    s = s.downcase if force_lower
    escape(s)
  end
  module_function :slugify

  ALPHA_NUM_RE = /[a-zA-Z0-9]+/.freeze

  def label_for_field field_name
    field_name.to_s.scan(ALPHA_NUM_RE).map(&:capitalize).join(SPACE)
  end
  module_function :label_for_field

  EACH_STUB_ERR_MSG = 'WebUtils.each_stub expects an object which respond to each_with_index.'

  def each_stub obj, &block 
    raise TypeError, EACH_STUB_ERR_MSG unless obj.respond_to?(:each_with_index)
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

  TYPECASTABLE = [:bool, :boolean, :nil, :int, :integer, :float].freeze
  INT_RE = /\A-?\d+\z/.freeze
  FLOAT_RE = /\A-?\d*\.\d+\z/.freeze

  def automatic_typecast str, casted=TYPECASTABLE 
    return str unless str.is_a?(String)
    casted = casted.map do |sym|
      case sym
      when :int
        :integer
      when :bool
        :boolean
      else
        sym
      end
    end
    if casted.include?(:boolean) and str == TRUE_STRING
      true
    elsif casted.include?(:boolean) and str == FALSE_STRING
      false
    elsif casted.include?(:nil) and str == EMPTY_STRING
      nil
    elsif casted.include?(:integer) and str =~ INT_RE
      str.to_i
    elsif casted.include?(:float) and str =~ FLOAT_RE
      str.to_f
    else
      str
    end
  end
  module_function :automatic_typecast

  ID_CHARS = (('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a).freeze.map(&:freeze)
  ID_SIZE = 16
  DEPRECATED_RANDOM_ID_STRING = 'WebUtils::generate_random_id is deprecated. Use standard SecureRandom instead.'.freeze

  def generate_random_id size=ID_SIZE
    warn DEPRECATED_RANDOM_ID_STRING
    id = String.new
    size.times{id << ID_CHARS[rand(ID_CHARS.size)]} 
    id
  end
  module_function :generate_random_id

  RN_RE = /\r?\n/.freeze

  def nl2br s, br=BR_TAG
    s.to_s.gsub(RN_RE, br)
  end
  module_function :nl2br

  COMPLETE_LINK_RE = /^(\/|[a-z]*:)/.freeze

  def complete_link link
    if blank?(link) or link =~ COMPLETE_LINK_RE
      link
    else
      "//#{link}"
    end
  end
  module_function :complete_link

  EXTERNAL_LINK_RE = /\A[a-z]*:?\/\//.freeze

  def external_link? link
    !!(link =~ EXTERNAL_LINK_RE)
  end
  module_function :external_link?

  EMAIL_REGEX = /([^\s]+@[^\s]*[a-zA-Z])/.freeze
  LINK_REGEX = /\b((https?:\/\/|ftps?:\/\/|www\.)([A-Za-z0-9\-_=%&@\?\.\/]+))\b/.freeze

  def automatic_html s, br=BR_TAG
    replaced = s.to_s.
    gsub(LINK_REGEX) do |str|
      url = complete_link $1
      "<a href='#{url}' target='_blank'>#{$1}</a>"
    end.
    gsub(EMAIL_REGEX) do |str|
      "<a href='mailto:#{$1.downcase}'>#{$1}</a>"
    end
    nl2br(replaced,br)
  end
  module_function :automatic_html

  TAG_REGEX = /<[^>]*>/.freeze
  NL_RE = /\n/.freeze

  def truncate s, c=320, ellipsis=ELLIPSIS
    s.to_s
      .gsub(TAG_REGEX, EMPTY_STRING)
      .gsub(NL_RE, SPACE)
      .sub(/^(.{#{c}}\w*).*$/m, ARG1_SUB+ellipsis)
  end
  module_function :truncate

  QUERY_SPLITTER = /[^a-zA-Z0-9\&]+/.freeze

  def regex_for_query query, exhaustive=true
    atoms = query.split(QUERY_SPLITTER)
    atom_patterns = atoms.map{|a| "(?=.*\\b#{a})" }
    sep = exhaustive ? EMPTY_STRING : PIPE
    /#{atom_patterns.join(sep)}/i.freeze
  end
  module_function :regex_for_query

  PRICE_ERR_MSG = 'The price needs to be the price in cents/pence as an integer'.freeze
  PRICE_FMT = '%.2f'.freeze
  NO_CENTS_RE = /\.00/.freeze
  THOUSANDS_RE = /(\d{3})(?=\d)/.freeze
  THOUSANDS_SUB = '\1,'.freeze

  def display_price int
    unless int.is_a?(Integer)
      raise(TypeError, PRICE_ERR_MSG)
    end
    (PRICE_FMT % (int/100.0))
      .sub(NO_CENTS_RE, EMPTY_STRING)
      .reverse
      .gsub(THOUSANDS_RE, THOUSANDS_SUB)
      .reverse
  end
  module_function :display_price

  PRICE_PARSE_ERR_MSG = 'The price needs to be parsed from a String'.freeze
  SWITCH_DOT_COMMA_TR = ['.,'.freeze, ',.'.freeze].freeze
  COMMA_BASED_PRICE_RE = /(\.\d\d\d|,\d\d?)\z/.freeze
  NON_PRICE_CHARS_RE = /[^\d\.\-,]/.freeze

  def parse_price string
    unless string.is_a?(String)
      raise(TypeError, PRICE_PARSE_ERR_MSG) 
    end
    string = string.gsub(NON_PRICE_CHARS_RE, EMPTY_STRING)
    if string[COMMA_BASED_PRICE_RE]
      # comma-based price 
      string = string.tr(*SWITCH_DOT_COMMA_TR)
    end
    (PRICE_FMT % string.gsub(COMMA, EMPTY_STRING)).gsub(DOT, EMPTY_STRING).to_i
  end
  module_function :parse_price

  DEFAULT_BRAND = self.name
  START_DOT_SLASH_RE = /\A\.\//.freeze

  def branded_filename path, brand=DEFAULT_BRAND
    "#{File.dirname(path)}/#{brand}-#{File.basename(path)}"
      .sub(START_DOT_SLASH_RE, EMPTY_STRING)
  end
  module_function :branded_filename

  def filename_variation path, variation, ext
    old_ext = File.extname(path) 
    path.sub(/#{Regexp.escape old_ext}$/, ".#{variation}.#{ext}")
  end
  module_function :filename_variation

  def initial_request? request
    URI.parse(request.referer).host!=request.host
  rescue URI::InvalidURIError
    return true
  end
  module_function :initial_request?

  BOT_REGEX = /bot|crawl|slurp|spider/i.freeze

  def being_crawled? request
    request.user_agent =~ BOT_REGEX
  end
  module_function :being_crawled?

  def h text
    escape_html text
  end
  module_function :h

  def u text
    escape text
  end
  module_function :u

  def google_maps_link address
    "https://www.google.com/maps/search/?api=1&query=#{u address}"
  end
  module_function :google_maps_link

end

