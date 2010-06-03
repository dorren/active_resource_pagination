require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ActiveResource::Pagination do
  describe "##per_page" do
    it "should config per_page" do
      ActiveResource::Base.per_page.should be_nil
      ActiveResource::Base.per_page = 3
      ActiveResource::Base.per_page.should == 3
      
      class MySrc < ActiveResource::Base; end
      MySrc.per_page.should == 3
    end
  
    it "should override per_page in method" do
      class Something < ActiveResource::Base
        def self.per_page
          2
        end
      end
    
      Something.per_page.should == 2
    end

    it "should override per_page ad hoc" do
      class Comment < ActiveResource::Base
      end
      Comment.per_page = 5
      Comment.per_page.should == 5
    end
  end
  
  describe "##paginate" do
    before(:all) do
      class Article < ActiveResource::Base
        self.site = ''
        
        def self.per_page
          2
        end
        
        def self.from_xml(xml)
          instantiate_collection(format.decode(xml))
        end
      end
      
      # generate 5 articles, per_page is 2
      xml = (1..5).collect{|x|  {:name => "article #{x}", :content => "blah blah #{x}"}}.to_xml(:root => "articles")
      @articles = Article.from_xml(xml)
    end
    
    it "should respond to paginate" do
      ActiveResource::Base.should respond_to(:paginate)
    end
    
    describe "when backend does not paginate" do  
      before(:each) do      
      end
          
      it "should paginate with no params" do
        pg_params = {:offset => 0, :limit => Article.per_page}
        Article.should_receive(:find).with(:all, :params => pg_params).and_return(@articles)
        Article.should_not_receive(:count).with(pg_params)  # since articles count > per_page
        
        col = Article.paginate
        col.current_page.should == 1
        col.per_page.should == Article.per_page
        col.total_entries.should == @articles.size
        col.total_pages.should == 3  # (col.total_entries / col.per_page.to_f).ceil
      end
      
      it "should paginate with params" do
        pg_params = {:offset => Article.per_page, :limit => Article.per_page}
        Article.should_receive(:find).with(:all, :params => pg_params).and_return(@articles)
        Article.should_not_receive(:count).with(pg_params) 
        
        col = Article.paginate(:page => 2)
        col.current_page.should == 2
        col.first.should == @articles[3]
      end
    end

    describe "when backend do paginate" do
      it "should paginate without :total_entries param" do
        @articles = @articles[2,2]  # returns 2nd page result
        pg_params = {:offset => Article.per_page, :limit => Article.per_page}
        Article.should_receive(:find).with(:all, :params => pg_params).and_return(@articles)
        Article.should_receive(:count).with(pg_params).and_return(5)
        
        col = Article.paginate(:page => 2)
        col.current_page.should == 2
        col.per_page.should == Article.per_page
        col.total_entries.should == 5
        col.total_pages.should == 3  # (col.total_entries / col.per_page.to_f).ceil
        col.first.should == @articles.first
      end
      
      it "should paginate  with :total_entries param" do
        @articles = @articles[2,2]  # returns 2nd page result
        pg_params = {:offset => Article.per_page, :limit => Article.per_page}
        Article.should_receive(:find).with(:all, :params => pg_params).and_return(@articles)
        Article.should_not_receive(:count)
        
        col = Article.paginate(:page => 2, :total_entries => 5)
        col.current_page.should == 2
        col.per_page.should == Article.per_page
        col.total_entries.should == 5
        col.total_pages.should == 3  # (col.total_entries / col.per_page.to_f).ceil
        col.first.should == @articles.first
      end
    end
  end
end
