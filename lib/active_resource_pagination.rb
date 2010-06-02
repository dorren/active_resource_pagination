require 'active_resource'
require 'will_paginate'

module ActiveResource
  # This adds pagination support to Active Resource. For example
  #
  #   Article.paginate
  #   Article.paginate(:all, :page => 2, :per_page => 20)
  #   Article.paginate(:all, :page => 2, :per_page => 20, :total_entries => 123)
  #   Article.paginate(:all, :from => :most_popular,
  #                    :params => {:year => 2010, :page => 1, :per_page => 20})
  #
  #  To set default per_page value for all resources. you can do
  #    ActiveResource::Base.per_page = 20    # do this in config/environment or initializers
  # 
  # or to implement per_page() in your resource class.
  module Pagination
    def self.included(base)
      base.class_eval do
        cattr_accessor :per_page
      end
      base.extend ClassMethods
    end
    
    module ClassMethods      
      # use same method signatures as find(), optional additional parameters: 
      #   page - current page
      #   per_pape - entries per page
      #   total_entries - total entries count
      #
      # if resource backend doesn't paginate and retursn all result, then this method automatically
      # sets the total_entry count from the result. Otherwise, you have to pass in the 
      # :total_entries count value manually.
      def paginate(*args)
        options = args.last || {}
        options = options[:params] || options
        options = options.reject{|k, v| v.blank?}
        options = {:page => 1, :per_page => per_page}.merge(options)
        page = options[:page]
        per_page = options[:per_page]
        
        arr = find(*args) || []
        total_entries = options[:total_entries] || arr.size 
        WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
          if arr.size > per_page
            pager.replace arr[pager.offset, pager.per_page]
          else
            pager.replace arr
          end
        end
      end
    end
  end
end

ActiveResource::Base.send :include, ActiveResource::Pagination
