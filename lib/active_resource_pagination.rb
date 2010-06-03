require 'active_resource'
require 'will_paginate'
require 'hash_ext'

module ActiveResource
  # This adds pagination support to Active Resource. For example
  #
  #   Article.paginate
  #   Article.paginate(:page => 2, :per_page => 20)
  #   Article.paginate(:page => 2, :per_page => 20, :total_entries => 123)
  #   Article.paginate(:page => 2, :per_page => 20, 
  #                    :from => :most_popular, :params => {:year => 2010})
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
      # returns the total_entries count for the paginated result.
      #
      # method expects the returned xml to be in the format of:
      #   <?xml version="1.0" encoding="UTF-8"?>
      #   <hash>
      #     <count type="integer">5</count>
      #   </hash>
      def count(options)
        find(:one, :from => :count, :params => options).count.to_i
      end
      
      # use same method signatures as find(), optional additional parameters: 
      #   page - current page
      #   per_pape - entries per page
      #   total_entries - total entries count
      #
      # if resource backend doesn't paginate and retursn all result, then this method automatically
      # sets the total_entry count from the result. Otherwise, you have to pass in the 
      # :total_entries count value manually.
      def paginate(options={})
        pg_options, find_options = options.partition{|k,v| [:page, :per_page, :total_entries].include?(k)}
        
        pg_options[:page] ||= 1
        pg_options[:per_page] ||= per_page
        
        WillPaginate::Collection.create(pg_options[:page], pg_options[:per_page], pg_options[:total_entries]) do |pager|
          find_options[:params] = (find_options[:params] || {}).merge(:offset => pager.offset, :limit => pager.per_page)  
          
          arr = find(:all, find_options) || []
          if pg_options[:total_entries]
            pager.total_entries = pg_options[:total_entries]
          else 
            pager.total_entries = arr.size > pager.per_page ? arr.size : count(find_options[:params])
          end
          
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
