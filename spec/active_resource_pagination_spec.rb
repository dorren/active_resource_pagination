require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ActiveResource::Pagination do
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
    
    it "should override per_page" do
      Article.per_page.should == 2
    end

    describe "when backend does not paginate" do  
      before(:each) do
        Article.should_receive(:find).and_return(@articles)      
      end
          
      it "should paginate with no params" do
        col = Article.paginate
        col.current_page.should == 1
        col.per_page.should == Article.per_page
        col.total_entries.should == @articles.size
        col.total_pages.should == 3  # (col.total_entries / col.per_page.to_f).ceil
      end
      
      it "should paginate with params" do
        col = Article.paginate(:page => 2)
        col.current_page.should == 2
        col.first.should == @articles[3]
      end
    end

    describe "when backend do paginate" do
      it "should paginate when backend returns paginated entries" do
        @articles = @articles[2,2]  # returns 2nd page result
        Article.should_receive(:find).and_return(@articles)
        
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
