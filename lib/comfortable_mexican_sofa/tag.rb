# encoding: utf-8

require 'csv'

class ComfortableMexicanSofa::Tag

  TAG_REGEX = /\{\{\s*cms:(\w+)(?::(\w+))?\s*(.*)\s*\}\}/.freeze
  OPT_SEPARATORS  = [',', ':'].freeze
  OPT_QUOTES      = ['"', "'"].freeze

  attr_accessor :options

  def self.initialize_tag(tag_signature)
    if match = tag_signature.match(tag_signature)
      klass       = match[0]
      identifier  = match[1]
      options     = parse_options(match[2].to_s)
    end
  end

  def initialize(identifier, options = { })

  end

protected

  # Transforing a JSON-like string into a hash. Keys are symbols, values are strings.
  # Values with spaces/columns can be enclosed in quotes
  # For example:
  #   'k1:v1, k2:v2'  => {:k1 => 'v', :k2 => 'v2'}
  #   'k:"foo: bar"'  => {:k => 'foo: bar'}
  def self.parse_options(options_string)
    tokens  = [ ]
    token   = ''
    quote   = nil
    chars   = options_string.split('')

    # tokenizing string
    chars.each_with_index do |char, index|
      if OPT_QUOTES.member?(char)
        if quote == char
          quote = nil
        elsif quote.nil?
          quote = char
        else
          token << char
        end
      elsif OPT_SEPARATORS.member?(char) && quote.nil?
        tokens << token.strip
        token = ''
      else
        token << char
      end
    end
    tokens << token.strip

    # converting array of [k, v, k, v] into a hash
    tokens.each_slice(2).each_with_object({}) do |(k, v), h|
      h[k.to_sym] = v if k.present? && !v.nil?
    end
  end

end

# This module provides all Tag classes with neccessary methods.
# Example class that will behave as a Tag:
#   class MySpecialTag
#     include ComfortableMexicanSofa::Tag
#     ...
#   end
# module ComfortableMexicanSofa::Tag
#
#   TOKENIZER_REGEX   = /(\{\{\s*cms:[^{}]*\}\})|((?:\{?[^{])+|\{+)/.freeze
#   IDENTIFIER_REGEX  = /\w+[\-\.\w]+\w+/.freeze
#
#   attr_accessor :blockable,
#                 :identifier,
#                 :namespace,
#                 :params,
#                 :parent
#
#   module ClassMethods
#     # Regex that is used to match tags in the content
#     # Example:
#     #   /\{\{\s*?cms:page:(\w+)\}\}/
#     # will match tags like these:
#     #   {{cms:page:my_identifier}}
#     def regex_tag_signature(identifier = nil)
#       nil
#     end
#
#     # Initializing tag object for a particular Tag type
#     # First capture group in the regex is the tag identifier
#     # Namespace is the string separated by a dot. So if identifier is:
#     # 'sidebar.about' namespace is: 'sidebar'
#     def initialize_tag(blockable, tag_signature)
#       if match = tag_signature.match(regex_tag_signature)
#
#         params = begin
#           (CSV.parse_line(match[2].to_s, :col_sep => ':') || []).compact
#         rescue
#           []
#         end.map{|p| p.gsub(/\\|'/) { |c| "\\#{c}" } }
#
#         tag = self.new
#         tag.blockable   = blockable
#         tag.identifier  = match[1]
#         tag.namespace   = (ns = tag.identifier.split('.')[0...-1].join('.')).blank?? nil : ns
#         tag.params      = params
#         tag
#       end
#     end
#   end
#
#   module InstanceMethods
#
#     # String indentifier of the tag
#     def id
#       "#{self.class.to_s.demodulize.underscore}_#{self.identifier}"
#     end
#
#     # Ancestors of this tag constructed during rendering process.
#     def ancestors
#       node, nodes = self, []
#       nodes << node = node.parent while node.parent
#       nodes
#     end
#
#     # Regex that is used to identify instance of the tag
#     # Example:
#     #   /<\{\s*?cms:page:tag_identifier\}/
#     def regex_tag_signature
#       self.class.regex_tag_signature(identifier)
#     end
#
#     # Content that is accociated with Tag instance.
#     def content
#       nil
#     end
#
#     # Content that is used during page rendering. Outputting existing content
#     # as a default.
#     def render
#       ignore = [ComfortableMexicanSofa::Tag::Partial, ComfortableMexicanSofa::Tag::Helper].member?(self.class)
#       ComfortableMexicanSofa::Tag.sanitize_irb(content, ignore)
#     end
#
#     # Find or initialize Comfy::Cms::Block object
#     def block
#       blockable.blocks.detect{|b| b.identifier == self.identifier.to_s} ||
#       blockable.blocks.build(:identifier => self.identifier.to_s)
#     end
#
#     # Checks if this tag is using Comfy::Cms::Block
#     def is_cms_block?
#       %w(page field collection).member?(self.class.to_s.demodulize.underscore.split(/_/).first)
#     end
#
#     # Used in displaying form elements for Comfy::Cms::Block
#     def record_id
#       block.id
#     end
#   end
#
# private
#
#
#   # Initializes a tag. It's handled by one of the tag classes
#   # def self.initialize_tag(blockable, tag_signature)
# #     tag_instance = nil
# #     tag_classes.find{ |c| tag_instance = c.initialize_tag(blockable, tag_signature) }
# #     tag_instance
# #   end
#
#   # Scanning provided content and splitting it into [tag, text] tuples.
#   # Tags are processed further and their content is expanded in the same way.
#   # Tags are defined in the parent tags are ignored and not rendered.
#   def self.process_content(blockable, content = '', parent_tag = nil)
#     tokens = content.to_s.scan(TOKENIZER_REGEX)
#     tokens.collect do |tag_signature, text|
#       if tag_signature
#         if tag = self.initialize_tag(blockable, tag_signature)
#           tag.parent = parent_tag if parent_tag
#           if tag.ancestors.select{|a| a.id == tag.id}.blank?
#             blockable.tags << tag
#             self.process_content(blockable, tag.render, tag)
#           end
#         end
#       else
#         text
#       end
#     end.join('')
#   end
#
#   # Cleaning content from possible irb stuff. Partial and Helper tags are OK.
#   def self.sanitize_irb(content, ignore = false)
#     if ComfortableMexicanSofa.config.allow_irb || ignore
#       content.to_s
#     else
#       content.to_s.gsub('<%', '&lt;%').gsub('%>', '%&gt;')
#     end
#   end
#
#   def self.included(tag)
#     tag.send(:include, ComfortableMexicanSofa::Tag::InstanceMethods)
#     tag.send(:extend, ComfortableMexicanSofa::Tag::ClassMethods)
#     @@tag_classes ||= []
#     @@tag_classes << tag
#   end
#
#   # A list of registered Tag classes
#   def self.tag_classes
#     @@tag_classes ||= []
#   end
# end
